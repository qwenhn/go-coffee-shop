variable "image_tag" {
  type    = string
  default = "dev"
}

job "counter" {
  datacenters = ["dc1"]

  type = "service"

  group "counter" {

    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "counter"
      port = 5002

      connect {
        sidecar_service {
          proxy {
            local_service_address = "127.0.0.1"
            local_service_port    = 5002

            config {
              protocol = "grpc"
            }

            upstreams {
              destination_name = "product"
              local_bind_port  = 5001

              config {
                protocol = "grpc"
              }
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
        image = "go-coffee-shop-counter:${var.image_tag}"
      }

      template {
        data = <<EOF
          {{ with secret "database/creds/coffee-counter" }}
          PG_DSN_URL=host=host.docker.internal port=5432 user={{ .Data.username }} password={{ .Data.password }} dbname=postgres sslmode=disable
          {{ end }}
        EOF

        destination = "secrets/postgres.env"
        env         = true

        change_mode = "restart"
      }

      template {
        data = <<EOF
          {{ with secret "rabbitmq/creds/coffee-counter" }}
          RABBITMQ_URL=amqp://{{ .Data.username }}:{{ .Data.password }}@host.docker.internal:5672/
          {{ end }}
        EOF

        destination = "secrets/rabbitmq.env"
        env         = true

        change_mode = "restart"
      }

      env {
        APP_NAME = "counter-service"

        PRODUCT_CLIENT_URL = "127.0.0.1:5001"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
