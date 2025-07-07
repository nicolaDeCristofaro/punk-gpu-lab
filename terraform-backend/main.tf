module "tfstate_backend" {
  source = "./modules/tfstate_backend"

  project_name = var.project_name
  environment  = var.environment
}
