# output "websiteEndPoint" {
#   value = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
# }

output "cloudfront_endpoint" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}
