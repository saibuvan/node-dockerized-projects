variable "docker_image" {
  description = "Docker image with tag"
  type        = string
  default     = "buvan654321/my-node-app:9.0"
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "my-node-app-container"
}

variable "host_port" {
  description = "Host port to expose"
  type        = number
  default     = 8089
}
