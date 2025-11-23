# --- APP ---

resource "docker_image" "app" {
  name         = "${var.docker_username}/dataops-demo:dev-latest"
  keep_locally = false
  pull_triggers = ["${timestamp()}"]
}

resource "docker_container" "app" {
  image = docker_image.app.image_id
  name  = "dataops-app"
  networks_advanced {
    name = docker_network.app_network.name
  }
  # Environment variables must match those expected in app/main.py
  env = [
    "ENV=${var.app_env}",
    "DB_HOST=dataops-db", # Matches the container name of the database
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "DB_NAME=${var.db_name}"
  ]
  depends_on = [docker_container.db]
}

# --- NGINX ---

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "dataops-nginx"
  depends_on = [docker_container.app]
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 80
    external = 8080
  }
  volumes {
    host_path      = abspath("${path.module}/config/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
  }
  # Restart container if config changes
  env = [
    "CONFIG_HASH=${filesha256("${path.module}/config/nginx.conf")}"
  ]
}
