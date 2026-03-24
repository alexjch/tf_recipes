resource "aws_instance" "emulation_server" {
  ami           = var.image_id
  instance_type = var.vm_type
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.sg_ssh.id,
  ]

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name = "emulation_server"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = local.public_key
}

resource "aws_security_group" "sg_ssh" {
  name        = "sg_ssh_emulation"
  description = "Allow SSH connections"

  tags = {
    Name = "sg_ssh_emulation"
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
