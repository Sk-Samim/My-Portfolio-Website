terraform {
  backend "s3" {
    bucket         = "sk-samim-terraform-backend"
    key            = "portfolio_website_backend.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-backend-s3-state-lock-table"
  }
}
