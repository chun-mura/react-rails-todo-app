# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## テスト実行方法

### 前提条件
- Docker Composeが起動していること
- データベースが作成されていること

### テスト実行コマンド

#### 全テストの実行
```bash
docker-compose exec backend env RAILS_ENV=test bundle exec rspec
```

#### 特定のテストファイルの実行
```bash
# コントローラのテスト
docker-compose exec backend env RAILS_ENV=test bundle exec rspec spec/requests/

# モデルのテスト
docker-compose exec backend env RAILS_ENV=test bundle exec rspec spec/models/

# 特定のファイルのテスト
docker-compose exec backend env RAILS_ENV=test bundle exec rspec spec/requests/application_controller_spec.rb
```

#### テストの詳細表示
```bash
docker-compose exec backend env RAILS_ENV=test bundle exec rspec --format documentation
```

### 重要な注意点
- **必ず `RAILS_ENV=test` を指定してください**
- 指定しないとdevelopment環境でテストが実行され、403エラーが発生します
- テスト環境では認証やホスト制限などの設定が適切に無効化されます

### テストデータベースの準備
初回実行時やデータベースが存在しない場合：
```bash
docker-compose exec backend env RAILS_ENV=test bundle exec rails db:create
docker-compose exec backend env RAILS_ENV=test bundle exec rails db:migrate
```
