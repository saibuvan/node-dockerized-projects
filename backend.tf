terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "node-app/terraform.tfstate"
    region                      = "us-east-1"
    endpoints = {
      s3 = "http://localhost:9000"
    }
#servie files server
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
