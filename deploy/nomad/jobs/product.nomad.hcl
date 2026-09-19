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

      port "grpc" {
        to = 5001
      }
    }

    service {
      name = "product"
      port = "grpc"

      tags = [
        "coffee-shop",
        "grpc",
      ]

      connect {
        sidecar_service {}
      }
    }

    task "product" {
      driver = "docker"

      config {
        image = "ghcr.io/qwenhn/go-coffee-shop/product:${var.image_tag}"

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
