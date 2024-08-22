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
  description = "the ID for this proxy e.g prod-us-west-2."
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
}


variable "endpoint" {
  description = "The endpoint for the RDS database."
  type        = string
}


variable "name" {
  description = "The name of thes RDS database."
  type        = string
}

variable "database" {
  description = "The database name RDS database."
  type        = string
}

variable "engine" {
  description = "The database engine of your RDS database."
  type        = string
}

variable "region" {
  description = "The region your RDS database is deployed in."
  type        = string
}



variable "users" {
  description = "List of users with access to the RDS database"
  type = list(object({

    name = string

    username = string

    password_secrets_manager_arn = string

    password = string

  }))

}
