job "counter" {
  datacenters = ["dc1"]

  type = "service"

  group "counter" {

    count = 1

    network {
      mode = "bridge"

      port "grpc" {
        to = 5002
      }
    }

    service {
      name = "counter"
      port = "grpc"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "product"
              local_bind_port  = 5001
            }
          }
        }
      }
    }

    task "counter" {
      driver = "docker"

      vault {
        role = "coffee-counter"
      }

      config {
        image = "go-coffee-shop-counter:dev"
      }

      template {
        data = <<EOF
          {{ with secret "database/creds/coffee-counter" }}
          POSTGRES_USER={{ .Data.username }}
          POSTGRES_PASSWORD={{ .Data.password }}
          {{ end }}
        EOF

        destination = "secrets/postgres.env"
        env         = true

        change_mode = "restart"
      }

      template {
        data = <<EOF
          {{ with secret "rabbitmq/creds/coffee-counter" }}
          RABBITMQ_USER={{ .Data.username }}
          RABBITMQ_PASSWORD={{ .Data.password }}
          {{ end }}
        EOF

        destination = "secrets/rabbitmq.env"
        env         = true

        change_mode = "restart"
      }

      env {
        APP_NAME = "counter-service"

        POSTGRES_HOST = "postgres"
        POSTGRES_PORT = "5432"
        POSTGRES_DB   = "postgres"

        RABBITMQ_HOST  = "rabbitmq"
        RABBITMQ_PORT  = "5672"
        RABBITMQ_VHOST = "/"

        PRODUCT_CLIENT_URL = "127.0.0.1:5001"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
