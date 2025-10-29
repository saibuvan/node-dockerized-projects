terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

# -----------------------------
# 🐳 Docker Provider
# -----------------------------
provider "docker" {}

# -----------------------------
# 🧩 Docker Image
# -----------------------------
resource "docker_image" "node_app_image" {
  name = var.docker_image
}

# -----------------------------
# 🚀 Docker Container
# -----------------------------
resource "docker_container" "node_app_container" {
  name  = var.container_name
  image = docker_image.node_app_image.name

  # -----------------------------
  # 🔒 Expose required ports (App, HTTP, SSH)
  # -----------------------------
  dynamic "ports" {
    for_each = toset(var.exposed_ports)
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  restart = "always"

  # -----------------------------
  # 🧹 Graceful cleanup when destroying
  # -----------------------------
  provisioner "local-exec" {
    when    = destroy
    command = "docker rm -f ${self.name} || true"
  }

  lifecycle {
    prevent_destroy = false
  }
}