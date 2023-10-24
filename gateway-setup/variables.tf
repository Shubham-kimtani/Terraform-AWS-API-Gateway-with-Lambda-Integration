variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}

variable "account_id" {
  description = "account id"

  type    = string
  default = "840118075213"
}

variable "stage_name" {
  description = "stage to be deployed"

  type    = string
  default = "initial"
}

variable "resource_path" {
  description = "resource path to be deployed"

  type    = string
  default = "translateit"
}
