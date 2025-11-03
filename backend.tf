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
    region                      = "us-east-1"

    # ✅ Point to your MinIO endpoint
    endpoints = {
      s3 = "http://localhost:9000"
    }

    # ✅ Use MinIO credentials
    access_key                  = "minioadmin"
    secret_key                  = "minioadmin"

    # ✅ Disable all AWS checks
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true

    # ✅ Force MinIO path-style URLs
    use_path_style              = true
  }
}
