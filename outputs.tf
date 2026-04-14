output "app_public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "Public IP address of the EpicBook VM"
}

output "mysql_fqdn" {
  value       = azurerm_mysql_flexible_server.mysql.fqdn
  description = "FQDN of the MySQL Flexible Server"
}

output "mysql_admin_username" {
  value       = var.mysql_admin_username
  description = "MySQL admin username"
}

output "mysql_db_name" {
  value       = var.mysql_db_name
  description = "MySQL database name"
}