provider "aws" {
  # Matches the backend region; backend blocks can't share a variable with this.
  region = "us-east-2"

  # Applied to every taggable resource. The workspace (ci/prod) is the environment.
  default_tags {
    tags = {
      env     = terraform.workspace
      project = "galera-path-to-production"
    }
  }
}
