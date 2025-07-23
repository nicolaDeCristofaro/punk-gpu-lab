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

################################################################################
# NETWORKING
################################################################################
variable "vpc_cidr" {
  description = "The CIDR block for the Virtual Private Cloud (VPC) that will be created for the project. It specifies the range of IP addresses for the VPC"
  type        = string
}

variable "private_subnets_cidr" {
  description = "A list of CIDR blocks for the compute private subnets within the VPC"
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "A list of CIDR blocks for the public subnets within the VPC"
  type        = list(string)
}

variable "az_count" {
  description = "Number of availability-zones to span"
  type        = number
  default     = 3
}

variable "nat_strategy" {
  description = <<-EOT
    NAT gateway strategy:
      - none    = isolated/private-only VPC
      - single  = one shared NAT GW (cheaper)
      - per-az  = one NAT GW in every AZ (high-availability)
  EOT
  type        = string
  default     = "per-az"

  validation {
    condition     = contains(["none", "single", "per-az"], var.nat_strategy)
    error_message = "nat_strategy must be one of \"none\", \"single\", or \"per-az\"."
  }
}

################################################################################
# EC2 Workspaces
################################################################################
variable "ec2_workspace" {
  description = "Description of EC2 workspace characteristics"
  type = object({
    scope : string
    instance_type : string
    ami_id : string
    user_data : optional(string)
    root_volume_size : number
    secondary_volume_size : number
    secondary_volume_mount_point : string
    az : string
    additional_tags : optional(map(string))
    spot_enabled : optional(bool)
    spot_max_price : optional(string)
    spot_interruption_behavior : optional(string)
  })
}
