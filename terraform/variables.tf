# The environment is the Terraform workspace (terraform.workspace), not a variable.

variable "instance_type" {
  # t2.small = 1 vCPU, 2 GB RAM. Keeps prod + an ephemeral CI cluster (8 instances)
  # within the account's vCPU quota. (t3.small is 2 vCPU, which doubles the count.)
  description = "EC2 instance type for the Galera and HAProxy nodes."
  type        = string
  default     = "t2.small"
}

variable "ssh_public_key" {
  description = "SSH public key installed on all instances."
  type        = string
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach HAProxy on 3306 (e.g. your IP as x.x.x.x/32)."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0))
    error_message = "allowed_cidr must be a valid CIDR block, e.g. 203.0.113.10/32."
  }
}
