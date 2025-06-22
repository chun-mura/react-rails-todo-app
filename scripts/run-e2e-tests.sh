#!/bin/bash

# E2Eテスト実行スクリプト

set -e

echo "🚀 E2Eテストを開始します..."

# 既存のテスト結果をクリーンアップ
echo "🧹 既存のテスト結果をクリーンアップ..."
rm -rf test-results playwright-report

# 既存のテストコンテナをクリーンアップ
echo "🧹 既存のテストコンテナをクリーンアップ..."
docker-compose -f docker-compose.test.yml down -v --remove-orphans

# テスト用のコンテナをビルドして起動
echo "🔨 テスト用コンテナをビルドして起動..."
docker-compose -f docker-compose.test.yml up --build -d

# フロントエンドのヘルスチェックを待つ
echo "⏳ フロントエンドの起動を待機中..."
docker-compose -f docker-compose.test.yml logs -f frontend-test &
LOGS_PID=$!

# ヘルスチェックが成功するまで待機
timeout=300  # 5分のタイムアウト
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f docker-compose.test.yml ps frontend-test | grep -q "healthy"; then
        echo "✅ フロントエンドが正常に起動しました！"
        break
    fi
    sleep 10
    elapsed=$((elapsed + 10))
    echo "⏳ フロントエンドの起動を待機中... ($elapsed/$timeout 秒)"
done

# ログプロセスを停止
kill $LOGS_PID 2>/dev/null || true

if [ $elapsed -ge $timeout ]; then
    echo "❌ フロントエンドの起動がタイムアウトしました"
    docker-compose -f docker-compose.test.yml logs frontend-test
    exit 1
fi

# 追加の待機時間
echo "⏳ 追加の待機時間..."
sleep 10

# Playwrightテストを実行
echo "🧪 Playwrightテストを実行..."
docker-compose -f docker-compose.test.yml run --rm playwright-test

# テスト結果を確認
echo "📊 テスト結果を確認..."
if [ $? -eq 0 ]; then
    echo "✅ すべてのテストが成功しました！"
else
    echo "❌ テストが失敗しました。"
    exit 1
fi

# テストコンテナを停止
echo "🛑 テストコンテナを停止..."
docker-compose -f docker-compose.test.yml down --remove-orphans

echo "🎉 E2Eテストが完了しました！"
