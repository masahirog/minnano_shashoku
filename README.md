# みんなの社食 オペレーション管理システム

「みんなの社食」のオペレーション業務を一元管理するWebアプリケーション

## 概要

現在スプレッドシートで分散管理されている案件管理、配送スケジュール、請求書作成、在庫管理を統合し、手作業を大幅に削減するシステムです。

## 技術スタック

- Ruby 3.1.4
- Rails 7.1
- PostgreSQL 15
- Redis 7
- Docker / Docker Compose
- ActiveAdmin（管理画面）
- Sidekiq（バックグラウンド処理）
- Prawn（PDF生成）
- Caxlsx（Excel生成）

## セットアップ

### 必要な環境

- Docker
- Docker Compose

### 初回セットアップ

1. リポジトリをクローン
```bash
git clone <repository-url>
cd minnano_shashoku
```

2. Docker コンテナをビルド・起動
```bash
docker-compose up -d
```

3. データベースを作成・マイグレーション
```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
```

4. 初期データを投入（オプション）
```bash
docker-compose exec web rails db:seed
```

5. ブラウザでアクセス
```
http://localhost:3000
```

管理画面: http://localhost:3000/admin
- デフォルトログイン: admin@example.com / password

## ローカル開発

### サーバー起動
```bash
docker-compose up
```

### コンテナに入る
```bash
docker-compose exec web bash
```

### マイグレーション実行
```bash
docker-compose exec web rails db:migrate
```

### データインポート
```bash
docker-compose exec web rails import:all
```

## データベース構成

- staff（スタッフ）
- companies（導入企業）
- restaurants（飲食店）
- menus（メニュー）
- delivery_companies（配送会社）
- drivers（ドライバー）
- orders（案件）
- delivery_sheet_items（配送シート明細）

## MVP スコープ（Phase 1）

- マスタ管理（企業、飲食店、メニュー、配送会社）
- 案件管理
- 配送シート自動生成（Excel/PDF出力）
- 配送会社向け閲覧画面

## 本番環境

Heroku にデプロイ

```bash
# Heroku へのデプロイは指示があるまで実行しないこと
```

## ライセンス

Private
