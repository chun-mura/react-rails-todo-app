# Secrets Manager - Rails Master Key
resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${var.project_name}-rails-master-key-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = local.rails_master_key
}

# Secrets Manager - JWT Secret Key
resource "aws_secretsmanager_secret" "jwt_secret_key" {
  name = "${var.project_name}-jwt-secret-key-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
}

resource "aws_secretsmanager_secret_version" "jwt_secret_key" {
  secret_id     = aws_secretsmanager_secret.jwt_secret_key.id
  secret_string = local.jwt_secret_key
}
