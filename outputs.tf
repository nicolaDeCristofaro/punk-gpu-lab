# Consolidated outputs for each main component
output "networking" {
  description = "Details about networking configuration"
  value = {
    vpc_id          = module.networking.vpc_id
    private_subnets = module.networking.private_subnets
    public_subnets  = module.networking.public_subnets
  }
}

output "kms" {
  description = "Details about the KMS key used for encryption"
  value = {
    key_arn   = module.kms.key_arn
    key_alias = keys(module.kms.aliases)[0]
  }
}

output "ec2_workspace" {
  description = "Details about the EC2 workspace instance"
  value = {
    instance_id       = module.ec2_workspace.id
    private_ip        = module.ec2_workspace.private_ip
    availability_zone = var.ec2_workspace.az
  }
}

output "ebs" {
  description = "Details about the persistent EBS volume"
  value = {
    volume_id         = aws_ebs_volume.ec2_workspace_data.id
    device_name       = aws_volume_attachment.data_attach.device_name
    attached_instance = aws_volume_attachment.data_attach.instance_id
    size              = var.ec2_workspace.volume_size
  }
}




