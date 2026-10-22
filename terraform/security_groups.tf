# HAProxy / jump host: the only instance reachable from the internet.
resource "aws_security_group" "haproxy" {
  name        = "galera-${terraform.workspace}-haproxy"
  description = "HAProxy load balancer and SSH jump host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH to jump host (pipeline narrows this to the runner IP in CI)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "MySQL via HAProxy"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "galera-${terraform.workspace}-haproxy" }
}

# Galera nodes: no internet ingress. Client traffic via HAProxy; replication among themselves.
resource "aws_security_group" "galera" {
  name        = "galera-${terraform.workspace}-galera"
  description = "MariaDB Galera cluster nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from HAProxy only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  ingress {
    description = "Galera replication (TCP)"
    from_port   = 4567
    to_port     = 4567
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Galera replication (UDP multicast)"
    from_port   = 4567
    to_port     = 4567
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Galera IST (incremental state transfer)"
    from_port   = 4568
    to_port     = 4568
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Galera SST (full snapshot via mariabackup)"
    from_port   = 4444
    to_port     = 4444
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description     = "SSH via the HAProxy jump host only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.haproxy.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "galera-${terraform.workspace}-galera" }
}
