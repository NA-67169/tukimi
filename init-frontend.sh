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
    
    # 追加の必要な依存関係をインストール（@tanstack/react-queryを使用）
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
