locals {
  services = toset([
    "barista",
    "counter",
    "kitchen",
  ])
}

resource "vault_mount" "database" {
  path = "database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgres"
  allowed_roles = [for service in local.services : "coffee-${service}"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${var.database_host}:5432/${var.database_name}?sslmode=disable"
    username       = var.database_username
    password       = var.database_password
  }
}

resource "vault_database_secret_backend_role" "postgres" {
  for_each = local.services

  backend = vault_mount.database.path
  name    = "coffee-${each.value}"
  db_name = vault_database_secret_backend_connection.postgres.name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT CONNECT ON DATABASE \"${var.database_name}\" TO \"{{name}}\";",
    "GRANT USAGE ON SCHEMA \"order\", \"barista\", \"kitchen\" TO \"{{name}}\";",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA \"order\", \"barista\", \"kitchen\" TO \"{{name}}\";",
    "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA \"order\", \"barista\", \"kitchen\" TO \"{{name}}\";",
  ]

  revocation_statements = [
    "REASSIGN OWNED BY \"{{name}}\" TO \"${var.database_username}\";",
    "DROP OWNED BY \"{{name}}\";",
    "DROP ROLE IF EXISTS \"{{name}}\";",
  ]

  default_ttl = 3600
  max_ttl     = 86400
}

resource "vault_rabbitmq_secret_backend" "rabbitmq" {
  path              = "rabbitmq"
  connection_uri    = "http://${var.rabbitmq_host}:15672"
  username          = var.rabbitmq_username
  password          = var.rabbitmq_password
  verify_connection = true
}

resource "vault_rabbitmq_secret_backend_role" "rabbitmq" {
  for_each = local.services

  backend = vault_rabbitmq_secret_backend.rabbitmq.path
  name    = "coffee-${each.value}"
  tags    = "management"

  vhost {
    host      = "/"
    configure = ".*"
    read      = ".*"
    write     = ".*"
  }
}

resource "vault_policy" "service" {
  for_each = local.services

  name = "coffee-${each.value}"
  policy = templatefile("${path.module}/../vault/policies/${each.value}.hcl", {
    service = each.value
  })
}

resource "vault_jwt_auth_backend" "nomad" {
  path        = "jwt-nomad"
  type        = "jwt"
  description = "Nomad workload identity authentication"
  jwks_url    = var.nomad_jwks_url
}

resource "vault_jwt_auth_backend_role" "service" {
  for_each = local.services

  backend                 = vault_jwt_auth_backend.nomad.path
  role_name               = "coffee-${each.value}"
  role_type               = "jwt"
  user_claim              = "/nomad_job_id"
  user_claim_json_pointer = true
  bound_audiences         = ["vault.io"]
  token_policies          = [vault_policy.service[each.value].name]
  token_ttl               = 3600
  token_max_ttl           = 86400
}
