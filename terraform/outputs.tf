output "container_id" {
  value = docker_container.node_app_container.id
}

output "container_name" {
  value = docker_container.node_app_container.name
}

output "image_used" {
  value = docker_image.node_app_image.name
}
