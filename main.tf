variable "domain_name" {
  default = "dendilz-do10"
}

variable "hcloud_token" {}

variable "aws_access_key" {}

variable "aws_secret_key" {}

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  region  = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

data "hcloud_ssh_key" "rebrain_ssh_key" {
  name = "REBRAIN.SSH.PUB.KEY"
}

data "hcloud_ssh_key" "danil_pub_key" {
  name       = "Danil.pub.key"
}

resource "hcloud_server" "hcloud_node" {
  name        = "${var.domain_name}.devops.rebrain.srwx.net"
  image       = "ubuntu-18.04"
  server_type = "cx11"
  ssh_keys    = [data.hcloud_ssh_key.rebrain_ssh_key.name,
                data.hcloud_ssh_key.danil_pub_key.id]
  labels = {
    "module" = "devops"
    "email"  = "dendilz_at_bk_ru"
  }

  provisioner "local-exec" {
    command = "echo ${hcloud_server.hcloud_node.name} > domain"
  }
}

data "aws_route53_zone" "primary" {
  name = "devops.rebrain.srwx.net"
}

resource "aws_route53_record" "s53_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = hcloud_server.hcloud_node.name
  type    = "A"
  ttl     = "300"
  records = [element(hcloud_server.hcloud_node.*.ipv4_address, 0)]
}

resource "null_resource" "install_nginx" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ./inventory ./install_nginx.yml"
  }
  depends_on = [
    aws_route53_record.s53_record
  ]
}
