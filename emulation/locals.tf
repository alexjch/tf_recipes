locals {
  public_key = file("${path.module}/keys/aws_key.pub")

  cloud_init = templatefile("${path.module}/scripts/cloud-init.yaml", {
    ssh_pub_key = local.public_key,
    username    = var.username
  })
}
