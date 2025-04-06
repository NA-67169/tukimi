#!/bin/bash
set -e

echo "Rails（バックエンド）環境の初期化を開始します..."

# backendディレクトリがなければ作成
mkdir -p backend

# Railsアプリケーション初期化用のDockerfileを作成
cat > docker/backend/init.Dockerfile << 'EOF'
FROM ruby:3.4.2

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm && \
    npm install -g yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gem install rails -v 7.2.2.1
EOF

# バックエンドの初期化用docker-composeファイルを作成
cat > docker-compose.init-backend.yml << 'EOF'
version: '3.8'

services:
  backend-init:
    build:
      context: .
      dockerfile: docker/backend/init.Dockerfile
    volumes:
      - ./backend:/app
    command: bash -c "rails new . --force --api --database=mysql --skip-git && chmod -R 777 ."
EOF

# Railsプロジェクトを初期化
docker compose -f docker-compose.init-backend.yml run --rm backend-init

echo "Railsアプリケーションの環境変数設定ファイルを更新しています..."
cat > backend/config/database.yml << 'EOF'
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("MYSQL_USER", "app_user") %>
  password: <%= ENV.fetch("MYSQL_PASSWORD", "app_password") %>
  host: <%= ENV.fetch("MYSQL_HOST", "db") %>

development:
  <<: *default
  database: <%= ENV.fetch("MYSQL_DATABASE", "app_development") %>

test:
  <<: *default
  database: app_test

production:
  <<: *default
  database: app_production
  username: <%= ENV.fetch("MYSQL_USER", "app_user") %>
  password: <%= ENV.fetch("MYSQL_PASSWORD", "app_password") %>
EOF

# Railsアプリケーションのエントリーポイントスクリプトを作成
cat > docker/backend/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
EOF

chmod +x docker/backend/entrypoint.sh

# 本番用DockerfileとDockerfileを作成
cat > docker/backend/Dockerfile << 'EOF'
# ベースステージ
FROM ruby:3.4.2-slim AS base

WORKDIR /app

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm default-libmysqlclient-dev libyaml-dev && \
    npm install -g yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# エントリーポイントスクリプトを設定
COPY docker/backend/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# 開発ステージ
FROM base AS development

ENV RAILS_ENV=development
ENV BUNDLE_WITHOUT="production"

# ビルドステージ
FROM base AS builder

WORKDIR /app

# Gemfileをコピーして依存関係をインストール
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install --jobs=4

# アプリケーションコードをコピー
COPY backend .

# 本番向けの設定
ENV RAILS_ENV=production
RUN bundle exec rake assets:precompile

# 本番ステージ
FROM base AS production

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# ビルドステージからGemと最適化されたアセットをコピー
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# サーバー起動
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
EOF

echo "Railsアプリケーションの初期化が完了しました！"
