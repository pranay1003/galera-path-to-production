variable "github_repo" {
  description = "owner/repo allowed to assume the deploy role via OIDC."
  type        = string
  default     = "pranay1003/galera-path-to-production"
}

variable "state_bucket" {
  description = "S3 bucket holding Terraform state (the deploy role needs access)."
  type        = string
  default     = "galera-ptp-tfstate-pranay1003"
}

variable "deploy_role_name" {
  description = "Name of the IAM role GitHub Actions assumes."
  type        = string
  default     = "galera-ptp-gha-deploy"
}
