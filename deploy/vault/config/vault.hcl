ui = true

disable_mlock = true

api_addr = "http://coffee-vault:8200"

cluster_addr = "http://coffee-vault:8201"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

storage "raft" {
  path    = "/vault/file"
  node_id = "vault-local"
}
