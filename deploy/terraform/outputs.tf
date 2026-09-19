output "vault_jwt_auth_backend_path" {
  value = vault_jwt_auth_backend.nomad.path
}

output "database_roles" {
  value = [for role in vault_database_secret_backend_role.postgres : role.name]
}

output "rabbitmq_roles" {
  value = [for role in vault_rabbitmq_secret_backend_role.rabbitmq : role.name]
}
