#!/bin/bash

set -e

# 環境変数ファイルを読み込み（存在する場合）
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 設定
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
PROJECT_NAME="${PROJECT_NAME:-todo-app}"

# AWSアカウントIDが設定されているかチェック
if [ -z "$AWS_ACCOUNT_ID" ] || [ "$AWS_ACCOUNT_ID" = "your-aws-account-id" ]; then
    echo "エラー: AWS_ACCOUNT_IDが設定されていません。"
    echo ".envファイルを作成するか、環境変数を設定してください。"
    exit 1
fi

# ECRリポジトリのURL
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-frontend"
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}-backend"

echo "ECRにログイン中..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Buildxビルダーを作成（存在しない場合）
echo "Docker Buildxビルダーを設定中..."
docker buildx create --name multiarch-builder --use 2>/dev/null || docker buildx use multiarch-builder

# フロントエンドイメージをビルドしてプッシュ
echo "フロントエンドイメージをビルド中..."
cd frontend
docker buildx build --platform linux/amd64 \
  -t ${FRONTEND_REPO}:latest \
  --push .

echo "フロントエンドイメージをプッシュしました: ${FRONTEND_REPO}:latest"

# バックエンドイメージをビルドしてプッシュ
echo "バックエンドイメージをビルド中..."
cd ../backend
docker buildx build --platform linux/amd64 \
  -t ${BACKEND_REPO}:latest \
  --push .

echo "バックエンドイメージをプッシュしました: ${BACKEND_REPO}:latest"

echo "すべてのイメージのビルドとプッシュが完了しました！"
