locals {
  local_data = jsondecode(file("${path.module}/../idh/${var.prefix}/${var.env}/idh.json"))
}


module "pgflex" {
  source = "../../../__idh__.__v4__/postgres_flexible_server"

  administrator_login = var.administrator_login
  administrator_password = var.administrator_password
  db_version = local.local_data[var.idh_resource].db_version
  high_availability_enabled = local.local_data[var.idh_resource].high_availability_enabled
  standby_availability_zone = local.local_data[var.idh_resource].standby_availability_zone
  location = var.location
  name = var.name
  private_endpoint_enabled = local.local_data[var.idh_resource].private_endpoint_enabled
  resource_group_name = var.resource_group_name
  sku_name = local.local_data[var.idh_resource].sku_name
  storage_mb = local.local_data[var.idh_resource].storage_mb

  backup_retention_days        = local.local_data[var.idh_resource].backup_retention_days
  geo_redundant_backup_enabled = local.local_data[var.idh_resource].geo_redundant_backup_enabled
  create_mode                  = local.local_data[var.idh_resource].create_mode
  zone                         = local.local_data[var.idh_resource].zone

  delegated_subnet_id = local.local_data[var.idh_resource].private_endpoint_enabled ? var.delegated_subnet_id : null
  private_dns_zone_id           = local.local_data[var.idh_resource].private_endpoint_enabled ? var.private_dns_zone_id : null
  public_network_access_enabled = local.local_data[var.idh_resource].public_network_access_enabled

  customer_managed_key_enabled = var.customer_managed_key_enabled
  customer_managed_key_kv_key_id = var.customer_managed_key_kv_key_id
  primary_user_assigned_identity_id = var.primary_user_assigned_identity_id

  auto_grow_enabled = var.auto_grow_enabled

  maintenance_window_config = local.local_data[var.idh_resource].maintenance_window_config

  private_dns_registration = var.private_dns_registration
  private_dns_record_cname = var.private_dns_record_cname
  private_dns_zone_name = var.private_dns_zone_name
  private_dns_zone_rg_name = var.private_dns_zone_rg_name
  private_dns_cname_record_ttl = var.private_dns_cname_record_ttl

  pgbouncer_enabled = local.local_data[var.idh_resource].pgbouncer_enabled

  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostic_setting_destination_storage_id = var.diagnostic_setting_destination_storage_id
  diagnostic_settings_enabled = var.diagnostic_settings_enabled

  tags = var.tags

}