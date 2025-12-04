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

### Phase 1: 案件管理・配送シート
- staff（スタッフ）
- companies（導入企業）
- restaurants（飲食店）
- menus（メニュー）
- delivery_companies（配送会社）
- drivers（ドライバー）
- orders（案件）
- recurring_orders（定期注文）
- delivery_sheet_items（配送シート明細）

### Phase 2: 請求・支払い・在庫管理
- invoices（請求書）
- invoice_items（請求明細）
- payments（入金）
- supplies（備品）
- supply_stocks（拠点別在庫）
- supply_movements（入出庫履歴）

## MVP スコープ（Phase 1）

- マスタ管理（企業、飲食店、メニュー、配送会社）
- 案件管理
- 配送シート自動生成（Excel/PDF出力）
- 配送会社向け閲覧画面

## 開発履歴

### Phase 2 Week 5-6 Day 25-26（2025-12-04）
**在庫補充アラート機能実装**
- LowStockCheckerサービス作成
  - check_low_stock: 在庫不足（発注点以下）を検出
  - check_out_of_stock: 在庫切れを検出
  - send_low_stock_alerts/send_out_of_stock_alerts: アラートメール送信
- SupplyMailer作成
  - low_stock_alert: 在庫不足通知メール
  - out_of_stock_alert: 在庫切れ通知メール（緊急）
  - HTML/テキスト両形式のメールテンプレート
- supplies.rakeタスク作成
  - supplies:check_stock: 在庫チェックと自動メール送信
  - supplies:list: 在庫状況一覧表示
  - supplies:low_stock: 在庫不足・在庫切れ一覧表示

### Phase 2 Week 3-4 Day 17-18（2025-12-04）
**支払状況レポート機能実装**
- ReportGeneratorService作成
  - 月次支払状況レポート生成
  - 支払ステータス別・企業別集計
  - Chart.js用グラフデータ生成
- Admin::ReportsController作成
  - レポート表示画面
  - PDF/CSVエクスポート機能
- ReportPdfGenerator作成
  - Prawnを使用したPDFレポート生成
  - 日本語フォント対応（Noto Sans JP）
- レポート画面作成
  - Chart.js CDNによるグラフ表示（円グラフ・棒グラフ）
  - 期間選択機能、PDF/CSVダウンロードボタン

### Phase 2 Week 3-4 Day 15-16（2025-12-04）
**未払い請求書アラート機能実装**
- UnpaidInvoiceCheckerサービス作成
  - 期限超過請求書の検出機能
  - 支払期限が近い請求書のリマインダー機能
- InvoiceMailer作成
  - overdue_notice: 期限超過通知メール
  - payment_reminder: 支払リマインダーメール
  - HTML/テキスト両形式のメールテンプレート
- invoices:check_overdue rakeタスク追加
  - 期限超過チェックと自動メール送信

### Phase 2 Week 3-4 Day 13-14（2025-12-04）
**入金管理画面実装**
- PaymentDashboard、Admin::PaymentsController作成
- 入金一覧・登録・編集・削除機能
- Administrateデフォルト機能を使用

### Phase 2 Week 3-4 Day 11-12（2025-12-04）
**Paymentモデル実装**
- Paymentモデル作成（invoice_id, payment_date, amount, payment_method, reference_number）
- バリデーション追加（金額が残高を超えないチェック）
- コールバック追加（after_create/after_destroy: update_invoice_payment_status）
- Invoice#update_payment_status実装（paid/partial/unpaid/overdue自動更新）

### Phase 2 Week 1-2 Day 7-10（2025-12-03）
**請求書PDF出力・管理画面実装**
- InvoicePdfGenerator作成（Prawn使用、A4縦向き、日本語フォント対応）
- InvoiceDashboard、Admin::InvoicesController作成
- 請求書一覧・詳細・PDF出力機能
- Administrateデフォルト機能を使用

### Phase 2 Week 1-2 Day 5-6（2025-12-03）
**請求書自動生成機能実装**
- InvoiceGenerator作成（月次請求書自動生成）
- invoices:generate_monthly rakeタスク作成
- GenerateInvoicesJob作成（バックグラウンドジョブ）
- 企業別・月別集計、消費税計算、割引適用

### Phase 2 Week 1-2 Day 1-4（2025-12-03）
**Invoice/InvoiceItemモデル実装**
- Invoice/InvoiceItemモデル作成
- アソシエーション・バリデーション・コールバック追加
- 請求書番号自動生成（INV-YYYYMM-XXXX）
- 金額計算ロジック（小計・消費税・合計）
- ステータス管理（draft/sent/paid/cancelled、unpaid/partial/paid/overdue）

### Phase 1 Week 4 Day 26-28（2025-12-03）
**実運用テスト準備・ドキュメント整備**
- 操作マニュアル作成（docs/user_manual.md）
  - ログイン方法
  - 定期スケジュール管理
  - 案件管理
  - カレンダー表示
  - スケジュール調整
  - 配送シート出力
  - マスタデータ管理
  - トラブルシューティング
- データ移行手順書作成（docs/data_migration_guide.md）
  - 移行概要・スケジュール
  - 事前準備（バックアップ手順）
  - 移行手順（マスタデータ→案件→定期スケジュール）
  - データ検証手順
  - トラブルシューティング
  - 移行完了チェックリスト
- ロールバック手順書作成（docs/rollback_guide.md）
  - ロールバック判断基準（重大度別）
  - 部分ロールバック手順
  - 完全ロールバック手順（Phase 1-4）
  - ロールバック後の対応
  - 緊急連絡先・チェックリスト

### Phase 1 Week 4 Day 24-25（2025-12-03）
**統合テスト・パフォーマンステスト**
- Gemfile更新
  - capybara: E2Eテスト用
  - selenium-webdriver: ブラウザテスト用
  - bullet: N+1クエリ検出用
- Bullet設定追加（config/initializers/bullet.rb）
  - 開発環境でN+1クエリを自動検出
- RSpec/Capybara設定
  - rails_helper.rbにCapybara設定追加
  - Deviseヘルパー追加
- E2Eテスト作成（spec/features/）
  - recurring_orders_spec.rb: 定期スケジュール登録・編集・削除・自動生成
  - calendar_spec.rb: カレンダー表示・フィルタリング・表示切替・メニュー重複警告
  - delivery_sheets_spec.rb: 配送シート一覧・フィルタリング・PDF出力・グループ化
  - schedule_adjustment_spec.rb: スケジュール調整・一括更新・コンフリクト表示・フィルタリング
- パフォーマンステスト作成（spec/performance/orders_performance_spec.rb）
  - カレンダー表示のクエリ数チェック
  - 配送シート一覧のクエリ数チェック
  - スケジュール調整画面のクエリ数チェック
  - PDF生成速度テスト（3秒以内）
  - ConflictDetector性能テスト
  - カスタムマッチャー（perform_under）実装

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
