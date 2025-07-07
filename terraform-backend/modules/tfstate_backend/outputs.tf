output "s3_kms_key_arn" {
  value       = aws_kms_key.terraform_bucket_key.arn
  description = "The ARN of the KMS key used to encrypt the bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}


