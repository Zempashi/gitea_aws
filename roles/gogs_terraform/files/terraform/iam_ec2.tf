resource "aws_iam_role_policy" "letsencrypt" {
  name = "letsencrypt_policy"
  role = aws_iam_role.letsencrypt.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:SetLoadBalancerListenerSSLCertificate",
        "iam:GetServerCertificate",
        "iam:ListServerCertificates",
        "iam:UploadServerCertificate",
        "iam:UpdateServerCertificate",
        "iam:DeleteServerCertificate"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "letsencrypt" {
  name = "letsencrypt"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "letsencrypt" {
name = "letsencrypt"
role = aws_iam_role.letsencrypt.name
}
