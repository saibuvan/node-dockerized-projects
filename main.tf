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

# Pull image from Docker Hub
resource "docker_image" "node_app_image" {
  name = var.docker_image
}

# Run container locally
resource "docker_container" "node_app_container" {
  name  = var.container_name
  image = docker_image.node_app_image.name

  ports {
    internal = 3000
    external = var.host_port
  }

  restart = "always"

  # 🔧 Handle duplicate container issues gracefully
  provisioner "local-exec" {
    when    = destroy
    command = "docker rm -f ${self.name} || true"
  }

  lifecycle {
    prevent_destroy = false
  }
}

