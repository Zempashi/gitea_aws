output "gogs_instance_ids" {
  value = ["${aws_instance.gogs.id}"]
}

output "gogs_ebs" {
  value = ["${aws_volume_attachment.gogs_attachement.device_name}"]
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

resource "aws_instance" "gogs" {
  ami           = "${data.aws_ami.debian_stretch.id}"
  instance_type = "t2.micro"
  tags {
    Name = "gogs"
  }
  key_name = "${aws_key_pair.local_ssh_key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.letsencrypt.name}"
  security_groups = ["${aws_security_group.allow_ssh_git_http.name}"]
}

resource "aws_ebs_volume" "gogs" {
  availability_zone = "${aws_instance.gogs.availability_zone}"
  size = 20
  tags {
    Name = "gogs"
  }

  lifecycle {
    prevent_destroy = "true"
  }
}

resource "aws_volume_attachment" "gogs_attachement" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.gogs.id}"
  instance_id = "${aws_instance.gogs.id}"
}
