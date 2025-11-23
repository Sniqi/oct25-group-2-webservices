terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

resource "docker_network" "app_network" {
  name = "dataops-network"
}

# --- DATABASE ---

resource "docker_volume" "db_data" {
  name = "dataops-db-data"
}

resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

resource "docker_container" "db" {
  image = docker_image.postgres.image_id
  name  = "dataops-db"
  networks_advanced {
    name = docker_network.app_network.name
  }
  env = [
    "POSTGRES_USER=dataops",
    "POSTGRES_PASSWORD=secretpassword",
    "POSTGRES_DB=dataopsdb"
  ]
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U dataops -d dataopsdb"]
    interval = "5s"
    retries  = 5
  }
}

# --- APP ---

resource "docker_image" "app" {
  name         = "sniqi/dataops-demo:dev-latest"
  keep_locally = false
  pull_triggers = ["${timestamp()}"]
}

resource "docker_container" "app" {
  image = docker_image.app.image_id
  name  = "dataops-app"
  networks_advanced {
    name = docker_network.app_network.name
  }
  env = [
    "ENV=local-terraform",
    "DB_HOST=dataops-db",
    "DB_USER=dataops",
    "DB_PASSWORD=secretpassword",
    "DB_NAME=dataopsdb"
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
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 80
    external = 8080
  }
  volumes {
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
  }
}
