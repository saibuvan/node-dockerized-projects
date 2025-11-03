provider "aws" {
  access_key                  = "minioadmin"
  secret_key                  = "minioadmin"
  region                      = "us-east-1"

  # Point to MinIO instead of AWS
  endpoints = {
    s3 = "http://localhost:9000"
  }

  # Disable all AWS API calls
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Force MinIO path-style (important)
  s3_force_path_style = true
}
