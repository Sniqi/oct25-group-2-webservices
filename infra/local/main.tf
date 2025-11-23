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
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}"
  ]
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
    interval = "5s"
    retries  = 5
  }
}

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
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
  }
}

# --- MONITORING ---

# Prometheus
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  image = docker_image.prometheus.image_id
  name  = "dataops-prometheus"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 9090
    external = 9090
  }
  volumes {
    host_path      = abspath("${path.module}/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# Loki (Log Aggregation)
resource "docker_image" "loki" {
  name         = "grafana/loki:2.9.2"
  keep_locally = true
}

resource "docker_container" "loki" {
  image = docker_image.loki.image_id
  name  = "dataops-loki"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 3100
    external = 3100
  }
  volumes {
    host_path      = abspath("${path.module}/loki.yml")
    container_path = "/etc/loki/local-config.yaml"
  }
}

# Promtail (Log Collector)
resource "docker_image" "promtail" {
  name         = "grafana/promtail:2.9.2"
  keep_locally = true
}

resource "docker_container" "promtail" {
  image = docker_image.promtail.image_id
  name  = "dataops-promtail"
  networks_advanced {
    name = docker_network.app_network.name
  }
  volumes {
    host_path      = abspath("${path.module}/promtail.yml")
    container_path = "/etc/promtail/config.yml"
  }
  # Mount Docker socket to read container logs
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
}

# Grafana
resource "docker_volume" "grafana_data" {
  name = "dataops-grafana-data"
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.image_id
  name  = "dataops-grafana"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 3000
    external = 3000
  }
  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]
  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }
}
