# Terraform Backend Setup

This documentation describes the process for setting up the Terraform remote backend infrastructure on AWS, including:
- An S3 bucket to store the remote state, with versioning enabled and encrypted with a KMS key.

## Environment-Specific Backends

In this setup, we assume separate Terraform backends for different environments (e.g., `dev`, `prod`). This is a common practice to:

- Isolate the state and resources between environments.
- Prevent accidental changes to production while working on development.
- Provide better governance and control.

Each environment have its own S3 bucket. If you have multiple "non-prod" environments (e.g. `dev`, `test` and so on) you can use a shared bucket with unique key paths for each terraform state (e.g. env `noprod`).

## Why the First Run Must Be Local

Terraform requires a backend to store its state file. However, the S3 bucket and other resources that will *become* the backend cannot be used as a backend until they exist. Therefore, the first time you apply this configuration, you **must run it locally** without a configured remote backend.

\*An alternative can be creating the resources hadling the terraform state manually, if you do it manually, you can skip this process completely.

## Step-by-Step Instructions

### 1. Initialize and Apply Locally

Run the following commands from this folder (assuming we start for `dev` environment):

```bash
cd terraform-backend/
terraform init
terraform plan -var-file="terraform.tfvars" -var-file="environments/dev/backend_dev.tfvars" # optional to check the changes
terraform apply -var-file="terraform.tfvars" -var-file="environments/dev/backend_dev.tfvars"
```

Expected output:

```bash
...
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + tfstate_backend = {
      + s3_bucket_arn  = (known after apply)
      + s3_kms_key_arn = (known after apply)
    }
```

### 2. Configure the Remote Backend

Once the resources are created, update your Terraform configuration to use them as the backend.

```bash
# de-comment the snippet inside backend.tf file
terraform {
	backend "s3" {}
}

# re-init
terraform init -reconfigure -backend-config=environments/dev/backend.hcl
```

Terraform will detect the backend configuration and ask you if you'd like to migrate your state to the remote backend. Answer `yes`.

### 3. Clean Up
Now that the backend is remote, you can safely delete the local `.terraform` folder, the local `terraform.tfstate` file and the local `terraform.tfstate.backup` file.

## Notes
- Only run this module once. After the remote backend is set up, all Terraform operations should use the remote backend from the start.
- The same operations can be done for `prod` or another environment. Before of swtiching to another environment, delete the `.terraform` folder to properly re-initilize.