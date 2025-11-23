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
