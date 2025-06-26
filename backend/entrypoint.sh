#!/bin/sh
set -e

echo "Starting Rails application..."

# データベース接続を待機
max_attempts=60
attempt=1

# パスワード認証のための環境変数を設定（スクリプト終了時にクリア）
export PGPASSWORD="$DB_PASSWORD"
trap 'unset PGPASSWORD' EXIT

echo "Waiting for database connection..."

while [ $attempt -le $max_attempts ]; do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_NAME" 2>/dev/null; then
    echo "Database connection established successfully"
    break
  else
    echo "Attempt $attempt/$max_attempts: Database not ready, waiting..."
    sleep 5
    attempt=$((attempt + 1))
  fi
done

if [ $attempt -gt $max_attempts ]; then
  echo "ERROR: データベース接続の待機がタイムアウトしました"
  echo "DB_HOST: $DB_HOST"
  echo "DB_PORT: $DB_PORT"
  echo "DB_USERNAME: $DB_USERNAME"
  echo "DB_NAME: $DB_NAME"
  exit 1
fi

echo "Preparing database..."

# データベースの準備
bundle exec rake db:create RAILS_ENV=${RAILS_ENV:-development} || echo "Database creation skipped (may already exist)"
bundle exec rake db:migrate RAILS_ENV=${RAILS_ENV:-development} || echo "Database migration failed"
bundle exec rake db:seed RAILS_ENV=${RAILS_ENV:-development} || echo "Database seeding skipped"

echo "Starting Rails server..."

# サーバーを起動
exec bundle exec rails server -b 0.0.0.0 -p 3001
