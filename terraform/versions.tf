terraform {
  # use_lockfile (native S3 locking) requires >= 1.11; CI pins the exact version.
  required_version = "~> 1.17"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  # State bucket is created by hand (see DESIGN.md). Backend blocks can't use variables.
  # Workspaces store state under env:/<workspace>/<key>.
  backend "s3" {
    bucket       = "galera-ptp-tfstate-pranay1003"
    key          = "galera/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
