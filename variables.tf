variable "namespace" {
  description = "Specifies the namespace for the deployment."
  default     = "common-fate"
  type        = string
}

variable "stage" {
  description = "Determines the deployment stage (e.g., 'dev', 'staging', 'prod')."
  default     = "prod"
  type        = string
}

variable "proxy_id" {
  description = "The ID of the Common Fate AWS RDS Proxy e.g prod-us-west-2. The proxy is deployed seperately, it must exist before you register a database using this module."
  type        = string
}

variable "app_url" {
  description = "The app url (e.g., 'https://common-fate.mydomain.com')."
  type        = string

  validation {
    condition     = can(regex("^https://", var.app_url))
    error_message = "The app_url must start with 'https://'."
  }
}

variable "rds_security_group_id" {
  description = "The security group attached with your RDS database."
  type        = string
  default     = ""

  validation {
    condition     = var.create_security_group_rule == true && length(var.rds_security_group_id) == 0
    error_message = "rds_security_group_id must not be empty when create_security_group_rule is true."
  }
}

variable "rds_instance_identifier" {
  description = "The identifier of the rds instance."
  type        = string
}


variable "name" {
  description = "A human readable name to give the RDS database resource in Common Fate. Defaults to the database name."
  type        = string
  default     = ""
}

variable "database" {
  description = "The name of the database to connect to on the RDS instance."
  type        = string
}

variable "users" {
  description = "A list of database users and their credentials to access the database"
  type = list(object({

    name = string

    username = string

    password_secrets_manager_arn = string

  }))

}


variable "create_security_group_rule" {
  description = "If 'true', will create a rule allowing ingress from the proxy to the database security group. The database security group is specified by the 'rds_security_group_id' variable."
  type        = bool
  default     = true
}
