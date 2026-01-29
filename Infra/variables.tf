variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "sql_admin_username" {
  type    = string
  default = "user"
}

variable "sql_admin_password" {
  type    = string
  default = "Vivek@123"
}
