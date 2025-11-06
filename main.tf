terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "docker" {}

resource "docker_network" "app_networkk" {
  name = "app_networkk"
}

resource "docker_image" "node_app_image" {
  name         = var.docker_image
  keep_locally = false
}

resource "docker_image" "postgres_image" {
  name         = var.postgres_image
  keep_locally = false
}

resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

resource "docker_container" "postgres_container" {
  name    = var.postgres_container_name
  image   = docker_image.postgres_image.image_id
  restart = "always"

  networks_advanced {
    name = docker_network.app_networkk.name
  }

  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}"
  ]

  ports {
    internal = 5432
    external = var.postgres_port
  }

  mounts {
    target = "/var/lib/postgresql/data"
    source = docker_volume.postgres_data.name
    type   = "volume"
  }
}

resource "docker_image" "pgadmin_image" {
  name         = var.pgadmin_image
  keep_locally = false
}

resource "docker_volume" "pgadmin_data" {
  name = "pgadmin_data"
}

resource "docker_container" "pgadmin_container" {
  name    = var.pgadmin_container_name
  image   = docker_image.pgadmin_image.image_id
  restart = "always"

  networks_advanced {
    name = docker_network.app_networkk.name
  }

  env = [
    "PGADMIN_DEFAULT_EMAIL=${var.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${var.pgadmin_password}"
  ]

  ports {
    internal = 80
    external = var.pgadmin_port
  }

  mounts {
    target = "/var/lib/pgadmin"
    source = docker_volume.pgadmin_data.name
    type   = "volume"
  }

  depends_on = [docker_container.postgres_container]
}

resource "docker_container" "node_app_container" {
  name    = var.container_name
  image   = docker_image.node_app_image.image_id
  restart = "always"

  networks_advanced {
    name = docker_network.app_networkk.name
  }

  dynamic "ports" {
    for_each = var.exposed_ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  env = [
    "DB_HOST=${docker_container.postgres_container.name}",
    "DB_PORT=${var.postgres_port}",
    "DB_USER=${var.postgres_user}",
    "DB_PASSWORD=${var.postgres_password}",
    "DB_NAME=${var.postgres_db}"
  ]

  depends_on = [docker_container.postgres_container]
}

output "postgres_connection_string" {
  value     = "postgresql://${var.postgres_user}:${var.postgres_password}@localhost:${var.postgres_port}/${var.postgres_db}"
  sensitive = true
}

output "pgadmin_url" {
  value = "http://localhost:${var.pgadmin_port}"
}

output "app_url" {
  value = "http://localhost:${var.host_port}"
}
