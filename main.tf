terraform {
  required_providers {


    commonfate = {
      source = "common-fate/commonfate"
      version = "2.23.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

locals {
  name_prefix    = join("-", compact([var.namespace, var.stage, var.proxy_id]))

}



//data source to look up proxy that has already been registered
data "commonfate_proxy_ecs_proxy" "proxy_data" {
  id    =  var.proxy_id

}

resource "aws_iam_policy" "read_secrets" {
  name        ="${local.name_prefix}-read-database-secret"
  description = "Allows access to read database password secret from ssm"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  role = commonfate_proxy_ecs_proxy.proxy_data.ecs_cluster_reader_role_arn
  policy_arn   = aws_iam_policy.read_secrets.arn
}

resource "aws_security_group_rule" "postgres_access_from_proxy" {
  type                     = "ingress"
  from_port                = 5432 //data.aws_rds_instance.port
  to_port                  = 5432 //data.aws_rds_instance.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id // database security group id
  source_security_group_id = data.proxy.security_group_id
}


resource "proxy_rds_database" "demo" {
  proxy_id    = var.proxy_id
  instance_id = var.instance_id
  name        = "Demo postgres Database"
  endpoint    = "localhost:5434"
  database    = "testpostgresdb"
  engine      = "postgres"
  region      = "ap-southeast-2"

  users = var.users
}
