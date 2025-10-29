# Display the Docker container ID
output "container_id" {
  description = "ID of the created Docker container"
  value       = docker_container.node_app_container.id
}

# Display the Docker container name
output "container_name" {
  description = "Name of the Docker container"
  value       = docker_container.node_app_container.name
}

# Display the Docker image used
output "image_used" {
  description = "Docker image used for this container"
  value       = docker_image.node_app_image.name
}

# Display all exposed ports (App, HTTP, SSH)
output "exposed_ports" {
  description = "Ports exposed from the container"
  value = {
    app_port  = var.host_port
    http_port = 80
    ssh_port  = 22
  }
}