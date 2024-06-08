############################
# Network
# AWS Availability Zones data
data "aws_availability_zones" "available" {}

resource "aws_vpc" "redshift-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = var.tags
}

resource "aws_subnet" "redshift-subnet-az1" {
  vpc_id            = aws_vpc.redshift-vpc.id
  cidr_block        = var.subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = var.tags
}

resource "aws_subnet" "redshift-subnet-az2" {
  vpc_id            = aws_vpc.redshift-vpc.id
  cidr_block        = var.subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = var.tags
}

resource "aws_redshift_subnet_group" "redshift-subnet-group" {
  depends_on = [
    aws_subnet.redshift-subnet-az1,
    aws_subnet.redshift-subnet-az2,
  ]

  name       = "kopicloud-redshift-subnet-group"
  subnet_ids = [aws_subnet.redshift-subnet-az1.id, aws_subnet.redshift-subnet-az2.id]

  tags = var.tags
}

resource "aws_internet_gateway" "redshift-igw" {
  vpc_id = aws_vpc.redshift-vpc.id

  tags = var.tags
}

resource "aws_route_table" "redshift-rt-igw" {
  vpc_id = aws_vpc.redshift-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redshift-igw.id
  }

  tags = var.tags
}

resource "aws_route_table_association" "redshift-subnet-rt-association-igw-az1" {
  subnet_id      = aws_subnet.redshift-subnet-az1.id
  route_table_id = aws_route_table.redshift-rt-igw.id
}

resource "aws_route_table_association" "redshift-subnet-rt-association-igw-az2" {
  subnet_id      = aws_subnet.redshift-subnet-az2.id
  route_table_id = aws_route_table.redshift-rt-igw.id
}

#############################
# Security Group
resource "aws_default_security_group" "redshift_security_group" {
  depends_on = [aws_vpc.redshift-vpc]

  vpc_id = aws_vpc.redshift-vpc.id

  ingress {
    description = "Redshift Port"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

############################
# IAM Role & Policy
resource "aws_iam_role" "redshift-role" {
  name               = "iam-redshift-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = var.tags
}

resource "aws_iam_role_policy" "redshift-s3-full-access-policy" {
  name = "${var.app_name}-${var.app_environment}-redshift-role-s3-policy"
  role = aws_iam_role.redshift-role.id

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": "s3:*",
       "Resource": "*"
      }
   ]
}
EOF
}

############################
# Provisioned Redshift server
resource "aws_redshift_cluster" "redshift-cluster" {
  depends_on = [
    aws_vpc.redshift-vpc,
    aws_redshift_subnet_group.redshift-subnet-group,
    aws_iam_role.redshift-role
  ]

  cluster_identifier     = var.redshift_cluster_name
  node_type              = var.redshift_node_type
  number_of_nodes        = var.redshift_number_of_nodes
  database_name          = var.redshift_database_name
  master_username        = var.redshift_master_username
  manage_master_password = var.redshift_manage_master_password

  iam_roles = [aws_iam_role.redshift-role.arn]

  cluster_subnet_group_name = aws_redshift_subnet_group.redshift-subnet-group.id

  skip_final_snapshot = true

  tags = var.tags
}

