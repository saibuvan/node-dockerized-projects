variable "docker_image" {
  description = "Docker image to use"
  type        = string
  default     = "buvan654321/my-node-app:latest"
}

variable "container_name" {
  description = "Name of the Docker container"
  type        = string
  default     = "my-node-app-container"
}

variable "host_port" {
  description = "External port for the Node.js app"
  type        = number
  default     = 3000
}

variable "exposed_ports" {
  description = "List of ports to expose (app, HTTP, SSH)"
  type = list(object({
    internal = number
    external = number
  }))
  default = [
    { internal = 3000, external = 3000 }, # Node.js app
    { internal = 80,   external = 80 },   # HTTP
    { internal = 22,   external = 22 }    # SSH
  ]
}