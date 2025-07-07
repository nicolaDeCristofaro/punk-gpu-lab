terraform {
  backend "s3" {
    bucket       = "workspace-dev-infra-terraform-state"
    key          = "terraform/dev/terraform.tfstate"
    region       = "eu-central-1"
    profile      = "workspace-dev"
    encrypt      = true
    use_lockfile = true #S3 native locking
  }
}
