# DevContainer 設定

このプロジェクトではVS Code DevContainersを使用して開発環境を統一しています。

## 使用方法

1. VS Codeと[Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)をインストールしてください。
2. プロジェクトをVS Codeで開き、左下の緑色のボタンをクリックして「Open in Container」を選択します。

## 設定の概要

- `.devcontainer/` - メインプロジェクト用DevContainer設定
- `.devcontainer/backend/` - Railsバックエンド用DevContainer設定
- `.devcontainer/frontend/` - React/Viteフロントエンド用DevContainer設定

## 個別の開発環境を使用する場合

バックエンドまたはフロントエンドのみで作業する場合は、各ディレクトリをVS Codeで開き、DevContainerで起動してください。