# Todo App AWS Infrastructure

このディレクトリには、TodoアプリケーションをAWSにデプロイするためのTerraform設定が含まれています。

## アーキテクチャ

以下のAWSサービスを使用してインフラを構築します：

- **VPC**: ネットワーク分離
- **ECS Fargate**: コンテナオーケストレーション
- **ECR**: コンテナイメージの保存
- **ALB**: ロードバランサー
- **Aurora PostgreSQL**: データベース
- **RDS Proxy**: データベース接続プール
- **CloudFront**: CDNとキャッシュ
- **WAF**: Webアプリケーションファイアウォール
- **Route 53**: DNS管理
- **ACM**: SSL証明書
- **Secrets Manager**: シークレット管理
- **CloudWatch**: 監視とログ
- **IAM**: アクセス制御

## 前提条件

1. AWS CLIがインストールされ、設定されている
2. Terraformがインストールされている（バージョン >= 1.0）
3. S3バケットが作成されている（Terraform状態ファイル用）

## セットアップ

### 1. S3バケットの作成

Terraform状態ファイルを保存するためのS3バケットを作成します：

```bash
aws s3 mb s3://react-rails-todo-app-20250622 --region ap-northeast-1
aws s3api put-bucket-versioning --bucket react-rails-todo-app-20250622 --versioning-configuration Status=Enabled
```

### 2. シークレットの管理（推奨: Parameter Store方式）

**重要**: シークレットは絶対にGitHubにコミットしないでください！

#### 推奨方法: AWS Systems Manager Parameter Store

```bash
# シークレット設定スクリプトを実行
./scripts/setup-secrets.sh --method parameter-store --force

# Terraform実行（自動でParameter Storeから読み込み）
terraform apply
```

#### 代替方法: 環境変数方式

```bash
# シークレット設定スクリプトを実行
./scripts/setup-secrets.sh --method env

# 環境変数を読み込み
source .env

# Terraform実行時に環境変数を渡す
terraform apply \
  -var="jwt_secret_key=$JWT_SECRET_KEY" \
  -var="rails_master_key=$RAILS_MASTER_KEY"
```

#### 代替方法: ローカルファイル方式

```bash
# シークレット設定スクリプトを実行
./scripts/setup-secrets.sh --method local

# Terraform実行（自動でファイルから読み込み）
terraform apply
```

### 3. 変数ファイルの設定

`terraform.tfvars.example`をコピーして`terraform.tfvars`を作成し、適切な値を設定します：

```bash
cp terraform.tfvars.example terraform/terraform.tfvars
```

特に以下の値を変更してください：
- `domain_name`: 実際のドメイン名

**注意**: シークレットは上記の方法で管理してください。

### 4. インフラのデプロイ

```bash
# Terraformの初期化
terraform init

# プランの確認
terraform plan

# インフラの作成
terraform apply
```

## デプロイ手順

### 1. コンテナイメージのビルドとプッシュ

#### フロントエンド

```bash
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_frontend_repository_url)

# イメージをビルド
cd frontend
docker build -t $(terraform output -raw ecr_frontend_repository_url):latest .

# イメージをプッシュ
docker push $(terraform output -raw ecr_frontend_repository_url):latest
```

#### バックエンド

```bash
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_backend_repository_url)

# イメージをビルド
cd backend
docker build -t $(terraform output -raw ecr_backend_repository_url):latest .

# イメージをプッシュ
docker push $(terraform output -raw ecr_backend_repository_url):latest
```

### 2. ECSサービスの更新

```bash
# フロントエンドサービスの更新
aws ecs update-service --cluster $(terraform output -raw ecs_cluster_name) --service todo-app-frontend --force-new-deployment

# バックエンドサービスの更新
aws ecs update-service --cluster $(terraform output -raw ecs_cluster_name) --service todo-app-backend --force-new-deployment
```

### 3. DNS設定

Terraformの出力から取得したnameserversを、ドメインのDNS設定に追加します：

```bash
terraform output route53_nameservers
```

## 出力値

デプロイ後、以下の重要な情報が出力されます：

- `alb_dns_name`: ALBのDNS名
- `cloudfront_domain_name`: CloudFrontディストリビューションのドメイン名
- `domain_name`: アプリケーションのドメイン名
- `ecr_frontend_repository_url`: フロントエンドECRリポジトリURL
- `ecr_backend_repository_url`: バックエンドECRリポジトリURL
- `rds_proxy_endpoint`: RDS Proxyエンドポイント
- `route53_nameservers`: Route 53ネームサーバー
- `cloudwatch_dashboard_url`: CloudWatchダッシュボードのURL

## セキュリティ

- WAFがALBに適用され、一般的な攻撃パターンをブロックします
- すべての通信はHTTPSで暗号化されます
- データベースパスワードとRails master keyはSecrets Managerで管理されます
- ECSタスクはプライベートサブネットで実行されます
- シークレットはAWS Parameter Storeで安全に管理されます

## 監視

- CloudWatch Logsでアプリケーションログを確認できます
- CloudWatch Container InsightsでECSクラスターのメトリクスを監視できます
- WAFメトリクスでセキュリティイベントを監視できます
- CloudWatchダッシュボードで統合された監視ビューを提供します
- 以下のアラームが設定されています：
  - ECS CPU使用率（80%以上）
  - ECS メモリ使用率（80%以上）
  - ALB 5xxエラー（10回以上）
  - Aurora CPU使用率（80%以上）
  - Aurora接続数（100以上）

## クリーンアップ

インフラを削除する場合：

```bash
terraform destroy
```

**注意**: このコマンドはすべてのリソースを削除します。データベースのデータも失われます。

## トラブルシューティング

### よくある問題

1. **ECSタスクが起動しない**
   - CloudWatch Logsでログを確認
   - セキュリティグループの設定を確認
   - 環境変数とシークレットの設定を確認

2. **データベース接続エラー**
   - RDS Proxyの設定を確認
   - セキュリティグループの設定を確認
   - Secrets Managerのシークレットを確認

3. **ALBのヘルスチェックが失敗**
   - アプリケーションのヘルスチェックエンドポイントを確認
   - ポート設定を確認
   - セキュリティグループの設定を確認

### ログの確認

```bash
# フロントエンドログ
aws logs tail /ecs/todo-app-frontend --follow

# バックエンドログ
aws logs tail /ecs/todo-app-backend --follow
```

### 監視ダッシュボード

CloudWatchダッシュボードにアクセスして、アプリケーションの全体的な状況を確認できます：

```bash
terraform output cloudwatch_dashboard_url
```

## シークレット管理のベストプラクティス

1. **絶対にGitHubにコミットしない**
   - `.gitignore`にシークレットファイルを追加
   - 環境変数や外部サービスを使用

2. **本番環境では強力なシークレットを使用**
   - 最低32文字のランダム文字列
   - 特殊文字を含む

3. **定期的なローテーション**
   - シークレットを定期的に更新
   - 古いシークレットを削除

4. **アクセス制御**
   - 必要最小限の権限のみ付与
   - アクセスログを監視

## シークレットの更新

シークレットを更新する場合：

```bash
# Parameter Storeのシークレットを更新
./scripts/setup-secrets.sh --method parameter-store --force

# ECSサービスを再デプロイ
aws ecs update-service --cluster $(terraform output -raw ecs_cluster_name) --service todo-app-backend --force-new-deployment
```
