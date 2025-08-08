################################################################################
# GENERAL
################################################################################
project_name = "workspace"
environment  = "dev"
aws_region   = "eu-central-1"

################################################################################
# Networking
################################################################################
vpc_cidr = "10.0.0.0/16"
public_subnets_cidr = [
  "10.0.0.0/24",
  "10.0.1.0/24",
  "10.0.2.0/24"
]
private_subnets_cidr = [
  "10.0.3.0/24",
  "10.0.4.0/24",
  "10.0.5.0/24"
]
nat_strategy = "single"

################################################################################
# EC2 Workspaces
################################################################################
ec2_workspace = {
  scope                        = "personal"
  instance_type                = "g4dn.xlarge"
  ami_id                       = "ami-0caf67d7f3f170d9d" # Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 24.04)
  root_volume_size             = 150                     # GB - ephemeral - it is lost when the instance is terminated
  secondary_volume_size        = 150                     # GB
  secondary_volume_mount_point = "/mnt/persistent-data"  # Mount point for the secondary volume
  az                           = "eu-central-1b"

  # Spot controls
  spot_enabled = true
  # Set to null to pay up to the current On‑Demand price,
  # or specify a string (e.g., "0.25") to cap the hourly bid.
  spot_max_price             = null
  spot_interruption_behavior = "stop" # "terminate" | "hibernate" | "stop"

  user_data = "general_init.tpl" # Path to the user data script
}