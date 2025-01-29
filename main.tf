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

# CloudFront Distribution for HTTPS redirection with OAC
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.mybucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.mybucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.OAC.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.mybucket.id}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
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
