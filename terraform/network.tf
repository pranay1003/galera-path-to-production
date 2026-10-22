locals {
  vpc_cidr = "10.0.0.0/16"

  # az name -> /24 subnet. Keyed by AZ so reordering the AZ list never recreates subnets.
  subnets = { for i, az in local.azs : az => cidrsubnet(local.vpc_cidr, 8, i) }
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Each workspace is an environment; the default workspace is never a real one.
  lifecycle {
    precondition {
      condition     = terraform.workspace != "default"
      error_message = "Select a workspace first: terraform workspace select -or-create ci|prod."
    }
  }

  tags = { Name = "galera-${terraform.workspace}" }
}

resource "aws_subnet" "public" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = { Name = "galera-${terraform.workspace}-${each.key}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "galera-${terraform.workspace}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "galera-${terraform.workspace}-public" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
