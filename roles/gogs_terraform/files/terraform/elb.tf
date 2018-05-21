output "gogs_elb_name" {
  value = "${aws_elb.gogs.name}"
}

resource "aws_elb" "gogs" {
  name               = "gogs-elb"
  security_groups    = ["${aws_security_group.elb_gogs.id}"]
  subnets            = ["${aws_instance.gogs.*.subnet_id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 2222
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.snakeoil.arn}"
  }

  lifecycle {
      ignore_changes = ["listener"]
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/.well-known/"
    interval            = 30
  }

  instances                   = ["${aws_instance.gogs.id}"]
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "gogs"
  }
}

resource "aws_security_group" "elb_gogs" {
  name        = "elb_gogs"
  description = "SSH and HTTP(S)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_iam_server_certificate" "snakeoil" {
  name             = "snakeoil"
  certificate_body = "${file("cert_snakeoil/ssl-cert-snakeoil.pem")}"
  private_key      = "${file("cert_snakeoil/ssl-cert-snakeoil.key")}"

}
