# ========================
# Node.js Application Vars
# ========================
variable "docker_image" {
  type    = string
  default = "buvan654321/my-node-app:10.0"
}

variable "container_name" {
  type    = string
  default = "my-node-app-container"
}

variable "host_port" {
  type    = number
  default = 3000
}

variable "exposed_ports" {
  type = list(object({
    internal = number
    external = number
  }))
  default = [
    { internal = 3000, external = 3000 }
  ]
}

# ========================
# PostgreSQL Vars
# ========================
variable "postgres_image" {
  type    = string
  default = "postgres:16"
}

variable "postgres_container_name" {
  type    = string
  default = "postgres_container"
}

variable "postgres_user" {
  type    = string
  default = "admin"
}

variable "postgres_password" {
  type      = string
  default   = "admin123"
  sensitive = true
}

variable "postgres_db" {
  type    = string
  default = "node_app_db"
}

variable "postgres_port" {
  type    = number
  default = 5432
}

# ========================
# pgAdmin Vars (NEW)
# ========================
variable "pgadmin_image" {
  type    = string
  default = "dpage/pgadmin4:latest"
}

variable "pgadmin_container_name" {
  type    = string
  default = "pgadmin_container"
}

variable "pgadmin_email" {
  type    = string
  default = "admin@admin.com"
}

variable "pgadmin_password" {
  type      = string
  default   = "admin123"
  sensitive = true
}

variable "pgadmin_port" {
  type    = number
  default = 8030
}