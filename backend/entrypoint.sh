#!/bin/sh
set -e

# 環境変数の確認
echo "RAILS_ENV: $RAILS_ENV"
echo "DB_HOST: $DB_HOST"
echo "DB_USERNAME: $DB_USERNAME"
echo "DB_PORT: $DB_PORT"

# データベースの準備
echo "データベースの準備を開始..."
bundle exec rake db:create RAILS_ENV=${RAILS_ENV:-development}
bundle exec rake db:migrate RAILS_ENV=${RAILS_ENV:-development}

# サンプルデータの作成
echo "サンプルデータを作成中..."
bundle exec rake db:seed RAILS_ENV=${RAILS_ENV:-development}

# サーバーを起動
echo "Railsサーバーを起動..."
exec bundle exec rails server -b 0.0.0.0 -p 3001
