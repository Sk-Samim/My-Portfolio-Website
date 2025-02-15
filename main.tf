#creating S3 bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = local.bucket_name

  tags = {
    Name = "Managed-With-Terraform"
  }
}

#Congifuring public access to the bucket
resource "aws_s3_bucket_public_access_block" "PublicAccess" {
  depends_on = [aws_s3_bucket.mybucket]
  bucket     = aws_s3_bucket.mybucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Configuring ownership control for the bucket
resource "aws_s3_bucket_ownership_controls" "OwnershipControl" {
  depends_on = [aws_s3_bucket.mybucket]
  bucket     = aws_s3_bucket.mybucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Configuring access control for the bucket
resource "aws_s3_bucket_acl" "Access-Control" {
  bucket = aws_s3_bucket.mybucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.OwnershipControl]
}

# Calling the data source for fetching the current aws account id
data "aws_caller_identity" "current" {}

#Configuring bucket policy to allow CloudFront access via OAC
resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  bucket = aws_s3_bucket.mybucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontServicePrincipalReadOnly",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.mybucket.bucket}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
          }
        }
      }
    ]
  })
}

# Configuring CORS rules for the S3 bucket
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.mybucket.id

  cors_rule {
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Calling this below module to upload multiple files 
module "template_files" {
  source   = "hashicorp/dir/template"
  version  = "1.0.2"
  base_dir = "${path.module}/Website"
}

#Configuring static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  depends_on = [aws_s3_bucket.mybucket]
  bucket     = aws_s3_bucket.mybucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

#Uploading files to the bucket
resource "aws_s3_object" "hosting_bucket_files" {
  bucket       = aws_s3_bucket.mybucket.id
  for_each     = module.template_files.files
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content
  acl          = "private"
  depends_on   = [aws_s3_bucket_acl.Access-Control]
  etag         = filemd5(each.value.source_path) # Re-upload files if content changes
}

# Creating Origin Access Control (OAC) for CloudFront to securely access the S3 bucket
resource "aws_cloudfront_origin_access_control" "OAC" {
  name                              = "my-oac"
  description                       = "OAC for accessing the S3 bucket via CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# # Creating a CloudFront Response Headers Policy for CSP
# resource "aws_cloudfront_response_headers_policy" "CSP" {
#   name = "CSP-Policy"

#   security_headers_config {
#     content_security_policy {
#       override                = true
#       content_security_policy = "default-src 'self'; script-src 'self' https://dz9adgl23c8cy.cloudfront.net/script.js"
#     }
#   }
# }

# CloudFront Distribution for HTTPS redirection with OAC
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.mybucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.mybucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.OAC.id
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.mybucket.id}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    # # Attaching the response headers policy
    # response_headers_policy_id = aws_cloudfront_response_headers_policy.CSP.id

    # TTL settings
    min_ttl     = 5
    max_ttl     = 5
    default_ttl = 5
  }


  viewer_certificate {
    cloudfront_default_certificate = true # Use CloudFront's default SSL certificate
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_root_object = "index.html"

  tags = {
    Name = "CloudFront HTTPS for S3"
  }

  depends_on = [aws_s3_bucket_website_configuration.website]
}
