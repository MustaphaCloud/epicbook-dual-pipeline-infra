variable "resource_group_name" {
  default = "epicbook-rg"
}

variable "location" {
  default = "southafricanorth"
}

variable "vm_name" {
  default = "epicbook-vm"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key content"
  default     = ""
}

variable "mysql_admin_username" {
  default = "epicadmin"
}

variable "mysql_admin_password" {
  default = "EpicBook@2025!"
}

variable "mysql_db_name" {
  default = "bookstore"
}