# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t backend .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name backend backend

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM ruby:3.2.2-alpine

# 必要なパッケージをインストール
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    postgresql-client \
    tzdata \
    nodejs \
    yarn

# 作業ディレクトリを設定
WORKDIR /app

# Gemfileをコピー
COPY Gemfile Gemfile.lock ./

# 依存関係をインストール
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート3001を公開
EXPOSE 3001

# 起動スクリプトをコピー
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
