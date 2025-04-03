#!/bin/bash
set -e

echo "======================================================="
echo "  Docker環境によるRails+React+MySQL開発環境初期化スクリプト"
echo "======================================================="

# ディレクトリ構造の作成
mkdir -p docker/backend docker/frontend docker/db

# 環境変数ファイルの作成（既に存在する場合はスキップ）
if [ ! -f .env ]; then
  cat > .env << EOL
# データベース設定
MYSQL_ROOT_PASSWORD=password
MYSQL_DATABASE=app_development
MYSQL_USER=app_user
MYSQL_PASSWORD=app_password

# Railsアプリケーション設定
RAILS_ENV=development
DATABASE_URL=mysql2://app_user:app_password@db/app_development

# その他設定
TZ=Asia/Tokyo
EOL
  echo "環境変数ファイル(.env)を作成しました"
else
  echo "環境変数ファイル(.env)は既に存在します"
fi

# MySQLの設定ファイルを作成
cat > docker/db/my.cnf << EOL
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone='+9:00'

[client]
default-character-set=utf8mb4
EOL
echo "MySQLの設定ファイルを作成しました"

# バックエンド初期化スクリプトを作成
cat > init-backend.sh << 'EOL'
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
    apt-get install -y build-essential libpq-dev nodejs npm default-libmysqlclient-dev && \
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
EOL

chmod +x init-backend.sh

# フロントエンド初期化スクリプトを作成
cat > init-frontend.sh << 'EOL'
#!/bin/bash
set -e

echo "React（フロントエンド）環境の初期化を開始します..."

# frontendディレクトリがなければ作成
mkdir -p frontend

# 一時的なNodeコンテナを実行してReactプロジェクトを初期化
docker run --rm -it \
  -v $(pwd)/frontend:/app \
  -w /app \
  node:23.9.0 bash -c "
    # 現在のディレクトリに新しいVite+Reactプロジェクトを作成
    npm create vite@latest . -- --template react
    
    # 依存関係をインストール
    npm install
    
    # 追加の必要な依存関係をインストール
    npm install @vitejs/plugin-react --save-dev axios react-router-dom @tanstack/react-query
    
    # 適切なファイル権限を設定
    chmod -R 777 .
  "

# vite.config.jsを修正
cat > frontend/vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 3000,
    watch: {
      usePolling: true
    }
  }
})
EOF

# フロントエンドのDockerfileを作成
cat > docker/frontend/Dockerfile << 'EOF'
# ベースステージ
FROM node:23.9.0 AS base
WORKDIR /app

# 開発ステージ
FROM base AS development
ENV NODE_ENV=development
# ソースコードはボリュームとしてマウントするので、ここではコピー不要
# エントリーポイントはdocker-composeのcommandで提供

# ビルドステージ
FROM base AS builder
COPY frontend/package*.json ./
RUN npm install
COPY frontend .
RUN npm run build

# 本番ステージ
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html

# Nginx設定ファイルをコピー
COPY docker/frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Nginx設定ファイルを作成
cat > docker/frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    # APIリクエストをバックエンドに転送
    location /api/ {
        proxy_pass http://backend:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "Reactアプリケーションの初期化が完了しました！"
EOL

chmod +x init-frontend.sh

# Docker Compose開発環境設定ファイルを作成
cat > docker-compose.yml << 'EOL'
services:
  db:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/db/my.cnf:/etc/mysql/conf.d/my.cnf
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: docker/backend/Dockerfile
      target: development
    volumes:
      - ./backend:/app
      - backend_bundle:/usr/local/bundle
      - backend_tmp:/app/tmp
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "3000:3000"
    environment:
      RAILS_ENV: ${RAILS_ENV}
      DATABASE_URL: ${DATABASE_URL}
      TZ: ${TZ}
    command: bash -c "bundle install && rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"

  frontend:
    build:
      context: .
      dockerfile: docker/frontend/Dockerfile
      target: development
    volumes:
      - ./frontend:/app
      - frontend_node_modules:/app/node_modules
    ports:
      - "8000:3000"
    depends_on:
      - backend
    environment:
      NODE_ENV: development
      VITE_API_URL: http://localhost:3000/api
    command: bash -c "npm install && npm run dev"

volumes:
  mysql_data:
  backend_bundle:
  frontend_node_modules:
  backend_tmp:
EOL

# Docker Compose本番環境設定ファイルを作成
cat > docker-compose.prod.yml << 'EOL'
services:
  db:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/db/my.cnf:/etc/mysql/conf.d/my.cnf
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: docker/backend/Dockerfile
      target: production
    depends_on:
      db:
        condition: service_healthy
    environment:
      RAILS_ENV: production
      DATABASE_URL: ${DATABASE_URL}
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      TZ: ${TZ}
    restart: always

  frontend:
    build:
      context: .
      dockerfile: docker/frontend/Dockerfile
      target: production
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: always

volumes:
  mysql_data:
EOL

echo "プロジェクト初期化ファイルが作成されました！"
echo ""
echo "次のコマンドを実行してRailsアプリケーションを初期化してください："
echo "./init-backend.sh"
echo ""
echo "次のコマンドを実行してReactアプリケーションを初期化してください："
echo "./init-frontend.sh"
echo ""
echo "その後、開発環境を起動するには："
echo "docker-compose up"