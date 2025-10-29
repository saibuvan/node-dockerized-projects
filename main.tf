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

resource "docker_image" "node_app_image" {
  name = var.docker_image
}

resource "docker_container" "node_app_container" {
  name  = var.container_name
  image = docker_image.node_app_image.name

  dynamic "ports" {
    for_each = toset(var.exposed_ports)
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  restart = "always"
  
  provisioner "local-exec" {
    when    = destroy
    command = "docker rm -f ${self.name} || true"
  }

  lifecycle {
    prevent_destroy = false
  }
}