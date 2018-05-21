variable "vpc_name" {
  default = ""
}

variable "ssh_key_path" {
  type = "string"
  default = "~/.ssh/id_rsa.pub"
}

data "aws_vpc" "default" {
  default = 1
  count = "${var.vpc_name == "" ? 1 : 0}"
}

data "aws_vpc" "custom" {
  count = "${var.vpc_name == "" ? 0 : 1}"
  #id = "${var.vpc_name}"
  filter {
    name = "tag:Name"
    values = ["${var.vpc_name}"]
  }
}

data "aws_vpc" "vpc" {
  id = "${element(concat(data.aws_vpc.default.*.id, data.aws_vpc.custom.*.id), 0)}"
}

resource "aws_key_pair" "local_ssh_key" {
  key_name   = "deployer-key"
  public_key = "${file(var.ssh_key_path)}"
}

data "aws_ami" "debian_stretch" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-2018-05-14-16107"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["379101102735"]
}
