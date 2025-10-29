output "container_id" {
  description = "ID of the created Docker container"
  value       = docker_container.node_app_container.id
}

output "container_name" {
  description = "Name of the Docker container"
  value       = docker_container.node_app_container.name
}

output "image_used" {
  description = "Docker image used for the container"
  value       = docker_image.node_app_image.name
}

output "exposed_ports" {
  description = "Ports exposed from the container"
  value = [
    "3000 (Node App)",
    "80 (HTTP)",
    "22 (SSH)"
  ]
}