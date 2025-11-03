terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "my-node-app/terraform.tfstate"   # path inside bucket
    region = "us-east-1"

    # Important for MinIO (S3-compatible)
    endpoint                    = "http://localhost:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
  }
}