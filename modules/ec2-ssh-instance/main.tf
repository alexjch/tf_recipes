resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  dynamic "cpu_options" {
    for_each = var.cpu_options != null ? [var.cpu_options] : []
    content {
      threads_per_core      = cpu_options.value.threads_per_core
      nested_virtualization = cpu_options.value.nested_virtualization
    }
  }

  vpc_security_group_ids = [
    aws_security_group.sg_ssh.id,
  ]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = var.name
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}

resource "aws_security_group" "sg_ssh" {
  name        = "sg_ssh_${var.name}"
  description = "Allow SSH connections"

  tags = {
    Name = "sg_ssh_${var.name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ssh_ipv4" {
  security_group_id = aws_security_group.sg_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.sg_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
