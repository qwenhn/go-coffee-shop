datacenter = "dc1"
data_dir   = "/tmp/nomad-data"

bind_addr = "0.0.0.0"

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc  = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true

  cni_path = "/opt/cni/bin"

  servers = [
    "127.0.0.1:4647",
  ]

  host_volume "data" {
    path      = "/tmp/nomad-data"
    read_only = false
  }
}

ui {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"

  auto_advertise   = true
  checks_use_advertise = true
  server_auto_join = true
  client_auto_join = true
}

vault {
  enabled = true
  address = "http://127.0.0.1:8200"

  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}
