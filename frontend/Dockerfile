# ビルドステージ
FROM node:18-alpine as build

WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係をインストール（開発用も含む）
RUN npm ci

# ソースコードをコピー
COPY . .

# アプリケーションをビルド
RUN npm run build

# 本番ステージ
FROM nginx:alpine

# ビルドされたアプリケーションをNginxにコピー
COPY --from=build /app/dist /usr/share/nginx/html

# Nginx設定をコピー
COPY nginx.conf /etc/nginx/nginx.conf

# ポート80を公開
EXPOSE 80

# Nginxを起動
CMD ["nginx", "-g", "daemon off;"]
