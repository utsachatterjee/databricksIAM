variable "users" {
  description = "User List JSON"
}

variable "service_principals" {
  description = "Service principal JSON"
}

variable "access_control_rule_sets" {
  description = "access control rule sets"
}

variable "account_id" {
  description = "Account id for databricks"
}

variable "groups" {
  description = "Group JSON"
}

variable "group_connections" {
  description = "Group Connections JSON"
}

variable "workspace_dictionary" {
  description = "Dictionary reference for workspace ID grabbing"
}

variable "workspace_assignment" {
  description = "Workspace Assignment JSON"
}

variable "databricks_workspace_url" {
  type = string
}
