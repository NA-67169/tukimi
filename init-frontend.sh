#!/bin/bash
set -e

# frontendディレクトリがなければ作成
mkdir -p frontend

# 一時的なNodeコンテナを実行してReactプロジェクトを初期化
docker run --rm -it \
  -v $(pwd)/frontend:/app \
  -w /app \
  node:18 bash -c "
    # 現在のディレクトリに新しいVite+Reactプロジェクトを作成
    npm create vite@latest . -- --template react
    
    # 依存関係をインストール
    npm install
    
    # 追加の必要な依存関係をインストール
    npm install @vitejs/plugin-react --save-dev axios react-router-dom react-query
    
    # 適切なファイル権限を設定
    chmod -R 777 .
  "

echo "Reactプロジェクトがfrontendディレクトリに正常に初期化されました！"