#!/bin/bash

# Todo App AWS デプロイスクリプト

set -e

# 色付きの出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 設定
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"

# 引数の解析
SKIP_INFRA=false
SKIP_BUILD=false
SKIP_DEPLOY=false
SKIP_SECRETS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-infra)
            SKIP_INFRA=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-deploy)
            SKIP_DEPLOY=true
            shift
            ;;
        --skip-secrets)
            SKIP_SECRETS=true
            shift
            ;;
        *)
            log_error "不明なオプション: $1"
            exit 1
            ;;
    esac
done

# 前提条件のチェック
check_prerequisites() {
    log_info "前提条件をチェックしています..."

    # AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLIがインストールされていません"
        exit 1
    fi

    # Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraformがインストールされていません"
        exit 1
    fi

    # Docker
    if ! command -v docker &> /dev/null; then
        log_error "Dockerがインストールされていません"
        exit 1
    fi

    # AWS認証情報
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS認証情報が設定されていません"
        exit 1
    fi

    log_info "前提条件チェック完了"
}

# シークレットの設定
setup_secrets() {
    if [ "$SKIP_SECRETS" = true ]; then
        log_warn "シークレット設定をスキップします"
        return
    fi

    log_info "シークレットを設定しています..."

    # Parameter Store方式でシークレットを設定
    ./scripts/setup-secrets.sh --method parameter-store --force

    log_info "シークレット設定完了"
}

# インフラのデプロイ
deploy_infrastructure() {
    if [ "$SKIP_INFRA" = true ]; then
        log_warn "インフラデプロイをスキップします"
        return
    fi

    log_info "インフラをデプロイしています..."

    cd "$TERRAFORM_DIR"

    # Terraformの初期化
    log_info "Terraformを初期化しています..."
    terraform init

    # プランの確認
    log_info "Terraformプランを確認しています..."
    terraform plan

    # ユーザーに確認
    read -p "インフラをデプロイしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "インフラデプロイをキャンセルしました"
        return
    fi

    # インフラの作成
    log_info "インフラを作成しています..."
    terraform apply -auto-approve

    log_info "インフラデプロイ完了"
}

# ECRリポジトリURLの取得
get_ecr_urls() {
    cd "$TERRAFORM_DIR"
    FRONTEND_ECR_URL=$(terraform output -raw ecr_frontend_repository_url)
    BACKEND_ECR_URL=$(terraform output -raw ecr_backend_repository_url)
}

# コンテナイメージのビルドとプッシュ
build_and_push_images() {
    if [ "$SKIP_BUILD" = true ]; then
        log_warn "イメージビルドをスキップします"
        return
    fi

    log_info "コンテナイメージをビルドしてプッシュしています..."

    # ECRリポジトリURLを取得
    get_ecr_urls

    # ECRにログイン
    log_info "ECRにログインしています..."
    aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin "$FRONTEND_ECR_URL"
    aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin "$BACKEND_ECR_URL"

    # Buildxビルダーを作成（存在しない場合）
    log_info "Docker Buildxビルダーを設定中..."
    docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

    # フロントエンドのビルドとプッシュ
    log_info "フロントエンドイメージをビルドしています..."
    cd "$FRONTEND_DIR"
    docker buildx build --platform linux/amd64 \
        -t "$FRONTEND_ECR_URL:latest" \
        --push .

    # バックエンドのビルドとプッシュ
    log_info "バックエンドイメージをビルドしています..."
    cd "$BACKEND_DIR"
    docker buildx build --platform linux/amd64 \
        -t "$BACKEND_ECR_URL:latest" \
        --push .

    log_info "イメージビルドとプッシュ完了"
}

# ECSサービスの更新
deploy_services() {
    if [ "$SKIP_DEPLOY" = true ]; then
        log_warn "サービスデプロイをスキップします"
        return
    fi

    log_info "ECSサービスを更新しています..."

    cd "$TERRAFORM_DIR"
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)

    # フロントエンドサービスの更新
    log_info "フロントエンドサービスを更新しています..."
    aws ecs update-service \
        --cluster "$ECS_CLUSTER" \
        --service todo-app-frontend \
        --force-new-deployment

    # バックエンドサービスの更新
    log_info "バックエンドサービスを更新しています..."
    aws ecs update-service \
        --cluster "$ECS_CLUSTER" \
        --service todo-app-backend \
        --force-new-deployment

    log_info "サービスデプロイ完了"
}

# デプロイ状況の確認
check_deployment_status() {
    log_info "デプロイ状況を確認しています..."

    cd "$TERRAFORM_DIR"
    ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)

    # サービスの状況を確認
    log_info "フロントエンドサービスの状況:"
    aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services todo-app-frontend \
        --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount}' \
        --output table

    log_info "バックエンドサービスの状況:"
    aws ecs describe-services \
        --cluster "$ECS_CLUSTER" \
        --services todo-app-backend \
        --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount}' \
        --output table

    # 出力値の表示
    log_info "デプロイ情報:"
    terraform output
}

# メイン処理
main() {
    log_info "Todo App AWS デプロイを開始します..."

    check_prerequisites
    setup_secrets
    deploy_infrastructure
    build_and_push_images
    deploy_services
    check_deployment_status

    log_info "デプロイ完了！"
    log_info "アプリケーションにアクセスするには、DNS設定を更新してください。"
    log_info "Route 53 nameservers:"
    cd "$TERRAFORM_DIR"
    terraform output route53_nameservers
}

# スクリプトの実行
main "$@"
