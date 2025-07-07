provider "aws" {
  region  = var.aws_region
  profile = "${var.project_name}-${var.environment}"
  default_tags {
    tags = {
      ProjectName = var.project_name
      Environment = var.environment
      CreatedBy   = "Terraform"
    }
  }
}
