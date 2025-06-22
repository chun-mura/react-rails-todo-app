# E2Eテスト

Dockerコンテナで実行するPlaywrightテストです。

## 前提条件

- Docker & Docker Compose
- バックエンドサーバーが起動していること

## 実行方法

### Docker環境での実行（推奨）

#### 自動実行スクリプトを使用
```bash
# プロジェクトルートから実行
./scripts/run-e2e-tests.sh
```

#### 手動でDocker Composeを使用
```bash
# テスト用コンテナを起動
docker-compose -f docker-compose.test.yml up --build -d

# Playwrightテストを実行
docker-compose -f docker-compose.test.yml run --rm playwright-test

# テスト完了後、コンテナを停止
docker-compose -f docker-compose.test.yml down
```

### ローカル環境での実行

#### 基本的なテスト実行
```bash
npm run test:e2e
```

#### UIモードでテスト実行
```bash
npm run test:e2e:ui
```

## テスト内容

- アプリケーションの基本動作確認
- ログインページの表示確認
- 登録ページの表示確認

## Docker環境の利点

1. **環境の一貫性**: 開発環境に関係なく同じ環境でテストが実行される
2. **Node.jsバージョン問題の解決**: 古いNode.jsバージョンでも問題なく実行
3. **ブラウザの自動インストール**: Playwrightブラウザが自動でインストールされる
4. **CI/CD対応**: 本番環境と同じ条件でテストが実行される

## 注意事項

- テスト実行前にバックエンドサーバーが起動していることを確認してください
- Docker環境では、テスト用の独立したデータベースとバックエンドが使用されます
- テスト結果は`playwright-report/`ディレクトリに保存されます
