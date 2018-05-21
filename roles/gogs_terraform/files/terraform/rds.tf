variable "db_password" {
  default = "temporaryPassword"
}

output "rds_name" {
  value = "${aws_db_instance.gogs_maria.identifier}"
}

resource "aws_db_instance" "gogs_maria" {
  allocated_storage      = 10
  engine                 = "mariadb"
  engine_version         = "10.2.12"
  instance_class         = "db.t2.micro"
  identifier             = "gogs"
  name                   = "gogs"
  username               = "root"
  password               = "${var.db_password}"
  skip_final_snapshot    = true
  vpc_security_group_ids = ["${aws_security_group.allow_mysql.id}"]

  lifecycle {
    ignore_changes = ["password"]
  }
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow mysql"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
  }
}
