provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      project   = "galera-path-to-production"
      component = "bootstrap"
    }
  }
}
