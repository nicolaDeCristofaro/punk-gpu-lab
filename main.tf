data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = var.public_subnets_cidr
  private_subnets = var.private_subnets_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway     = var.nat_strategy != "none"
  single_nat_gateway     = var.nat_strategy == "single"
  one_nat_gateway_per_az = var.nat_strategy == "per-az"
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases = ["alias/${var.project_name}-${var.environment}-kms"]

  description         = "KMS key for data encryption"
  enable_key_rotation = true
}

# ---------------------------------------------------------------------------
# Helper to translate an AZ name ("eu-central-1a") into the matching index
# used by module.networking.private_subnets
# ---------------------------------------------------------------------------
locals {
  az_index = index(data.aws_availability_zones.available.names, var.ec2_workspace.az)
}

module "ec2_workspace" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name          = "${var.project_name}-${var.environment}-${var.ec2_workspace.scope}"
  ami           = var.ec2_workspace.ami_id
  instance_type = var.ec2_workspace.instance_type

  # Networking
  subnet_id = module.networking.private_subnets[local.az_index]
  security_group_egress_rules = {
    internet_outbound = {
      description = "Allow outbound traffic to internet"
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 443
    }
  }
  associate_public_ip_address = false

  # Bootstrap script
  user_data_base64 = base64encode(templatefile("${path.module}/bootstrap_scripts/${var.ec2_workspace.user_data}", {
    ec2_secondary_volume_size = var.ec2_workspace.volume_size
    mount_point               = var.ec2_workspace.volume_mount_point
  }))

  # IAM role for SSM Session Manager
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 ${var.project_name}-${var.environment}-${var.ec2_workspace.scope}"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Spot configuration (enabled when var.ec2_workspace.spot_enabled is true)
  instance_market_options = var.ec2_workspace.spot_enabled ? {
    market_type = "spot"
    spot_options = {
      max_price                      = var.ec2_workspace.spot_max_price
      spot_instance_type             = "persistent"
      instance_interruption_behavior = var.ec2_workspace.spot_interruption_behavior
    }
  } : null
}

# ---------------------------------------------------------------------------
# Stand-alone EBS data volume
# ---------------------------------------------------------------------------
resource "aws_ebs_volume" "ec2_workspace_data" {
  availability_zone = var.ec2_workspace.az
  size              = var.ec2_workspace.volume_size
  type              = "gp3"

  encrypted  = true
  kms_key_id = module.kms.key_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.ec2_workspace.scope}-data"
  }
}

# Attach the volume to the instance (/dev/sdf == /dev/xvdf in Linux)
resource "aws_volume_attachment" "data_attach" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.ec2_workspace_data.id
  instance_id  = module.ec2_workspace.id
  force_detach = true
}
