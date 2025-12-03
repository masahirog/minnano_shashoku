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
- AWS S3バケット（ファイルアップロード用）

### AWS S3バケットの作成

開発環境用と本番環境用に別々のバケットを作成してください：

1. AWS S3コンソールにアクセス
2. 以下のバケットを作成：
   - **開発環境**: `minnano-shashoku-development`
   - **本番環境**: `minnano-shashoku-production`
3. リージョン：`ap-northeast-1`（東京）
4. パブリックアクセスはすべてブロック（デフォルト）

### 初回セットアップ

1. リポジトリをクローン
```bash
git clone <repository-url>
cd minnano_shashoku
```

2. 環境変数の設定
```bash
cp .env.sample .env
```

`.env` ファイルを開いて、以下の値を設定してください：
```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=ap-northeast-1
AWS_BUCKET=minnano-shashoku-development
```

**注意：** .env ファイルは絶対にGitにコミットしないでください。認証情報が漏洩します。

3. Docker コンテナをビルド・起動
```bash
docker-compose up -d
```

4. データベースを作成・マイグレーション
```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
```

5. 初期データを投入（オプション）
```bash
docker-compose exec web rails db:seed
```

6. ブラウザでアクセス
```
http://localhost:3000
```

管理画面: http://localhost:3000/admin
- デフォルトログイン: admin@example.com / password

### 日本語フォント設定（PDF生成用）

配送シートPDF生成で日本語を正しく表示するには、日本語フォントファイルが必要です。

1. Google FontsからNoto Sans JPをダウンロード
```bash
# ダウンロードページ: https://fonts.google.com/noto/specimen/Noto+Sans+JP
# または直接ダウンロード
curl -L -o NotoSansJP.zip "https://fonts.google.com/download?family=Noto%20Sans%20JP"
unzip NotoSansJP.zip -d noto_sans_jp
```

2. フォントファイルを配置
```bash
mkdir -p app/assets/fonts
cp noto_sans_jp/static/NotoSansJP-Regular.ttf app/assets/fonts/
```

3. 確認
```bash
ls -la app/assets/fonts/NotoSansJP-Regular.ttf
```

**注意：** フォントファイルは容量が大きいため、Gitにコミットしないことを推奨します。`.gitignore` に `app/assets/fonts/*.ttf` が既に追加されています。

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

## 開発履歴

### Phase 1 Week 4 Day 22-23（2025-12-03）
**バリデーション・制約チェック強化**
- Orderモデルにカスタムバリデーション実装
  - restaurant_capacity_check: 飲食店の1日のキャパシティチェック
    - capacity_per_day（1日あたりの食数制限）
    - max_lots_per_day（1日あたりの案件数制限）
    - キャンセル済み案件は計算対象外
  - restaurant_not_closed: 定休日チェック
    - closed_days配列で曜日ベースの定休日チェック
    - エラーメッセージに日付と曜日を表示
  - delivery_time_feasible: 配送時間の妥当性チェック
    - 倉庫集荷時刻 < 飲食店回収時刻
    - 最低30分の余裕時間を確保
- ConflictDetectorサービス作成（app/services/conflict_detector.rb）
  - detect_for_order: 単一案件のコンフリクト検出
  - detect_for_date: 指定日のすべてのコンフリクト検出
  - detect_for_range: 指定期間のすべてのコンフリクト検出
  - 検出項目: キャパオーバー、メニュー重複、時間帯重複、定休日
  - 重大度レベル（high/medium）付き
- RSpecテスト作成
  - spec/models/order_spec.rb: バリデーションテスト
  - spec/services/conflict_detector_spec.rb: コンフリクト検出テスト

### Phase 1 Week 3 Day 21（2025-12-03）
**日本語フォント設定**
- config/initializers/prawn.rb作成
  - Prawnの警告メッセージを非表示に設定
- .gitignoreにフォントファイル除外設定追加
- README.mdにフォントダウンロード手順追加
  - Google FontsからNoto Sans JPをダウンロード
  - app/assets/fonts/に配置
- DeliverySheetPdfGeneratorは既にフォント対応済み
  - フォントファイルがある場合は自動的に適用
  - フォントファイルがない場合はデフォルトフォント使用

### Phase 1 Week 3 Day 19-20（2025-12-03）
**配送シートUI画面**
- 配送シート一覧画面を実装（/admin/orders/delivery_sheets）
- 折りたたみ可能なフィルターフォーム
  - 期間指定（開始日・終了日）
  - 企業、飲食店、配送会社でフィルタリング
