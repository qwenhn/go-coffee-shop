variable "image_tag" {
  type    = string
  default = "dev"
}

job "kitchen" {
  datacenters = ["dc1"]
  type        = "service"

  group "kitchen" {
    count = 1

    task "kitchen" {
      driver = "docker"

      vault {
        role = "coffee-kitchen"
      }

      config {
        image = "go-coffee-shop-kitchen:${var.image_tag}"
      }

      template {
        data = <<EOF
          {{ with secret "database/creds/coffee-kitchen" }}
          PG_DSN_URL=host=host.docker.internal port=5432 user={{ .Data.username }} password={{ .Data.password }} dbname=postgres sslmode=disable
          {{ end }}
        EOF

        destination = "secrets/postgres.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data = <<EOF
          {{ with secret "rabbitmq/creds/coffee-kitchen" }}
          RABBITMQ_URL=amqp://{{ .Data.username }}:{{ .Data.password }}@host.docker.internal:5672/
          {{ end }}
        EOF

        destination = "secrets/rabbitmq.env"
        env         = true
        change_mode = "restart"
      }

      env {
        APP_NAME = "kitchen-service"

        PG_POOL_MAX = "10"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
