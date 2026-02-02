resource "aws_instance" "ollama_server" {
  ami           = var.image_id
  instance_type = var.vm_type
  key_name      = "aws_key"
  vpc_security_group_ids = [
    aws_security_group.sg_ssh.id,
  ]

  user_data = local.cloud_init

  ebs_block_device {
    device_name = "/dev/sda1"  # Typically the root device
    volume_size = 20            # Size in GB
    volume_type = "gp2"        # General Purpose SSD
  }

  tags = {
    Name = "ollama_server"
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
