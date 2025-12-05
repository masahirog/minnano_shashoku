# Phase 3 実装計画書：配送会社向け機能＋モバイル対応

**バージョン:** 1.0
**作成日:** 2025-12-05
**対象期間:** 8週間（Week 1-8）

---

## 目次

1. [概要](#概要)
2. [要件定義](#要件定義)
3. [データベース設計](#データベース設計)
4. [画面設計](#画面設計)
5. [実装スケジュール](#実装スケジュール)
6. [技術仕様](#技術仕様)
7. [テスト計画](#テスト計画)

---

## 概要

### Phase 3の目的

配送会社が配送業務を効率的に管理できるモバイルアプリ機能を提供し、配送状況のリアルタイム把握と報告の自動化を実現する。

### Phase 3の範囲

**配送会社向け機能：**
- 配送会社用ログイン・認証
- 配送予定一覧表示（日別、週別）
- 配送ステータス管理（準備中→配送中→完了）
- 配送報告機能（写真、メモ、時刻記録）
- 配送履歴・実績確認
- 配送ルート最適化提案

**モバイル対応：**
- レスポンシブデザイン（スマホ・タブレット対応）
- PWA対応（ホーム画面追加、オフライン動作）
- モバイルカメラアクセス（配送報告用写真撮影）
- プッシュ通知（新規配送依頼、配送完了通知）
- 位置情報取得（配送ルート記録）
- オフラインモード（ネットワーク切断時の動作継続）

### ゴール

- 配送会社が配送業務をモバイルで完結できる
- 管理画面で配送状況をリアルタイム確認できる
- 配送完了報告の自動化により事務作業を削減
- 配送遅延や問題を早期発見できる

---

## 要件定義

### 機能要件

#### 1. 配送会社用認証

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-01 | 配送会社アカウント作成 | 管理者が配送会社アカウントを作成 | 高 |
| F3-02 | 配送担当者ログイン | メールアドレス・パスワードでログイン | 高 |
| F3-03 | パスワードリセット | パスワード忘れた場合のリセット機能 | 中 |
| F3-04 | 権限管理 | 配送会社管理者・配送担当者の権限分離 | 中 |

#### 2. 配送予定管理

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-10 | 配送予定一覧表示 | 日別・週別の配送予定を表示 | 高 |
| F3-11 | 配送詳細表示 | 配送先、商品、時刻、特記事項を表示 | 高 |
| F3-12 | 配送ステータス更新 | 準備中→配送中→完了のステータス更新 | 高 |
| F3-13 | 配送順序並び替え | 配送順序を手動調整 | 中 |
| F3-14 | 配送ルート表示 | 地図上に配送先をマッピング | 中 |
| F3-15 | ルート最適化提案 | 効率的な配送順序を自動提案 | 低 |

#### 3. 配送報告

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-20 | 配送開始報告 | 配送開始時刻を記録 | 高 |
| F3-21 | 配送完了報告 | 配送完了時刻、写真、メモを記録 | 高 |
| F3-22 | 写真撮影・アップロード | モバイルカメラで配送先写真を撮影 | 高 |
| F3-23 | 問題報告 | 配送トラブル（不在、住所不明等）を報告 | 高 |
| F3-24 | 署名取得 | 配送先で署名を取得（タッチパネル） | 低 |
| F3-25 | GPS位置記録 | 配送完了時の位置情報を記録 | 中 |

#### 4. 配送履歴・実績

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-30 | 配送履歴一覧 | 過去の配送履歴を表示 | 中 |
| F3-31 | 配送実績レポート | 月次・週次の配送実績を集計 | 中 |
| F3-32 | 配送時間分析 | 平均配送時間、遅延率を分析 | 低 |

#### 5. 通知機能

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-40 | 新規配送依頼通知 | 新規配送が割り当てられたら通知 | 高 |
| F3-41 | 配送時刻リマインダー | 配送時刻の30分前に通知 | 中 |
| F3-42 | 管理者への通知 | 配送完了時に管理者に通知 | 中 |

#### 6. モバイル対応

| ID | 機能 | 説明 | 優先度 |
|----|------|------|--------|
| F3-50 | レスポンシブデザイン | スマホ・タブレットで使いやすいUI | 高 |
| F3-51 | PWA対応 | ホーム画面追加、オフライン動作 | 高 |
| F3-52 | オフラインモード | ネットワーク切断時も閲覧可能 | 中 |
| F3-53 | プッシュ通知 | ブラウザ通知API使用 | 中 |

### 非機能要件

| カテゴリ | 要件 | 目標値 |
|---------|------|--------|
| パフォーマンス | 画面読み込み時間 | < 2秒 |
| パフォーマンス | 写真アップロード時間 | < 5秒 |
| 可用性 | システム稼働率 | 99.9% |
| セキュリティ | 通信暗号化 | HTTPS必須 |
| セキュリティ | 写真データ保存 | S3暗号化保存 |
| ユーザビリティ | モバイルUI | タッチ操作に最適化 |
| ユーザビリティ | オフライン対応 | 基本機能は閲覧可能 |

---

## データベース設計

### 新規テーブル

#### 1. delivery_users（配送担当者）

配送会社の配送担当者アカウント

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | AUTO | ID |
| delivery_company_id | bigint | NO | - | 配送会社ID（外部キー） |
| email | string | NO | - | メールアドレス |
| encrypted_password | string | NO | - | 暗号化パスワード |
| name | string | NO | - | 担当者名 |
| phone | string | YES | - | 電話番号 |
| role | string | NO | 'driver' | 役割（admin/driver） |
| is_active | boolean | NO | true | アクティブフラグ |
| last_sign_in_at | datetime | YES | - | 最終ログイン日時 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス:**
- `delivery_company_id`
- `email` (UNIQUE)
- `is_active`

#### 2. delivery_assignments（配送割当）

配送担当者への配送割当

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | AUTO | ID |
| order_id | bigint | NO | - | 案件ID（外部キー） |
| delivery_user_id | bigint | NO | - | 配送担当者ID（外部キー） |
| delivery_company_id | bigint | NO | - | 配送会社ID（外部キー） |
| scheduled_date | date | NO | - | 配送予定日 |
| scheduled_time | time | YES | - | 配送予定時刻 |
| sequence_number | integer | YES | - | 配送順序 |
| status | string | NO | 'pending' | ステータス（pending/preparing/in_transit/completed/failed） |
| assigned_at | datetime | YES | - | 割当日時 |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス:**
- `order_id` (UNIQUE)
- `delivery_user_id`
- `delivery_company_id`
- `scheduled_date`
- `status`
- 複合インデックス: `(delivery_user_id, scheduled_date, status)`

**ステータス遷移:**
- pending（未着手）→ preparing（配送準備中）→ in_transit（配送中）→ completed（完了）
- pending → failed（配送失敗）

#### 3. delivery_reports（配送報告）

配送完了・問題報告

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | AUTO | ID |
| delivery_assignment_id | bigint | NO | - | 配送割当ID（外部キー） |
| delivery_user_id | bigint | NO | - | 配送担当者ID（外部キー） |
| report_type | string | NO | 'completed' | 報告種別（completed/failed/issue） |
| started_at | datetime | YES | - | 配送開始日時 |
| completed_at | datetime | YES | - | 配送完了日時 |
| latitude | decimal(10,7) | YES | - | 緯度 |
| longitude | decimal(10,7) | YES | - | 経度 |
| notes | text | YES | - | メモ |
| issue_type | string | YES | - | 問題種別（absent/address_unknown/other） |
| photos | json | YES | - | 写真URL配列 |
| signature_data | text | YES | - | 署名データ（Base64） |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス:**
- `delivery_assignment_id`
- `delivery_user_id`
- `report_type`
- `completed_at`

#### 4. delivery_routes（配送ルート記録）

配送ルートのGPS履歴

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | AUTO | ID |
| delivery_assignment_id | bigint | NO | - | 配送割当ID（外部キー） |
| delivery_user_id | bigint | NO | - | 配送担当者ID（外部キー） |
| recorded_at | datetime | NO | - | 記録日時 |
| latitude | decimal(10,7) | NO | - | 緯度 |
| longitude | decimal(10,7) | NO | - | 経度 |
| accuracy | decimal(5,2) | YES | - | 精度（メートル） |
| speed | decimal(5,2) | YES | - | 速度（km/h） |
| created_at | datetime | NO | - | 作成日時 |

**インデックス:**
- `delivery_assignment_id`
- `delivery_user_id`
- `recorded_at`

#### 5. push_subscriptions（プッシュ通知購読）

Web Push通知の購読情報

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | AUTO | ID |
| subscribable_type | string | NO | - | 購読者タイプ（DeliveryUser/AdminUser） |
| subscribable_id | bigint | NO | - | 購読者ID |
| endpoint | text | NO | - | プッシュエンドポイント |
| p256dh_key | string | NO | - | 公開鍵 |
| auth_key | string | NO | - | 認証キー |
| user_agent | text | YES | - | ユーザーエージェント |
| is_active | boolean | NO | true | アクティブフラグ |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

**インデックス:**
- 複合インデックス: `(subscribable_type, subscribable_id)`
- `endpoint` (UNIQUE)
- `is_active`

### 既存テーブルへの変更

#### orders テーブル

配送会社との連携フィールド追加

```ruby
add_column :orders, :delivery_notes, :text # 配送特記事項
add_column :orders, :recipient_name, :string # 受取人名
add_column :orders, :recipient_phone, :string # 受取人電話番号
add_column :orders, :delivery_address, :text # 配送先住所（企業住所と異なる場合）
```

#### delivery_companies テーブル

配送会社情報拡充

```ruby
add_column :delivery_companies, :api_enabled, :boolean, default: false # API連携有効化
add_column :delivery_companies, :api_key, :string # APIキー
add_column :delivery_companies, :service_area, :json # 配送エリア（都道府県配列）
```

---

## 画面設計

### 配送担当者向け画面

#### 1. ログイン画面 (`/delivery/login`)

- メールアドレス入力
- パスワード入力
- ログインボタン
- パスワードを忘れた場合のリンク

#### 2. 配送予定一覧画面 (`/delivery/assignments`)

**ヘッダー:**
- ロゴ
- 配送担当者名
- 通知アイコン
- メニュー（ハンバーガーメニュー）

**メインコンテンツ:**
- 日付選択（今日、明日、週間表示切替）
- ステータスフィルター（すべて、未着手、配送中、完了）
- 配送カードリスト
  - 配送時刻
  - 企業名
  - 配送先住所
  - 食数
  - ステータスバッジ
  - アクションボタン（詳細、ナビ開始）

**フッター:**
- ホーム
- 配送予定
- 履歴
- 設定

#### 3. 配送詳細画面 (`/delivery/assignments/:id`)

- 配送先情報
  - 企業名
  - 配送先住所
  - 受取人名・電話番号
  - 配送時刻
- 商品情報
  - 飲食店名
  - メニュー名
  - 食数
- 配送特記事項
- 地図表示（配送先ピン）
- アクションボタン
  - 配送開始
  - 配送完了
  - 問題報告
  - ナビ起動（Google Maps連携）

#### 4. 配送報告画面 (`/delivery/assignments/:id/report`)

- 配送完了報告フォーム
  - 配送完了時刻（自動入力）
  - 写真撮影・アップロード（複数枚可）
  - メモ入力
  - 位置情報取得（自動）
- 問題報告フォーム
  - 問題種別選択（不在、住所不明、その他）
  - 詳細メモ
  - 写真撮影
- 送信ボタン

#### 5. 配送履歴画面 (`/delivery/history`)

- 期間選択（今週、今月、カスタム期間）
- 配送履歴リスト
  - 日付
  - 企業名
  - ステータス
  - 配送時刻
- 詳細表示リンク

#### 6. 設定画面 (`/delivery/settings`)

- プロフィール編集
- 通知設定（プッシュ通知ON/OFF）
- パスワード変更
- ログアウト

### 管理者向け画面（既存の管理画面に追加）

#### 7. 配送担当者管理画面 (`/admin/delivery_users`)

- 配送担当者一覧
- 新規登録
- 編集・削除
- ステータス管理（有効/無効）

#### 8. 配送割当管理画面 (`/admin/delivery_assignments`)

- 配送割当一覧
- 日別・配送会社別フィルター
- 配送担当者への割当操作
- 配送順序調整（ドラッグ&ドロップ）
- ステータス一覧表示

#### 9. 配送ダッシュボード (`/admin/delivery_dashboard`)

- 今日の配送状況サマリー
  - 未着手/配送中/完了の件数
  - 配送会社別の進捗
- 配送遅延アラート
- 問題報告一覧
- 配送完了通知

---

## 実装スケジュール

### Week 1-2: 基盤構築

#### Day 1-2: データベース設計・マイグレーション
- [ ] delivery_users テーブル作成
- [ ] delivery_assignments テーブル作成
- [ ] delivery_reports テーブル作成
- [ ] delivery_routes テーブル作成
- [ ] push_subscriptions テーブル作成
- [ ] 既存テーブル（orders, delivery_companies）へのカラム追加

#### Day 3-4: 配送担当者認証機能
- [ ] DeliveryUserモデル作成（Devise統合）
- [ ] 配送担当者ログイン画面
- [ ] 配送担当者セッション管理
- [ ] 配送担当者パスワードリセット機能

#### Day 5-7: 管理画面（配送担当者管理）
- [ ] DeliveryUserDashboard作成（Administrate）
- [ ] 配送担当者一覧・新規作成・編集・削除
- [ ] 配送会社との紐付け管理
- [ ] テスト作成（Model/Request spec）

### Week 3-4: 配送予定管理

#### Day 8-10: 配送割当機能
- [ ] DeliveryAssignmentモデル作成
- [ ] 配送割当サービス（AssignDeliveryService）
- [ ] 管理画面：配送割当画面
- [ ] 配送順序調整機能（ドラッグ&ドロップ）
- [ ] テスト作成

#### Day 11-14: 配送予定一覧画面（モバイル）
- [ ] 配送担当者向けレイアウト作成（モバイル最適化）
- [ ] 配送予定一覧画面（/delivery/assignments）
- [ ] 日別・週別表示切替
- [ ] ステータスフィルター
- [ ] 配送詳細画面（/delivery/assignments/:id）
- [ ] レスポンシブデザイン実装
- [ ] テスト作成（Feature spec）

### Week 5-6: 配送報告機能

#### Day 15-17: 配送ステータス管理
- [ ] 配送ステータス更新API
- [ ] 配送開始報告機能
- [ ] 配送完了報告機能
- [ ] ステータス遷移バリデーション
- [ ] テスト作成

#### Day 18-21: 配送報告機能
- [ ] DeliveryReportモデル作成
- [ ] 配送報告画面（/delivery/assignments/:id/report）
- [ ] 写真撮影・アップロード機能（ActiveStorage + S3）
- [ ] 位置情報取得機能（Geolocation API）
- [ ] 問題報告機能（不在、住所不明等）
- [ ] テスト作成

### Week 7: モバイル対応・PWA

#### Day 22-24: PWA対応
- [ ] Service Worker実装
- [ ] マニフェストファイル作成（manifest.json）
- [ ] ホーム画面追加機能
- [ ] オフラインモード実装（キャッシュ戦略）
- [ ] アプリアイコン作成

#### Day 25-28: プッシュ通知
- [ ] PushSubscriptionモデル作成
- [ ] Web Push通知実装（webpush gem使用）
- [ ] 通知購読UI
- [ ] 新規配送依頼通知
- [ ] 配送時刻リマインダー通知
- [ ] テスト作成

### Week 8: 完成・テスト

#### Day 29-30: 配送履歴・実績
- [ ] 配送履歴画面（/delivery/history）
- [ ] 配送実績レポート（管理画面）
- [ ] 配送時間分析機能

#### Day 31-32: 統合テスト・パフォーマンステスト
- [ ] E2Eテスト作成（配送フロー全体）
- [ ] パフォーマンステスト（画面読み込み、写真アップロード）
- [ ] モバイルデバイステスト（iOS Safari, Android Chrome）
- [ ] オフラインモードテスト

#### Day 33-35: ドキュメント作成
- [ ] 配送担当者向け操作マニュアル
- [ ] 管理者向け配送管理マニュアル
- [ ] API仕様書更新
- [ ] データ移行手順書（配送会社データ）

---

## 技術仕様

### フロントエンド

#### フレームワーク・ライブラリ

| 名称 | 用途 | バージョン |
|------|------|----------|
| Tailwind CSS | レスポンシブデザイン | 3.x |
| Stimulus.js | JavaScriptコントローラー | 3.x |
| Turbo | SPA風ナビゲーション | 8.x |
| Leaflet.js | 地図表示 | 1.9.x |

#### PWA構成

```javascript
// service-worker.js
const CACHE_NAME = 'minnano-shashoku-v1';
const urlsToCache = [
  '/delivery/assignments',
  '/assets/application.css',
  '/assets/application.js',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});
```

#### manifest.json

```json
{
  "name": "みんなの社食 配送アプリ",
  "short_name": "配送アプリ",
  "start_url": "/delivery/assignments",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196f3",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### バックエンド

#### Gem追加

```ruby
# Gemfile
gem 'devise' # 既存（配送担当者用に拡張）
gem 'webpush' # Web Push通知
gem 'geocoder' # 住所→緯度経度変換
gem 'active_storage_validations' # 画像バリデーション
```

#### サービスクラス

**AssignDeliveryService:**
```ruby
# 配送割当サービス
class AssignDeliveryService
  def assign(order_id, delivery_user_id)
    # 配送割当ロジック
  end
end
```

**DeliveryNotificationService:**
```ruby
# 配送通知サービス
class DeliveryNotificationService
  def notify_new_assignment(delivery_assignment)
    # Web Push通知送信
  end
end
```

**RouteOptimizerService:**
```ruby
# 配送ルート最適化サービス（将来実装）
class RouteOptimizerService
  def optimize(delivery_assignments)
    # 巡回セールスマン問題を解く
  end
end
```

### セキュリティ

- HTTPS必須（本番環境）
- 配送担当者認証（Devise）
- CORS設定（API利用時）
- CSRFトークン保護
- S3画像暗号化保存
- 位置情報の適切な権限管理

---

## テスト計画

### テストカバレッジ目標

- Model spec: 100%
- Request spec: 90%以上
- Feature spec: 主要フロー100%
- パフォーマンステスト: 全画面

### テスト項目

#### Model spec

- [ ] DeliveryUserモデル（バリデーション、アソシエーション、認証）
- [ ] DeliveryAssignmentモデル（ステータス遷移、バリデーション）
- [ ] DeliveryReportモデル（位置情報、写真、問題報告）
- [ ] DeliveryRouteモデル（GPS履歴）
- [ ] PushSubscriptionモデル（購読管理）

#### Request spec

- [ ] 配送担当者認証API
- [ ] 配送予定一覧API
- [ ] 配送ステータス更新API
- [ ] 配送報告API
- [ ] プッシュ通知購読API

#### Feature spec

- [ ] 配送担当者ログイン
- [ ] 配送予定一覧表示
- [ ] 配送ステータス更新フロー
- [ ] 配送完了報告フロー
- [ ] 写真アップロードフロー
- [ ] プッシュ通知購読フロー

#### パフォーマンステスト

- [ ] 配送予定一覧（100件）が2秒以内
- [ ] 写真アップロード（3MB）が5秒以内
- [ ] N+1クエリなし（Bullet検証）

#### モバイルテスト

- [ ] iOS Safari テスト
- [ ] Android Chrome テスト
- [ ] タブレット表示確認
- [ ] オフラインモード動作確認
- [ ] PWAインストール確認

---

## リスク管理

| リスク | 発生確率 | 影響度 | 対策 |
|-------|---------|-------|------|
| GPS位置情報の精度不足 | 中 | 中 | 複数回測定して平均値を取得 |
| オフラインモードでのデータ同期 | 高 | 中 | 同期キューを実装、失敗時はリトライ |
| 写真アップロードの失敗 | 中 | 低 | リトライ機能、ローカル一時保存 |
| プッシュ通知の非対応ブラウザ | 低 | 低 | フォールバック通知（アプリ内通知） |
| 配送順序最適化の複雑性 | 中 | 低 | Phase 3では手動調整のみ実装 |

---

## 成功指標

| 指標 | 目標値 | 測定方法 |
|------|-------|---------|
| 配送担当者のアプリ利用率 | 90%以上 | 月次アクティブユーザー数 |
| 配送報告の自動化率 | 80%以上 | 手動報告vs自動報告の比率 |
| 配送完了報告の平均時間 | 3分以内 | 配送完了〜報告送信までの時間 |
| システム稼働率 | 99.9%以上 | Uptime監視 |
| 配送遅延の早期発見率 | 70%以上 | 予定時刻超過アラート数 |

---

## 次のステップ

Phase 3完了後、Phase 4（飲食店向け機能）に進みます。

**Phase 4の想定内容：**
- 飲食店用アカウント・認証
- 案件受注・確認機能
- 在庫管理・発注機能
- 売上・実績レポート
- メニュー管理・写真登録
