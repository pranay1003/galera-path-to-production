resource "aws_key_pair" "main" {
  key_name   = "galera-${terraform.workspace}"
  public_key = var.ssh_public_key

  tags = { Name = "galera-${terraform.workspace}" }
}

# One Galera node per AZ, each in its own public subnet.
resource "aws_instance" "galera" {
  for_each = aws_subnet.public

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = each.value.id
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.galera.id]
  ebs_optimized          = true

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  # A new Canonical AMI must not plan to replace running nodes; patch via Ansible.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = { Name = "galera-${terraform.workspace}-${each.key}" }
}

# Single HAProxy / jump host in the first AZ.
resource "aws_instance" "haproxy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[local.azs[0]].id
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.haproxy.id]
  ebs_optimized          = true

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = { Name = "galera-${terraform.workspace}-haproxy" }
}
