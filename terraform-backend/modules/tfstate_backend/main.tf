# KMS key to allow for the encryption of the state bucket
resource "aws_kms_key" "terraform_bucket_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
resource "aws_kms_alias" "key_alias" {
  name          = "alias/${var.project_name}-${var.environment}-terraform-bucket-key"
  target_key_id = aws_kms_key.terraform_bucket_key.key_id
}

# S3 bucket 
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${var.environment}-infra-terraform-state"
}

# Enable versioning on the bucket to allow for state recovery in the case of accidental deletions and human error
resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on the bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sse" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_bucket_key.arn
    }
  }
}
