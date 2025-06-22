# Secrets Manager - Rails Master Key
resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${var.project_name}-rails-master-key"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = local.rails_master_key
}
