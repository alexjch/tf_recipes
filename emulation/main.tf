module "server" {
  source        = "../modules/ec2-ssh-instance"
  name          = "emulation_server"
  ami           = var.image_id
  instance_type = var.vm_type
  key_name      = var.key_name
  public_key    = local.public_key
  user_data     = local.cloud_init
  volume_size   = 16
  volume_type   = "gp3"

  cpu_options = {
    nested_virtualization = "enabled"
    threads_per_core      = 2
  }
}
