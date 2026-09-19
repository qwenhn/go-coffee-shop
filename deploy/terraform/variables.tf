variable "vault_addr" {
  type        = string
  description = "Vault API address."
  default     = "http://127.0.0.1:8200"
}

variable "vault_skip_tls_verify" {
  type        = bool
  description = "Skip Vault TLS certificate verification for local HTTP Vault."
  default     = true
}

variable "database_host" {
  type        = string
  description = "PostgreSQL hostname reachable from Vault."
  default     = "coffee-postgres"
}

variable "database_name" {
  type        = string
  description = "PostgreSQL database containing the service schemas."
  default     = "coffee"
}

variable "database_username" {
  type        = string
  description = "PostgreSQL administrator used by Vault to create leases."
  default     = "coffee"
}

variable "database_password" {
  type        = string
  description = "PostgreSQL administrator password used by Vault to create leases."
  sensitive   = true
  default     = "coffee-local"
}

variable "rabbitmq_host" {
  type        = string
  description = "RabbitMQ management hostname reachable from Vault."
  default     = "coffee-rabbitmq"
}

variable "rabbitmq_username" {
  type        = string
  description = "RabbitMQ administrator used by Vault to create leases."
  default     = "coffee"
}

variable "rabbitmq_password" {
  type        = string
  description = "RabbitMQ administrator password used by Vault to create leases."
  sensitive   = true
  default     = "coffee-local"
}

variable "nomad_jwks_url" {
  type        = string
  description = "Nomad workload identity JWKS URL reachable from Vault."
}
