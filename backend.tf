terraform {
  backend "s3" {
    bucket                      = "terraform-states"
    key                         = "state/my-node-app.tfstate"
    endpoint                    = "http://localhost:9000"
    region                      = "us-east-1"
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"
    skip_credentials_validation  = true
    skip_metadata_api_check      = true
    force_path_style             = true
  }
}