- 日付ごとにグループ化されたプレビューテーブル表示
  - 回収時刻、倉庫集荷時刻
  - 企業名（カラーバッジ）、飲食店名、メニュー名
  - 食数、区分（試食会/本導入）
  - 返却先、器材メモ
  - メニュー重複警告アイコン
- PDF出力ボタン（ヘッダーとフッター2箇所）
- カレンダー・スケジュール調整画面からのナビゲーションリンク追加
- パンくずリストとナビゲーション完備

### Phase 1 Week 3 Day 15-16（2025-12-03）
**配送シートPDF生成機能**
- DeliverySheetPdfGeneratorサービスを実装
- Prawn gemで印刷可能なPDF生成
- A4横向きレイアウト、日付ごとにグループ化
- 配送フロー情報を含むテーブル形式
  - 回収時刻、倉庫集荷時刻
  - 企業名、飲食店名、メニュー名、食数
  - 区分（試食会/本導入）、返却先、器材メモ
- OrdersControllerにdelivery_sheet_pdfアクション追加
- 日付範囲・企業・飲食店・配送会社でフィルタリング可能
- キャンセル済み案件を自動除外
- PDFダウンロード機能
- 日本語フォント対応準備（app/assets/fonts/）

### Phase 1 Week 2 Day 13（2025-12-03）
**スケジュール調整画面とコンフリクト検出機能**
- スケジュール調整画面を実装（/admin/orders/schedule）
- テーブル形式での案件一覧表示（期間指定、フィルター機能）
- 各行で日付・時刻を直接編集可能
- チェックボックスで複数案件を選択して一括更新
- Orderモデルにコンフリクト検出メソッド実装
  - `schedule_conflicts`: 飲食店の時間帯重複、同じ企業の複数配送を検出
  - `has_conflicts?`: コンフリクトの有無を判定
- コンフリクトがある行を赤色でハイライト表示
- コンフリクト警告アイコンとツールチップ表示
- 全選択機能、選択行のハイライト表示

### Phase 1 Week 2 Day 12（2025-12-03）
**メニュー重複チェック機能**
- Orderモデルに `duplicate_menu_in_week?` メソッドを実装
- 同じ週（月曜〜日曜）に同じメニューが重複しているかチェック
- カレンダービューに警告アイコン表示（Font Awesome exclamation-triangle）
- ツールチップに重複警告メッセージを追加
- 警告アイコンのパルスアニメーション実装
- delivery_timeをcollection_timeに修正

### Phase 1 Week 2 Day 10-11（2025-12-03）
**カレンダーUI改善**
- Companyモデルにcolorカラムを追加（デフォルト: #2196f3）
- 既存企業データに8種類の異なる色を自動割当
- カレンダーイベントに企業カラーを適用
- Bootstrap tooltipでホバー時に詳細情報表示
- 企業、飲食店、ステータスでフィルタリング機能
- フィルター条件保持機能
- CompanyDashboardにcolor編集機能追加

### Phase 1 Week 2 Day 8-9
**カレンダービュー基本実装**
- 月間カレンダー・週間カレンダー表示
- simple_calendarの導入

### Phase 1 Day 7
**RecurringOrder管理画面実装**
- 定期注文の管理画面を実装

## 本番環境

### Heroku にデプロイ

```bash
# Heroku へのデプロイは指示があるまで実行しないこと
```

### 本番環境の環境変数設定

Heroku では以下の環境変数を設定してください：

```bash
heroku config:set AWS_ACCESS_KEY_ID=your_access_key_id
heroku config:set AWS_SECRET_ACCESS_KEY=your_secret_access_key
heroku config:set AWS_REGION=ap-northeast-1
heroku config:set AWS_BUCKET=minnano-shashoku-production
```

## ファイルアップロード

メニュー写真や配送シート写真は AWS S3 に保存されます。

- 開発環境・本番環境ともに S3 を使用
- S3バケット名：
  - 開発環境: `minnano-shashoku-development`
  - 本番環境: `minnano-shashoku-production`
- リージョン：`ap-northeast-1`（東京）

管理画面からメニューや配送シート明細を編集する際に、写真をアップロードできます。

**重要：** 環境ごとに異なるバケットを使用することで、開発環境と本番環境のファイルが混在しません。

## ライセンス

Private
