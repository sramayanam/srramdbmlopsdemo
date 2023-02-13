resource "databricks_group" "mlops-service-principal-group-staging" {
  display_name = "srram-db-mlops-demo-service-principals"
  provider     = databricks.staging
}

resource "databricks_group" "mlops-service-principal-group-prod" {
  display_name = "srram-db-mlops-demo-service-principals"
  provider     = databricks.prod
}

module "azure_create_sp" {
  depends_on = [databricks_group.mlops-service-principal-group-staging, databricks_group.mlops-service-principal-group-prod]
  source     = "databricks/mlops-azure-project-with-sp-creation/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
    azuread            = azuread
  }
  service_principal_name       = "srram-db-mlops-demo-cicd"
  project_directory_path       = "/srram-azure-project"
  azure_tenant_id              = var.azure_tenant_id
  service_principal_group_name = "srram-db-mlops-demo-service-principals"
}

data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

provider "databricks" {
  alias = "staging_sp"
  host  = "https://adb-7392334018826966.6.azuredatabricks.net"
  token = module.azure_create_sp.staging_service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = "https://adb-6329546450638653.13.azuredatabricks.net"
  token = module.azure_create_sp.prod_service_principal_aad_token
}

module "staging_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.staging_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  env             = "staging"
  github_repo_url = var.github_repo_url
}

module "prod_workspace_cicd" {
  source = "./common"
  providers = {
    databricks = databricks.prod_sp
  }
  git_provider    = var.git_provider
  git_token       = var.git_token
  env             = "prod"
  github_repo_url = var.github_repo_url
}



// We produce the service princpal's application ID, client secret, and tenant ID as output, to enable
// extracting their values and storing them as secrets in your CI system
//
// If using GitHub Actions, you can create new repo secrets through Terraform as well
// e.g. using https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret

output "stagingAzureSpApplicationId" {
  value     = module.azure_create_sp.staging_service_principal_application_id
  sensitive = true
}

output "stagingAzureSpClientSecret" {
  value     = module.azure_create_sp.staging_service_principal_client_secret
  sensitive = true
}

output "stagingAzureSpTenantId" {
  value     = var.azure_tenant_id
  sensitive = true
}

output "prodAzureSpApplicationId" {
  value     = module.azure_create_sp.prod_service_principal_application_id
  sensitive = true
}

output "prodAzureSpClientSecret" {
  value     = module.azure_create_sp.prod_service_principal_client_secret
  sensitive = true
}

output "prodAzureSpTenantId" {
  value     = var.azure_tenant_id
  sensitive = true
}
