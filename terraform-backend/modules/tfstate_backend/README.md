# Terraform State Remote Backend Module

This Terraform module provisions an AWS S3 bucket with versioning and server-side encryption, along with a KMS key, to securely store and manage Terraform state files.

## Features

- **Creates an S3 Bucket**  
  - Named using the pattern: `{project_name}-{environment}-infra-terraform-state`
  - Versioning enabled to recover previous state versions in case of accidental deletion or human error.

- **Enables Server-Side Encryption (SSE)**  
  - Uses a KMS key for encryption with support for key rotation.
  - SSE is enforced by default using the `aws:kms` algorithm.

- **Creates a KMS Key and Alias**  
  - Key description, deletion window, and rotation are predefined.
  - Alias is automatically named using the pattern:  
    `alias/{project_name}-{environment}-terraform-bucket-key`

## Notes
- Ensure that IAM roles or users interacting with the Terraform state bucket have appropriate permissions for S3 and KMS.