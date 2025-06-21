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
