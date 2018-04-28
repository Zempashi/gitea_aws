resource "aws_db_instance" "gitea_maria" {
  allocated_storage    = 10
  engine               = "mariadb"
  engine_version       = "10.2.12"
  instance_class       = "db.t2.micro"
  identifier           = "gitea"
  name                 = "gitea"
  username             = "root"
  password             = "${var.db_password}"
  vpc_security_group_ids = ["${aws_security_group.allow_mysql.id}"]
}

resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow mysql"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_default_vpc.default.cidr_block}"]
  }
}

variable "db_password" {
  default = "temporaryPassword"
}

output "rds_name" {
  value = "${aws_db_instance.gitea_maria.identifier}"
}
