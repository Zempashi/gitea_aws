
data "aws_availability_zones" "all_az" {}

resource "random_shuffle" "az" {
  input = ["${data.aws_availability_zones.all_az.names}"]
  result_count = 1
}

resource "aws_ebs_volume" "gogs" {
  availability_zone = "${random_shuffle.az.result[0]}"
  size = 20
  tags {
    Name = "gogs"
  }

  lifecycle {
    prevent_destroy = "true"
    ignore_changes = ["availability_zone"]
  }
}
