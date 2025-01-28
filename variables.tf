variable "user_name" {
  default = "sk-samim"
}

locals {
  bucket_name = "${var.user_name}-portfolio-website-bucket-2025"
}
