

locals {
  name_prefix    = join("-", compact([var.namespace, var.stage, var.proxy_id]))
  password_secrets_manager_arns = flatten([
      for user in var.users : user.password_secrets_manager_arn
  ])
}

terraform {
  required_providers {
    commonfate = {
      source  = "common-fate/commonfate"
      version = "2.25.0"
    }

    
  }
}





//data source to look up proxy that has already been registered
data "commonfate_ecs_proxy" "proxy_data" {
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
        "Resource" : distinct(local.password_secrets_manager_arns)
      }
    ]
})
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  role = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_task_role_name
  policy_arn   = aws_iam_policy.database_secrets_read_access.arn
}

data "aws_db_instance" "database" {
  db_instance_identifier = var.rds_instance_identifier
}


resource "aws_security_group_rule" "postgres_access_from_proxy" {
  type                     = "ingress"
  from_port                = data.aws_db_instance.database.port //data.aws_rds_instance.port
  to_port                  = data.aws_db_instance.database.port //data.aws_rds_instance.port
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id // database security group id
  source_security_group_id = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_security_group_id
}


resource "commonfate_proxy_rds_database" "demo" {
  proxy_id    = var.proxy_id
  
  name        = var.name
  instance_id = var.rds_instance_identifier
  endpoint    = data.aws_db_instance.database.endpoint
  database    = var.rds_database_name
  engine      = data.aws_db_instance.database.engine
  region      = var.region


  users = var.users
}
