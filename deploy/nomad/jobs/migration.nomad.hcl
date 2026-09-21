variable "image_tag" {
  type    = string
  default = "dev"
}

job "coffee-migration" {
  datacenters = ["dc1"]

  type = "batch"

  group "migration" {

    network {
      mode = "bridge"
    }

    task "migrate" {
      driver = "docker"

      config {
        image = "go-coffee-shop-migration:${var.image_tag}"

        args = [
          "-path=/migrations",
          "-database",
          "postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable",
          "up"
        ]
      }

      template {
        data = <<EOF
            POSTGRES_USER={{ env "POSTGRES_USER" }}
            POSTGRES_PASSWORD={{ env "POSTGRES_PASSWORD" }}
            POSTGRES_DB={{ env "POSTGRES_DB" }}
        EOF

        destination = "local/postgres.env"
        env         = true
      }
    }
  }
}
