# フルスタックWebアプリケーションハンズオン

このプロジェクトは、モダンなWebアプリケーション開発の完全なスタックを学ぶためのハンズオンです。

## 技術スタック

### フロントエンド
- **React.js** - ユーザーインターフェース
- **TypeScript** - 型安全性
- **Vite** - ビルドツール

### バックエンド
- **Ruby on Rails** - APIサーバー
- **PostgreSQL** - データベース
- **JWT** - 認証

### インフラストラクチャ
- **AWS EKS** - Kubernetesクラスター
- **AWS Fargate** - サーバーレスコンテナ実行環境
- **Nginx** - リバースプロキシ
- **Terraform** - インフラストラクチャ・アズ・コード

### CI/CD
- **GitHub Actions** - 継続的インテグレーション/デプロイメント
- **Docker** - コンテナ化

## アプリケーション概要

シンプルなタスク管理アプリケーション（Todo App）を構築します。

### 機能
- ユーザー認証（サインアップ/サインイン）
- タスクの作成、読み取り、更新、削除（CRUD）
- タスクの完了/未完了切り替え
- レスポンシブデザイン

## ハンズオン手順

### 1. ローカル開発環境のセットアップ
```bash
# フロントエンド
cd frontend
npm install
npm run dev

# バックエンド
cd backend
bundle install
rails db:create db:migrate
rails server
```

### 2. Docker化
```bash
# フロントエンド
cd frontend
docker build -t todo-frontend .

# バックエンド
cd backend
docker build -t todo-backend .
```

### 3. Kubernetesデプロイ
```bash
cd k8s
kubectl apply -f .
```

### 4. AWSインフラ構築
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. GitHub Actions設定
- `.github/workflows/` ディレクトリのワークフローファイルを確認
- リポジトリのSecrets設定

## ディレクトリ構造

```
.
├── frontend/                 # React.jsアプリケーション
├── backend/                  # Ruby on Rails API
├── k8s/                     # Kubernetesマニフェスト
├── terraform/               # Terraform設定
├── .github/workflows/       # GitHub Actions
└── docs/                    # ドキュメント
```

## 前提条件

- Docker
- kubectl
- AWS CLI
- Terraform
- Node.js (v18+)
- Ruby (v3.2+)
- PostgreSQL

## 注意事項

- 本ハンズオンは学習目的です
- 本番環境での使用前にセキュリティ設定を確認してください
- AWSリソースの料金にご注意ください

# Todo App

RailsバックエンドとReactフロントエンドで構築されたTodoアプリケーションです。

## 🚨 セキュリティに関する重要な注意事項

### 機密情報の管理
- **絶対にGitHubにアップロードしないでください**:
  - `terraform/terraform.tfvars`
  - `terraform/secrets/`ディレクトリ内のファイル
  - `.env*`ファイル
  - `backend/config/master.key`
  - 証明書ファイル（`.pem`, `.key`, `.crt`など）

### 環境変数の設定
本番環境では、以下の環境変数を必ず設定してください：
```bash
# データベース
DB_USERNAME=your_db_username
DB_PASSWORD=your_secure_password
DB_HOST=your_db_host
DB_PORT=5432

# JWT認証
JWT_SECRET_KEY=your_secure_jwt_secret

# Rails
RAILS_MASTER_KEY=your_rails_master_key
RAILS_ENV=production
```

### 推奨されるシークレット管理方法
1. **AWS Systems Manager Parameter Store**（推奨）
2. **環境変数**
3. **ローカルファイル**（開発環境のみ）

詳細は[terraform/README.md](terraform/README.md)を参照してください。

## アーキテクチャ

- **フロントエンド**: React + TypeScript + Vite
- **バックエンド**: Ruby on Rails API
- **データベース**: PostgreSQL
- **認証**: JWT

## ローカル開発

### 前提条件

- Docker
- Docker Compose

### 起動方法

```bash
# アプリケーションを起動
docker-compose up -d

# データベースのマイグレーション
docker-compose exec backend rails db:migrate

# データベースのシード
docker-compose exec backend rails db:seed
```

### アクセス

- フロントエンド: http://localhost:3000
- バックエンドAPI: http://localhost:3001

### データベース接続

PostgreSQLデータベースに接続する方法：

#### コンテナ内から接続
```bash
# PostgreSQLコンテナ内でpsqlを実行
docker exec -it todo-postgres psql -U postgres -d todo_app_development
```

#### ホストマシンから接続
```bash
# psqlがインストールされている場合
psql -h localhost -p 5432 -U postgres -d todo_app_development
```

#### 接続情報
- **ホスト**: localhost
- **ポート**: 5432
- **ユーザー名**: postgres
- **パスワード**: password（デフォルト）
- **データベース名**: todo_app_development

**注意**: ポート5433ではなく、5432を使用してください。

## AWSデプロイ

このプロジェクトはAWSにデプロイするためのTerraform設定が含まれています。

### 使用するAWSサービス

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

### デプロイ手順

詳細なデプロイ手順は [terraform/README.md](terraform/README.md) を参照してください。

#### 簡単なデプロイ（推奨）

```bash
# 完全自動デプロイ（シークレット設定からインフラ構築まで）
./scripts/deploy.sh
```

#### 手動デプロイ

```bash
# 1. シークレット設定（Parameter Store方式）
./scripts/setup-secrets.sh --method parameter-store --force

# 2. インフラデプロイ
cd terraform
terraform init
terraform apply

# 3. コンテナイメージのビルドとプッシュ
# （デプロイスクリプトに含まれています）
```

#### クリーンアップ

```bash
# インフラを削除
./scripts/cleanup.sh
```

## プロジェクト構造

```
project/
├── backend/                 # Rails API
├── frontend/               # React アプリケーション
├── terraform/              # AWS インフラ設定
├── scripts/                # デプロイスクリプト
├── docker-compose.yml      # ローカル開発用
└── README.md
```

## 開発

### フロントエンド

```bash
cd frontend
npm install
npm run dev
```

### バックエンド

```bash
cd backend
bundle install
rails server
```

## ライセンス

MIT
