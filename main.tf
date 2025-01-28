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

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.OwnershipControl]
}

#Configuring bucket policy
resource "aws_s3_bucket_policy" "bucketPolicy" {
  bucket = aws_s3_bucket.mybucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${local.bucket_name}/*"
      }
    ]
  })
}

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
  acl          = "public-read"
  depends_on   = [aws_s3_bucket_acl.Access-Control]
  etag         = filemd5(each.value.source_path) # Adding this line to evaluate change to the objects by terraform
}
