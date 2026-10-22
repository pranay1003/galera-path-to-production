# Standard AZs only (excludes Local Zones / Wavelength). One Galera node per AZ.
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Latest Ubuntu 24.04 amd64 from Canonical (owner ID pinned so look-alike AMIs can't match).
# Instances should set lifecycle { ignore_changes = [ami] }, or a new Canonical build
# will plan a replacement of every node at once.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
