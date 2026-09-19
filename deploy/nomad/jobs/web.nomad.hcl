variable "image_tag" {
  type    = string
  default = "dev"
}

job "web" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 1

    network {
      mode = "bridge"

      port "http" {
        static = 8888
        to     = 8888
      }
    }

    service {
      name = "web"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "proxy"
              local_bind_port  = 5555
            }
          }
        }
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "go-coffee-shop-web:${var.image_tag}"
        ports = ["http"]
      }

      env {
        REVERSE_PROXY_URL = "http://127.0.0.1:5555"
        WEB_PORT          = "8888"
      }

      resources {
        cpu    = 250
        memory = 256
      }
    }
  }
}
