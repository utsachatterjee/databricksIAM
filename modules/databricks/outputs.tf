output "users" {
  description = "The name of the resource group"
  value       = databricks_user.user_creation[*]
}
output "groups" {
  description = "The databricks group resource output"
  value       = data.databricks_group.groups[*]
}

output "service_principals" {
  description = "The databricks service principal resource output"
  value       = databricks_service_principal.sp[*]
}
