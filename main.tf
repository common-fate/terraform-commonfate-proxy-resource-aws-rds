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


locals {
  name_prefix    = join("-", compact([var.namespace, var.stage, var.proxy_id]))
  password_secrets_manager_arns = flatten([
      for user in var.users : user.passwordSecretsManagerARN
  ])
}


//data source to look up proxy that has already been registered
data "commonfate_proxy_ecs_proxy" "proxy_data" {
  id    =  var.proxy_id

}

resource "aws_iam_policy" "database_secrets_read_access" {
  name        = "${var.namespace}-${var.stage}-database_secret_read_access"
  description = "Allows pull database secret from secrets manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : local.password_secrets_manager_arns
      }
    ]
})
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  role = commonfate_proxy_ecs_proxy.proxy_data.ecs_cluster_task_role_name
  policy_arn   = aws_iam_policy.database_secrets_read_access.arn
}

resource "aws_security_group_rule" "postgres_access_from_proxy" {
  type                     = "ingress"
  from_port                = 5432 //data.aws_rds_instance.port
  to_port                  = 5432 //data.aws_rds_instance.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id // database security group id
  source_security_group_id = data.proxy.security_group_id
}

data "aws_db_instance" "database" {
  db_instance_identifier = var.rds_name
}

resource "commonfate_proxy_rds_database" "demo" {
  proxy_id    = var.proxy_id

  name        = var.rds_name
  endpoint    = aws_db_instance.database.endpoint
  database    = aws_db_instance.database.db_name
  engine      = aws_db_instance.database.engine
  region      = aws_db_instance.database.region

  users = var.users
}
