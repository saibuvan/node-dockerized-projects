variable "docker_image" {
  description = "Docker image to use"
  type        = string
  default     = "buvan654321/my-node-app:latest"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "node_app_container"
}

variable "host_port" {
  description = "External port for the Node app"
  type        = number
  default     = 3000
}