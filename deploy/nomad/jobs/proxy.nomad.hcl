variable "image_tag" {
  type    = string
  default = "dev"
}

job "proxy" {
  datacenters = ["dc1"]
  type        = "service"

  group "proxy" {
    count = 2

    network {
      mode = "bridge"

      port "http" {
        to = 5000
      }
    }

    service {
      name = "proxy"
      port = "http"
      address_mode = "host"

      tags = [
        "coffee-shop",
        "http",
      ]

      connect {
        sidecar_service {
          proxy {
            local_service_address = "127.0.0.1"
            local_service_port    = 5000

            upstreams {
              destination_name = "product"
              local_bind_port  = 5001

              config {
                protocol = "grpc"
              }
            }

            upstreams {
              destination_name = "counter"
              local_bind_port  = 5002

              config {
                protocol = "grpc"
              }
            }
          }
        }
      }
    }

    task "proxy" {
      driver = "docker"

      config {
        image = "go-coffee-shop-proxy:${var.image_tag}"
        ports = ["http"]
      }

      env {
        APP_NAME = "proxy-service"

        GRPC_PRODUCT_HOST = "127.0.0.1"
        GRPC_PRODUCT_PORT = "5001"

        GRPC_COUNTER_HOST = "127.0.0.1"
        GRPC_COUNTER_PORT = "5002"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
