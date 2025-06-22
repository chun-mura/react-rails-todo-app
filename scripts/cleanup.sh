#!/bin/bash

# Todo App AWS クリーンアップスクリプト

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

# 引数の解析
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
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

    # AWS認証情報
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS認証情報が設定されていません"
        exit 1
    fi

    log_info "前提条件チェック完了"
}

# ECRリポジトリのクリーンアップ
cleanup_ecr() {
    log_info "ECRリポジトリをクリーンアップしています..."

    cd "$TERRAFORM_DIR"

    # ECRリポジトリURLを取得
    FRONTEND_ECR_URL=$(terraform output -raw ecr_frontend_repository_url 2>/dev/null || echo "")
    BACKEND_ECR_URL=$(terraform output -raw ecr_backend_repository_url 2>/dev/null || echo "")

    if [ -n "$FRONTEND_ECR_URL" ]; then
        log_info "フロントエンドECRリポジトリのイメージを削除しています..."
        aws ecr batch-delete-image \
            --repository-name "$(basename "$FRONTEND_ECR_URL")" \
            --image-ids imageTag=latest 2>/dev/null || true
    fi

    if [ -n "$BACKEND_ECR_URL" ]; then
        log_info "バックエンドECRリポジトリのイメージを削除しています..."
        aws ecr batch-delete-image \
            --repository-name "$(basename "$BACKEND_ECR_URL")" \
            --image-ids imageTag=latest 2>/dev/null || true
    fi
}

# CloudWatch Logsのクリーンアップ
cleanup_cloudwatch_logs() {
    log_info "CloudWatch Logsをクリーンアップしています..."

    # ロググループを削除
    aws logs delete-log-group --log-group-name "/ecs/todo-app-frontend" 2>/dev/null || true
    aws logs delete-log-group --log-group-name "/ecs/todo-app-backend" 2>/dev/null || true
}

# Secrets Managerのクリーンアップ
cleanup_secrets() {
    log_info "Secrets Managerをクリーンアップしています..."

    # シークレットを削除
    aws secretsmanager delete-secret --secret-id "todo-app-db-password" --force-delete-without-recovery 2>/dev/null || true
    aws secretsmanager delete-secret --secret-id "todo-app-rails-master-key" --force-delete-without-recovery 2>/dev/null || true
}

# インフラの削除
destroy_infrastructure() {
    log_info "インフラを削除しています..."

    cd "$TERRAFORM_DIR"

    # Terraformの初期化
    log_info "Terraformを初期化しています..."
    terraform init

    # プランの確認
    log_info "削除対象を確認しています..."
    terraform plan -destroy

    # ユーザーに確認
    if [ "$FORCE" = false ]; then
        echo
        log_warn "この操作により、すべてのリソースとデータが削除されます。"
        log_warn "データベースのデータも失われます。"
        read -p "本当に削除しますか？ (yes/no): " -r
        echo
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_warn "削除をキャンセルしました"
            return
        fi
    fi

    # インフラの削除
    log_info "インフラを削除しています..."
    terraform destroy -auto-approve

    log_info "インフラ削除完了"
}

# メイン処理
main() {
    log_info "Todo App AWS クリーンアップを開始します..."

    check_prerequisites

    # 警告メッセージ
    if [ "$FORCE" = false ]; then
        log_warn "このスクリプトは以下のリソースを削除します："
        log_warn "- すべてのAWSリソース（VPC、ECS、RDS、ALB、CloudFront等）"
        log_warn "- データベースのデータ"
        log_warn "- ECRのコンテナイメージ"
        log_warn "- CloudWatch Logs"
        log_warn "- Secrets Managerのシークレット"
        echo
    fi

    # クリーンアップの実行
    cleanup_ecr
    cleanup_cloudwatch_logs
    cleanup_secrets
    destroy_infrastructure

    log_info "クリーンアップ完了！"
}

# スクリプトの実行
main "$@"
