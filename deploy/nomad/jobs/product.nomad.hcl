variable "image_tag" {
  type    = string
  default = "dev"
}

job "product" {
  datacenters = ["dc1"]
  type        = "service"

  group "product" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "product"
      port = 5001

      tags = [
        "coffee-shop",
        "grpc",
      ]

      connect {
        sidecar_service {
          proxy {
            local_service_address = "127.0.0.1"
            local_service_port    = 5001

            config {
              protocol = "grpc"
            }
          }
        }
      }
    }

    task "product" {
      driver = "docker"

      config {
        image = "go-coffee-shop-product:${var.image_tag}"

        ports = [
          "grpc",
        ]
      }

      env {
        APP_NAME = "product-service"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
