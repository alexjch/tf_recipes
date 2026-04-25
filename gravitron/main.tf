module "server" {
  source        = "../modules/ec2-ssh-instance"
  name          = "gravitron_server"
  ami           = var.image_id != "" ? var.image_id : data.aws_ssm_parameter.al2023_arm64.value
  instance_type = var.vm_type
  key_name      = var.key_name
  public_key    = local.public_key
  user_data     = local.cloud_init
  volume_size   = 16
  volume_type   = "gp3"

  cpu_options = {
    threads_per_core = 2
  }
}

data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64"
}
