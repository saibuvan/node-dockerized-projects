# Create a custom Docker network for communication
resource "docker_network" "app_network" {
  name = "app_network"
}

# Pull the Node.js image
resource "docker_image" "node_app_image" {
  name = var.docker_image
}

# Pull the PostgreSQL image
resource "docker_image" "postgres_image" {
  name = var.postgres_image
  keep_locally = false
}

# Create a volume for PostgreSQL persistence
resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

# Create PostgreSQL container
resource "docker_container" "postgres_container" {
  name  = var.postgres_container_name
  image = docker_image.postgres_image.latest
  restart = "always"

  networks_advanced {
    name = docker_network.app_network.name
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

# Create Node.js app container
resource "docker_container" "node_app_container" {
  name  = var.container_name
  image = docker_image.node_app_image.name
  restart = "always"

  networks_advanced {
    name = docker_network.app_network.name
  }

  dynamic "ports" {
    for_each = toset(var.exposed_ports)
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

# Local message after deployment
output "postgres_connection" {
  value = "postgresql://${var.postgres_user}:${var.postgres_password}@localhost:${var.postgres_port}/${var.postgres_db}"
  sensitive = true
}

output "app_url" {
  value = "http://localhost:${var.host_port}"
}