resource "null_resource" "ha_sku_check" {
  count = local.local_data[var.idh_resource].high_availability_enabled == true && length(regexall("^B_.*", local.local_data[var.idh_resource].sku_name)) > 0 ? "ERROR: High Availability is not allow for Burstable(B) series" : 0
}

resource "null_resource" "pgbouncer_check" {
  count = length(regexall("^B_.*", local.local_data[var.idh_resource].sku_name)) > 0 && local.local_data[var.idh_resource].pgbouncer_enabled ? "ERROR: PgBouncer is not allow for Burstable(B) series" : 0
}

locals {
  local_data = jsondecode(file("${path.module}/../idh/${var.prefix}/${var.env}/idh.json"))

}


resource "azurerm_postgresql_flexible_server" "this" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  
  version             = local.local_data[var.idh_resource].db_version
  #
  # Backup
  #
  backup_retention_days        = local.local_data[var.idh_resource].backup_retention_days
  geo_redundant_backup_enabled = local.local_data[var.idh_resource].geo_redundant_backup_enabled
  create_mode                  = local.local_data[var.idh_resource].create_mode
  zone                         = local.local_data[var.idh_resource].zone

  #
  # Network
  #

  # The provided subnet should not have any other resource deployed in it and this subnet will be delegated to the PostgreSQL Flexible Server, if not already delegated.
  delegated_subnet_id = local.local_data[var.idh_resource].private_endpoint_enabled ? var.delegated_subnet_id : null
  #  private_dns_zobe_id will be required when setting a delegated_subnet_id
  private_dns_zone_id           = local.local_data[var.idh_resource].private_endpoint_enabled ? var.private_dns_zone_id : null
  public_network_access_enabled = local.local_data[var.idh_resource].public_network_access_enabled

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  storage_mb = local.local_data[var.idh_resource].storage_mb
  sku_name   = local.local_data[var.idh_resource].sku_name

  auto_grow_enabled = var.auto_grow_enabled

  dynamic "high_availability" {
    for_each = local.local_data[var.idh_resource].high_availability_enabled && local.local_data[var.idh_resource].standby_availability_zone != null ? ["dummy"] : []

    content {
      #only possible value
      mode                      = "ZoneRedundant"
      standby_availability_zone = local.local_data[var.idh_resource].standby_availability_zone
    }
  }

  # Enable Customer managed key encryption
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_enabled ? [1] : []
    content {
      key_vault_key_id                  = var.customer_managed_key_kv_key_id
      primary_user_assigned_identity_id = var.primary_user_assigned_identity_id
    }
  }

  dynamic "identity" {
    for_each = var.customer_managed_key_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.primary_user_assigned_identity_id]
    }

  }

  dynamic "maintenance_window" {
    for_each = local.local_data[var.idh_resource].maintenance_window_config != null ? ["dummy"] : []

    content {
      day_of_week  = local.local_data[var.idh_resource].maintenance_window_config.day_of_week
      start_hour   = local.local_data[var.idh_resource].maintenance_window_config.start_hour
      start_minute = local.local_data[var.idh_resource].maintenance_window_config.start_minute
    }
  }

  tags = var.tags

} # end azurerm_postgresql_flexible_server

# Configure: Enable PgBouncer
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_enabled" {

  count = local.local_data[var.idh_resource].pgbouncer_enabled ? 1 : 0

  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "True"
}


resource "azurerm_private_dns_cname_record" "cname_record" {
  count               = var.private_dns_registration ? 1 : 0
  name                = var.private_dns_record_cname
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.private_dns_zone_rg_name
  ttl                 = var.private_dns_cname_record_ttl
  record              = azurerm_postgresql_flexible_server.this.fqdn
}
