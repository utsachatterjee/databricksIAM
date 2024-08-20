locals {

  groups                   = jsondecode(file("creation_management/groups.json"))
  group_connections        = jsondecode(file("creation_management/group_connections.json"))
  users                    = jsondecode(file("creation_management/users.json"))
  access_control_rule_sets = jsondecode(file("creation_management/access_control_rule_sets.json"))
  workspace_assignment     = jsondecode(file("creation_management/workspace_assignment.json"))
  service_principals       = jsondecode(file("creation_management/service_principals.json"))
  workspace_dictionary     = jsondecode(file("creation_management/workspaces.json"))

  tags = {
    resource-owner   = "Utsa Chatterjee"
    contact-info     = "utsachatterjee89@gmail.com"
  }
  
  account_id = "<databricks-account>"
}
