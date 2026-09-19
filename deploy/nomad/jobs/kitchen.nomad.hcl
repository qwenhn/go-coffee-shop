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

      config {
        image = "ghcr.io/qwenhn/go-coffee-shop/kitchen:${var.image_tag}"
      }

      env {
        APP_NAME = "kitchen-service"

        PG_POOL_MAX = "10"

        PG_DSN_URL = "host=host.docker.internal user=coffee password=coffee dbname=coffee sslmode=disable"

        RABBITMQ_URL = "amqp://coffee:coffee@host.docker.internal:5672/"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
