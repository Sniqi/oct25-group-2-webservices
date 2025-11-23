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
    host_path      = abspath("${path.module}/config/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
  }
  volumes {
    host_path      = abspath("${path.module}/config/alert_rules.yml")
    container_path = "/etc/prometheus/alert_rules.yml"
  }
  # Restart container if config changes
  env = [
    "CONFIG_HASH_PROM=${filesha256("${path.module}/config/prometheus.yml")}",
    "CONFIG_HASH_RULES=${filesha256("${path.module}/config/alert_rules.yml")}"
  ]
}

# Alertmanager
resource "docker_image" "alertmanager" {
  name         = "prom/alertmanager:latest"
  keep_locally = true
}

resource "docker_container" "alertmanager" {
  image = docker_image.alertmanager.image_id
  name  = "dataops-alertmanager"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 9093
    external = 9093
  }
  volumes {
    host_path      = abspath("${path.module}/config/alertmanager.yml")
    container_path = "/etc/alertmanager/alertmanager.yml"
  }
  # Restart container if config changes
  env = [
    "CONFIG_HASH=${filesha256("${path.module}/config/alertmanager.yml")}"
  ]
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
    host_path      = abspath("${path.module}/config/loki.yml")
    container_path = "/etc/loki/local-config.yaml"
  }
  # Restart container if config changes
  env = [
    "CONFIG_HASH=${filesha256("${path.module}/config/loki.yml")}"
  ]
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
    host_path      = abspath("${path.module}/config/promtail.yml")
    container_path = "/etc/promtail/config.yml"
  }
  # Mount Docker socket to read container logs
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  # Restart container if config changes
  env = [
    "CONFIG_HASH=${filesha256("${path.module}/config/promtail.yml")}"
  ]
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

# Locust (Load Testing)
resource "docker_image" "locust" {
  name         = "locustio/locust"
  keep_locally = true
}

resource "docker_container" "locust" {
  image = docker_image.locust.image_id
  name  = "dataops-locust"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 8089
    external = 8089
  }
  volumes {
    # Mounts the Locustfile from the tests folder
    host_path      = abspath("${path.module}/../../tests/load/locustfile.py")
    container_path = "/mnt/locust/locustfile.py"
  }
  # Starts Locust with Web Interface
  command = ["-f", "/mnt/locust/locustfile.py"]
}
