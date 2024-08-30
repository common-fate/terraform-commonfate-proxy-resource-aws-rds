

locals {
  name_prefix    = join("-", compact([var.namespace, var.stage, var.proxy_id]))
  password_secrets_manager_arns = flatten([
      for user in var.users : user.passwordSecretsManagerARN
  ])
}

terraform {
  required_providers {
    commonfate = {
      source  = "common-fate/commonfate"
      version = "2.25.0-alpha1"
    }

    
  }
}

provider "commonfate" {
  authz_url = var.app_url
  api_url   = var.app_url
  # oidc_client_id     = <filled in via GitHub Actions env vars>
  # oidc_client_secret = <filled in via GitHub Actions env vars>
  oidc_issuer = "https://cognito-idp.ap-southeast-2.amazonaws.com/ap-southeast-2_xzhfVdcnp"
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
        "Resource" : local.password_secrets_manager_arns
      }
    ]
})
}

resource "aws_iam_role_policy_attachment" "read_secrets" {
  role = data.commonfate_ecs_proxy.proxy_data.ecs_cluster_reader_role_arn
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
  source_security_group_id = data.commonfate_ecs_proxy.ecs_cluster_security_group_id
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
