variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "sql_admin_user" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}