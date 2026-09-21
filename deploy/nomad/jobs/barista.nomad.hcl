variable "image_tag" {
  type    = string
  default = "dev"
}

job "barista" {
  datacenters = ["dc1"]
  type        = "service"

  group "barista" {
    count = 1

    task "barista" {
      driver = "docker"

      vault {
        role = "coffee-barista"
      }

      config {
        image = "go-coffee-shop-barista:${var.image_tag}"
      }

      template {
        data = <<EOF
          {{ with secret "database/creds/coffee-barista" }}
          PG_DSN_URL=host=host.docker.internal port=5432 user={{ .Data.username }} password={{ .Data.password }} dbname=postgres sslmode=disable
          {{ end }}
        EOF

        destination = "secrets/postgres.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data = <<EOF
          {{ with secret "rabbitmq/creds/coffee-barista" }}
          RABBITMQ_URL=amqp://{{ .Data.username }}:{{ .Data.password }}@host.docker.internal:5672/
          {{ end }}
        EOF

        destination = "secrets/rabbitmq.env"
        env         = true
        change_mode = "restart"
      }

      env {
        APP_NAME = "barista-service"

        PG_POOL_MAX = "10"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
