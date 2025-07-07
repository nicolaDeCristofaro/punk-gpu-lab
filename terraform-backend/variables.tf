################################################################################
# GENERAL
################################################################################
variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "A unique identifier for the project. It helps in distinguishing resources associated with this project from others"
  type        = string
}

variable "environment" {
  description = "Defines the deployment environment, such as 'dev' or 'prod'"
  type        = string
}
