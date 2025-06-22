#!/bin/bash

# Todo App シークレット設定スクリプト

set -e

# AWS CLIのページャーを無効化
export AWS_PAGER=""

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
SECRETS_DIR="$TERRAFORM_DIR/secrets"

# 引数の解析
METHOD="local"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --method)
            METHOD="$2"
            shift 2
            ;;
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

    # OpenSSL
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSLがインストールされていません"
        exit 1
    fi

    # AWS認証情報
    if ! aws sts get-caller-identity --no-cli-pager &> /dev/null; then
        log_error "AWS認証情報が設定されていません"
        exit 1
    fi

    log_info "前提条件チェック完了"
}

# JWT Secret Keyの生成
generate_jwt_secret() {
    openssl rand -hex 32
}

# Rails Master Keyの取得
get_rails_master_key() {
    if [ -f "$PROJECT_ROOT/backend/config/master.key" ]; then
        cat "$PROJECT_ROOT/backend/config/master.key"
    else
        log_error "Rails Master Keyファイルが見つかりません: $PROJECT_ROOT/backend/config/master.key"
        exit 1
    fi
}

# ローカルファイル方式でのシークレット設定
setup_local_secrets() {
    log_info "ローカルファイル方式でシークレットを設定しています..."

    # secretsディレクトリの作成
    mkdir -p "$SECRETS_DIR"

    # JWT Secret Key
    if [ "$FORCE" = true ] || [ ! -f "$SECRETS_DIR/jwt_secret_key.txt" ]; then
        generate_jwt_secret > "$SECRETS_DIR/jwt_secret_key.txt"
        log_info "JWT Secret Keyを保存しました: $SECRETS_DIR/jwt_secret_key.txt"
    else
        log_warn "JWT Secret Keyファイルが既に存在します。--forceオプションで上書きできます。"
    fi

    # Rails Master Key
    if [ "$FORCE" = true ] || [ ! -f "$SECRETS_DIR/rails_master_key.txt" ]; then
        get_rails_master_key > "$SECRETS_DIR/rails_master_key.txt"
        log_info "Rails Master Keyを保存しました: $SECRETS_DIR/rails_master_key.txt"
    else
        log_warn "Rails Master Keyファイルが既に存在します。--forceオプションで上書きできます。"
    fi

    # ファイルの権限を制限
    chmod 600 "$SECRETS_DIR"/*.txt

    log_info "ローカルファイル方式の設定完了"
}

# 環境変数方式でのシークレット設定
setup_env_secrets() {
    log_info "環境変数方式でシークレットを設定しています..."

    # JWT Secret Key
    JWT_SECRET_KEY=$(generate_jwt_secret)
    export JWT_SECRET_KEY
    log_info "JWT_SECRET_KEY環境変数を設定しました"

    # Rails Master Key
    RAILS_MASTER_KEY=$(get_rails_master_key)
    export RAILS_MASTER_KEY
    log_info "RAILS_MASTER_KEY環境変数を設定しました"

    # .envファイルに保存（オプション）
    if [ "$FORCE" = true ] || [ ! -f "$PROJECT_ROOT/.env" ]; then
        cat > "$PROJECT_ROOT/.env" << EOF
# シークレット設定
JWT_SECRET_KEY=$JWT_SECRET_KEY
RAILS_MASTER_KEY=$RAILS_MASTER_KEY

# 使用方法:
# source .env
# terraform apply -var="jwt_secret_key=\$JWT_SECRET_KEY" -var="rails_master_key=\$RAILS_MASTER_KEY"
EOF
        log_info ".envファイルを作成しました: $PROJECT_ROOT/.env"
    fi

    log_info "環境変数方式の設定完了"
}

# AWS Systems Manager Parameter Store方式でのシークレット設定
setup_parameter_store_secrets() {
    log_info "AWS Systems Manager Parameter Store方式でシークレットを設定しています..."

    PROJECT_NAME="todo-app"
    ENVIRONMENT="production"

    # JWT Secret Key
    log_info "JWT Secret Keyを生成しています..."
    JWT_SECRET=$(generate_jwt_secret)
    aws ssm put-parameter \
        --name "/$PROJECT_NAME/$ENVIRONMENT/jwt_secret_key" \
        --value "$JWT_SECRET" \
        --type "SecureString" \
        --region ap-northeast-1 \
        --overwrite \
        --no-cli-pager

    # Rails Master Key
    log_info "Rails Master Keyを取得しています..."
    RAILS_MASTER_KEY=$(get_rails_master_key)
    aws ssm put-parameter \
        --name "/$PROJECT_NAME/$ENVIRONMENT/rails_master_key" \
        --value "$RAILS_MASTER_KEY" \
        --type "SecureString" \
        --region ap-northeast-1 \
        --overwrite \
        --no-cli-pager

    log_info "Parameter Store方式の設定完了"
}

# メイン処理
main() {
    log_info "Todo App シークレット設定を開始します..."

    check_prerequisites

    case $METHOD in
        "local")
            setup_local_secrets
            ;;
        "env")
            setup_env_secrets
            ;;
        "parameter-store")
            setup_parameter_store_secrets
            ;;
        *)
            log_error "不明な方式: $METHOD"
            log_error "利用可能な方式: local, env, parameter-store"
            exit 1
            ;;
    esac

    log_info "シークレット設定完了！"

    # 使用方法の表示
    case $METHOD in
        "local")
            log_info "使用方法:"
            log_info "terraform apply"
            ;;
        "env")
            log_info "使用方法:"
            log_info "source .env"
            log_info "terraform apply -var=\"jwt_secret_key=\$JWT_SECRET_KEY\" -var=\"rails_master_key=\$RAILS_MASTER_KEY\""
            ;;
        "parameter-store")
            log_info "使用方法:"
            log_info "terraform apply"
            ;;
    esac
}

# スクリプトの実行
main "$@"
