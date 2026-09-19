terraform {
  required_version = ">= 1.6.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.12"
    }
  }
}

provider "vault" {
  address         = var.vault_addr
  skip_tls_verify = var.vault_skip_tls_verify
}
