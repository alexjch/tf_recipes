module "server" {
  source        = "../modules/ec2-ssh-instance"
  name          = "ollama_server"
  ami           = var.image_id
  instance_type = var.vm_type
  key_name      = var.key_name
  public_key    = local.public_key
  user_data     = local.cloud_init
  volume_size   = 32
  volume_type   = "gp2"
}
