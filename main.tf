terraform {
  required_providers {
    commonfate = {
      source  = "common-fate/commonfate"
      version = ">= 2.25.3, < 3.0.0, = 2.27.0-alpha2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  password_secrets_manager_arns = flatten([
    for user in var.users : user.password_secrets_manager_arn
  ])
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
}


//data source to look up proxy that has already been registered
data "commonfate_ecs_proxy" "proxy_data" {
  id = var.proxy_id
}

data "aws_db_instance" "database" {
  db_instance_identifier = var.rds_instance_identifier
}

// Add network access for the proxy to the database instance
resource "aws_security_group_rule" "postgres_access_from_proxy" {
  count                    = var.create_security_group_rule ? 1 : 0
  type                     = "ingress"
  from_port                = data.aws_db_instance.database.port
  to_port                  = data.aws_db_instance.database.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id
  source_security_group_id = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_security_group_id
}


resource "commonfate_proxy_rds_database" "database" {
  proxy_id = var.proxy_id

  name           = var.name == "" ? var.database : var.name
  instance_id    = var.rds_instance_identifier
  endpoint       = data.aws_db_instance.database.endpoint
  database       = var.database
  engine         = data.aws_db_instance.database.engine
  region         = local.aws_region
  aws_account_id = local.aws_account_id

  users = var.users
}


resource "aws_iam_policy" "database_secrets_read_access" {
  // use a name prefix so that multiple or this module may be deployed
  name_prefix = "${var.namespace}-${var.stage}-database-secret-read-access"
  description = "Allow the Common Fate AWS RDS Proxy (${var.proxy_id}) to read secrets for access to the database (${commonfate_proxy_rds_database.database.id})"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : distinct(local.password_secrets_manager_arns)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  role       = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_task_role_name
  policy_arn = aws_iam_policy.database_secrets_read_access.arn
}
