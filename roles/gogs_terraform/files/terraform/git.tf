data "aws_ami" "debian_stretch" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-gp2-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["379101102735"]
}

resource "aws_instance" "gogs" {
  ami           = "${data.aws_ami.debian_stretch.id}"
  instance_type = "t2.micro"
  tags {
    Name = "gogs"
  }
  key_name = "${aws_key_pair.local_ssh_key.key_name}"
  security_groups = ["${aws_security_group.allow_ssh_git_http.name}"]
}

resource "aws_security_group" "allow_ssh_git_http" {
  name        = "allow_ssh_git_http"
  description = "Allow ssh and http for git"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "local_ssh_key" {
  key_name   = "deployer-key"
  public_key = "${var.local_ssh_key}"
}

variable "local_ssh_key" {
  type = "string"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9Nd3mhKOFjAp8yP2TOYpo6MFoxUGk4NW7GdoLg1qHZhfVY1bHn8sTdhFakdmyWKzA5bwiMf9buv+CnFQKNURym2NlHnQyO62haTka7jrIQeaKTuvJEBHdQWPLzZ5RdecUoHY7eSbHpUi6QYvXqktJQXte/LeZu+zmvm3I3HpLVsCr9xrqHCY84/POhjESFldS9xrxY6N+T90yQtTTKMK0KN3h1i6Ewj9//hW93zpxaNnyIXmrSH8WznPsbVNKJXK0cSaByI+FVhDEoJRzw6WoBVoQcfmdkS/GLTU2c/4OBaA6L1jug300Fv9rdqYzB8YGqJT4q5oRwvqTvjUqHImX dummy@example.com"
}

output "gogs_instance_ids" {
  value = ["${aws_instance.gogs.id}"]
}
