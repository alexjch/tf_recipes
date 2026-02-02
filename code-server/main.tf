resource "aws_instance" "dev_server" {
  ami           = var.image_id
  instance_type = var.vm_type
  key_name      = "aws_key"
  vpc_security_group_ids = [
    aws_security_group.sg_ssh.id,
    aws_security_group.sg_http.id
  ]

  user_data = local.cloud_init

  ebs_block_device {
    device_name = "/dev/sda1"  # Typically the root device
    volume_size = 20            # Size in GB
    volume_type = "gp2"        # General Purpose SSD
  }

  tags = {
    Name = "dev_server"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = local.public_key
}

resource "aws_security_group" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow SSH connections"
  tags = {
    Name = "sg_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ssh_ipv4" {
  security_group_id = aws_security_group.sg_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_security_group" "sg_http" {
  name        = "sg_http"
  description = "Allow HHTP connections"
  tags = {
    Name = "sg_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_http_ingress_ipv4" {
  security_group_id = aws_security_group.sg_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "sg_http_egress_ipv4" {
  security_group_id = aws_security_group.sg_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
