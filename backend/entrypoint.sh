#!/bin/sh
set -e

# データベースの準備
echo "データベースの準備を開始..."
bundle exec rake db:create
bundle exec rake db:migrate

# サンプルデータの作成
echo "サンプルデータを作成中..."
bundle exec rake db:seed

# サーバーを起動
echo "Railsサーバーを起動..."
exec bundle exec rails server -b 0.0.0.0 -p 3001
