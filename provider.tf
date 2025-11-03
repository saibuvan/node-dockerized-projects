provider "aws" {
  region                      = "us-east-1"
  access_key                  = "minioadmin"
  secret_key                  = "minioadmin"

  # ✅ Tell Terraform to use MinIO instead of AWS services
  endpoints = {
    s3 = "http://localhost:9000"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  use_path_style              = true
}
