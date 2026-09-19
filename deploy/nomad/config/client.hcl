client {
  enabled = true

  servers = [
    "127.0.0.1:4647"
  ]

  alloc_dir = "/opt/nomad/alloc"
}

plugin "docker" {
  config {
    endpoint = "unix:///var/run/docker.sock"
  }
}

consul {
  address = "127.0.0.1:8500"

  auto_advertise   = true
  server_auto_join = true
  client_auto_join = true
}
