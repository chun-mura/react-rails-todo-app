# Secrets Manager - データベースパスワード
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}-db-password-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Secrets Manager - RDS Proxy認証用
resource "aws_secretsmanager_secret" "rds_proxy_auth" {
  name = "${var.project_name}-rds-proxy-auth-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
}

resource "aws_secretsmanager_secret_version" "rds_proxy_auth" {
  secret_id = aws_secretsmanager_secret.rds_proxy_auth.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# ランダムパスワード生成
resource "random_password" "db_password" {
  length      = 16
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  # RDS制限: '/', '@', '"', ' ' は使用不可
  # URLエンコードの問題も避けるため、安全な特殊文字のみ使用
  override_special = "!#$%&*()_+-=[]{}|;:,.<>?"
}

# Aurora PostgreSQL クラスター
resource "aws_rds_cluster" "main" {
  cluster_identifier        = "${var.project_name}-aurora-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "15.10"
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = random_password.db_password.result
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  deletion_protection       = true # 削除する場合はfalse
  # apply_immediately         = true # アンコメントで即時反映

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  tags = {
    Name = "${var.project_name}-aurora-cluster"
  }
}

# Aurora PostgreSQL インスタンス
resource "aws_rds_cluster_instance" "main" {
  count              = 2
  identifier         = "${var.project_name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t4g.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  # apply_immediately  = true # アンコメントで即時反映

  tags = {
    Name = "${var.project_name}-aurora-instance-${count.index + 1}"
  }
}

# RDS Proxy
resource "aws_db_proxy" "main" {
  name                   = "${var.project_name}-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  vpc_subnet_ids         = aws_subnet.private[*].id

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_proxy_auth.arn
  }

  tags = {
    Name = "${var.project_name}-proxy"
  }
}

# RDS Proxy エンドポイント
resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_cluster_identifier = aws_rds_cluster.main.id
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main.name
}

# IAMロール - RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  name = "${var.project_name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

# IAMポリシー - RDS Proxy (Secrets Manager)
resource "aws_iam_role_policy" "rds_proxy" {
  name = "${var.project_name}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.rds_proxy_auth.arn
        ]
      }
    ]
  })
}
