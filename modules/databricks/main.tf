locals {
}

# ---------------------------------------------------------------------------------------------------------------------
# Databricks User Creation
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_user" "user_creation" {
  provider     = databricks.accounts
  for_each     = jsondecode(var.users)
  display_name = each.value.name
  user_name    = each.key
  active       = each.value.active
  force        = each.value.preexisting
}

# ---------------------------------------------------------------------------------------------------------------------
# Databricks Service Principal Creation
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_service_principal" "sp" {
  for_each       = jsondecode(var.service_principals)
  provider       = databricks.accounts
  display_name   = each.key
  application_id = each.value.application_id
  active         = each.value.active
  force          = each.value.preexisting
}

resource "databricks_access_control_rule_set" "dacrs" {
  for_each   = jsondecode(var.access_control_rule_sets)
  depends_on = [databricks_service_principal.sp]
  provider   = databricks.accounts
  name       = "accounts/${var.account_id}/servicePrincipals/${each.value.application_id}/ruleSets/default"

  dynamic "grant_rules" {
    for_each = each.value.grant_rules
    content {
      principals = [for v in grant_rules.value : "groups/${v}"]
      role       = "roles/servicePrincipal.${grant_rules.key}"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Databricks Group Creation
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group" "groups" {
  for_each                   = jsondecode(var.groups)
  provider                   = databricks.accounts
  display_name               = each.key
  allow_cluster_create       = each.value.allow_cluster_create
  allow_instance_pool_create = each.value.allow_instance_pool_create
  databricks_sql_access      = each.value.databricks_sql_access
  workspace_access           = each.value.workspace_access
  force                      = each.value.preexisting
}


# ---------------------------------------------------------------------------------------------------------------------
# Databricks Group Connection Creation
# ---------------------------------------------------------------------------------------------------------------------

#Flatten Group Connection into local variables
# group---users/sps for unique keys
# group---workspace---permission for workspace connections
locals {
  group_connections    = jsondecode(var.group_connections)
  workspace_dictionary = jsondecode(var.workspace_dictionary)
  workspace_assignment = jsondecode(var.workspace_assignment)


  flattened_users = tolist(flatten([
    for group, connections in local.group_connections : [
      for user, users in connections.users : [
      format("%s---%s", group, users)]
    ]
    ]
  ))
  flattened_sps = tolist(flatten([
    for group, connections in local.group_connections : [
      for sp, service_principals in connections.service_principals : [
      format("%s---%s", group, service_principals)]
    ]
    ]
  ))
  flattened_groups = tolist(flatten([
    for group, connections in local.group_connections : [
      for grp, groups in connections.groups : [
      format("%s---%s", group, groups)]
    ]
    ]
  ))
  flattened_workspaces = flatten([
    for group, connections in local.workspace_assignment : [
      for workspace, permissions in connections : [
      format("%s---%s---%s", group, workspace, permissions)]
    ]
    ]
  )

}

#Users
resource "databricks_group_member" "group_member_user" {
  for_each  = { for user in local.flattened_users : user => { group = split("---", user)[0], user_name = split("---", user)[1] } }
  provider  = databricks.accounts
  group_id  = databricks_group.groups[each.value.group].id
  member_id = databricks_user.user_creation[each.value.user_name].id
}


#Service Principals
resource "databricks_group_member" "group_member_sp" {
  for_each  = { for sp in local.flattened_sps : sp => { group = split("---", sp)[0], service_principal = split("---", sp)[1] } }
  provider  = databricks.accounts
  group_id  = databricks_group.groups[each.value.group].id
  member_id = databricks_service_principal.sp[each.value.service_principal].id
}


#Groups
resource "databricks_group_member" "group_member_grp" {
  for_each  = { for grp in local.flattened_groups : grp => { group = split("---", grp)[0], group_name = split("---", grp)[1] } }
  provider  = databricks.accounts
  group_id  = databricks_group.groups[each.value.group].id
  member_id = databricks_group.groups[each.value.group_name].id
}


#Workspace assignment
resource "databricks_mws_permission_assignment" "add_group" {
  for_each     = { for mws in local.flattened_workspaces : mws => { group = split("---", mws)[0], workspace = split("---", mws)[1], permission = split("---", mws)[2] } }
  provider     = databricks.accounts
  workspace_id = local.workspace_dictionary[each.value.workspace]
  principal_id = databricks_group.groups[each.value.group].id
  permissions  = [each.value.permission]
}
