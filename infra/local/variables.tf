variable "docker_username" {
  description = "Docker Hub username"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "dataops"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dataopsdb"
}

variable "app_env" {
  description = "Application environment"
  type        = string
  default     = "local-terraform"
}
