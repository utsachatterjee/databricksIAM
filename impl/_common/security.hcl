# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mysql. The common variables for each environment to
# deploy mysql are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If any environment
# needs to deploy a different module version, it should redefine this block with a different ref to override the
# deployed version.
terraform {
  source = "${get_path_to_repo_root()}/modules/databricks/security"
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  environment_vars         = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  groups                   = local.environment_vars.locals.groups
  group_connections        = local.environment_vars.locals.group_connections
  service_principals       = local.environment_vars.locals.service_principals
  access_control_rule_sets = local.environment_vars.locals.access_control_rule_sets
  users                    = local.environment_vars.locals.users
  workspace_assignment     = local.environment_vars.locals.workspace_assignment
  workspace_dictionary     = local.environment_vars.locals.workspace_dictionary
  account_id               = local.environment_vars.locals.account_id
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# The below can be removed if you set vnet_needed to false in an env.hcl
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  groups                   = local.groups
  group_connections        = local.group_connections
  service_principals       = local.service_principals
  access_control_rule_sets = local.access_control_rule_sets
  users                    = local.users
  workspace_dictionary     = local.workspace_dictionary
  account_id               = local.account_id
  workspace_assignment     = local.workspace_assignment

}
