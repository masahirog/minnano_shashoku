# 開発の進め方

このドキュメントでは、Phase 1（およびそれ以降）の開発を進める際の基本的なワークフローを説明します。

---

## 1. 基本的な開発フロー

### 1.1 毎日の開発サイクル

```
1. チェックリスト確認
   ↓
2. タスク選択
   ↓
3. ブランチ作成
   ↓
4. 実装
   ↓
5. テスト実行
   ↓
6. コミット
   ↓
7. プッシュ
   ↓
8. チェックリスト更新
```

### 1.2 具体的なコマンド例

```bash
# 1. 最新のmainブランチを取得
git checkout main
git pull origin main

# 2. 作業ブランチ作成（命名ルール: feature/phase1-xxx）
git checkout -b feature/phase1-recurring-order-model

# 3. 実装
# （コードを書く）

# 4. テスト実行
rspec spec/models/recurring_order_spec.rb

# 5. コミット
git add .
git commit -m "Add RecurringOrder model with validations and associations"

# 6. プッシュ
git push origin feature/phase1-recurring-order-model

# 7. （GitHub上でプルリクエスト作成 → レビュー → マージ）

# 8. チェックリスト更新
# docs/phase1_checklist.md を編集して [ ] を [x] に変更
git add docs/phase1_checklist.md
git commit -m "Update checklist: RecurringOrder model completed"
git push origin main
```

---

## 2. ブランチ戦略

### 2.1 ブランチの種類

| ブランチ名 | 用途 | 例 |
|-----------|------|-----|
| `main` | 本番環境にデプロイ可能な安定版 | `main` |
| `feature/phase1-xxx` | Phase 1の各機能開発 | `feature/phase1-calendar-view` |
| `feature/phase2-xxx` | Phase 2の各機能開発 | `feature/phase2-invoice` |
| `bugfix/xxx` | バグ修正 | `bugfix/calendar-date-format` |
| `hotfix/xxx` | 緊急の本番修正 | `hotfix/pdf-generation-error` |

### 2.2 ブランチのライフサイクル

```
main
 │
 ├─ feature/phase1-recurring-order-model
 │   │
 │   └─ (開発完了・テスト完了)
 │       │
 │       └─ Pull Request → Review → Merge to main
 │
 ├─ feature/phase1-calendar-view
 │   │
 │   └─ (開発完了・テスト完了)
 │       │
 │       └─ Pull Request → Review → Merge to main
 │
 └─ ...
```

### 2.3 マージのタイミング

- 各機能（Day単位のタスク）が完了したらマージ
- テストがすべてパスしていること
- コードレビューを受けること（可能なら）

---

## 3. コミットメッセージ規約

### 3.1 フォーマット

```
<type>: <subject>

<body>

<footer>
```

### 3.2 type の種類

| type | 説明 | 例 |
|------|------|-----|
| `feat` | 新機能 | `feat: Add RecurringOrder model` |
| `fix` | バグ修正 | `fix: Fix calendar date format` |
| `refactor` | リファクタリング | `refactor: Extract PDF generation logic` |
| `test` | テスト追加・修正 | `test: Add RecurringOrder validation tests` |
| `docs` | ドキュメント | `docs: Update Phase 1 implementation plan` |
| `chore` | その他（ビルド、設定等） | `chore: Add prawn gem` |

### 3.3 コミットメッセージ例

```
feat: Add RecurringOrder model with validations

- Add day_of_week, frequency, start_date, end_date fields
- Add associations: company, restaurant, menu, delivery_company
- Add validations: day_of_week inclusion, end_date after start_date
- Add scopes: active, for_day_of_week, current

Refs: #123
```

---

## 4. テスト戦略

### 4.1 テストの種類

| 種類 | 目的 | ツール | 実行タイミング |
|------|------|--------|---------------|
| Model spec | モデルのロジック検証 | RSpec | 実装直後 |
| Request spec | API動作検証 | RSpec | 実装直後 |
| Feature spec | E2E動作検証 | RSpec + Capybara | 機能完成後 |
| System spec | ブラウザ操作検証 | RSpec + Selenium | 機能完成後 |

### 4.2 テスト実行コマンド

```bash
# すべてのテストを実行
rspec

# 特定のファイルのみ実行
rspec spec/models/recurring_order_spec.rb

# 特定の行のテストのみ実行
rspec spec/models/recurring_order_spec.rb:23

# テストカバレッジ確認
COVERAGE=true rspec
open coverage/index.html
```

### 4.3 テストの書き方（例）

```ruby
# spec/models/recurring_order_spec.rb
require 'rails_helper'

RSpec.describe RecurringOrder, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      recurring_order = build(:recurring_order)
      expect(recurring_order).to be_valid
    end

    it 'is invalid without a company' do
      recurring_order = build(:recurring_order, company: nil)
      expect(recurring_order).not_to be_valid
      expect(recurring_order.errors[:company]).to include("must exist")
    end

    it 'is invalid with day_of_week outside 0-6' do
      recurring_order = build(:recurring_order, day_of_week: 7)
      expect(recurring_order).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active recurring orders' do
        active = create(:recurring_order, is_active: true)
        inactive = create(:recurring_order, is_active: false)
        expect(RecurringOrder.active).to include(active)
        expect(RecurringOrder.active).not_to include(inactive)
      end
    end
  end
end
```

---

## 5. データベースマイグレーション

### 5.1 マイグレーションの作成

```bash
# テーブル作成
rails g migration CreateRecurringOrders

# カラム追加
rails g migration AddScheduleFieldsToOrders recurring_order_id:references menu_confirmed:boolean

# カラム削除
rails g migration RemoveOldFieldFromOrders old_field:string

# カラム変更
rails g migration ChangeDeliveryTimeToTimeInOrders
```

### 5.2 マイグレーションの実行

```bash
# マイグレーション実行
rails db:migrate

# ロールバック（1つ前に戻す）
rails db:rollback

# 特定のバージョンまで戻す
rails db:migrate:down VERSION=20250102123456

# マイグレーション状態確認
rails db:migrate:status
```

### 5.3 マイグレーションの注意点

- **本番環境でのデータ損失を防ぐ**
  - カラム削除は慎重に
  - 先にアプリ側で使われていないことを確認
  - バックアップを取る

- **ダウンタイムを最小化**
  - NOT NULL制約は段階的に（デフォルト値設定 → データ投入 → NOT NULL追加）
  - インデックス追加は `algorithm: :concurrently`（PostgreSQL）

- **ロールバック可能にする**
  - `up` と `down` を両方定義
  - または `change` メソッドで可逆的に書く

---

## 6. コードレビューのポイント

### 6.1 レビュー観点

- [ ] **機能要件を満たしているか**
  - 要件定義・チェックリストと照らし合わせる

- [ ] **テストがあるか**
  - Model/Request/Feature specが揃っているか
  - テストがパスしているか

- [ ] **パフォーマンスに問題ないか**
  - N+1クエリがないか（includes/joins/preloadを使う）
  - 不要なデータを取得していないか

- [ ] **セキュリティに問題ないか**
  - SQLインジェクション対策（パラメータバインド）
  - XSS対策（エスケープ処理）

- [ ] **コードの可読性**
  - 変数名・メソッド名が分かりやすいか
  - 長すぎるメソッドがないか（15行以内が目安）

- [ ] **一貫性**
  - プロジェクト内の既存コードと統一感があるか

### 6.2 セルフレビューチェックリスト

プルリクエストを出す前に自分でチェック：

- [ ] テストがすべてパスする
- [ ] Rubocopの警告がない（`rubocop`）
- [ ] N+1クエリがない（`bullet` gemで確認）
- [ ] 不要なコメント・デバッグコードを削除した
- [ ] マイグレーションのロールバックを確認した
- [ ] READMEやドキュメントを更新した（必要なら）

---

## 7. デプロイフロー

### 7.1 ローカル → 本番環境

```
1. ローカルで開発・テスト
   ↓
2. mainブランチにマージ
   ↓
3. 本番環境にデプロイ（Heroku/AWS/GCP等）
   ↓
4. マイグレーション実行
   ↓
5. 動作確認
   ↓
6. 問題があればロールバック
```

### 7.2 Herokuへのデプロイ例

```bash
# Herokuアプリ作成（初回のみ）
heroku create minnano-shashoku-prod

# PostgreSQL addon追加（初回のみ）
heroku addons:create heroku-postgresql:mini

# Redis addon追加（初回のみ）
heroku addons:create heroku-redis:mini

# 環境変数設定
heroku config:set RAILS_MASTER_KEY=xxx

# デプロイ
git push heroku main

# マイグレーション実行
heroku run rails db:migrate

# Sidekiq起動（Procfileで設定）
heroku ps:scale worker=1

# ログ確認
heroku logs --tail

# 本番環境のRailsコンソール
heroku run rails console
```

### 7.3 ロールバック手順

```bash
# 直前のリリースに戻す
heroku rollback

# または特定のバージョンに戻す
heroku releases
heroku rollback v123

# マイグレーションのロールバック
heroku run rails db:rollback
```

---

## 8. トラブルシューティング

### 8.1 よくある問題と解決方法

#### マイグレーションエラー

```bash
# エラー内容を確認
rails db:migrate:status

# ロールバックして再実行
rails db:rollback
rails db:migrate

# どうしても解決しない場合（開発環境のみ）
rails db:drop db:create db:migrate db:seed
```

#### N+1クエリ

```bash
# bullet gemで検出
# Gemfile
gem 'bullet', group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.console = true
end

# 修正例
# Bad
@orders = Order.all
@orders.each { |order| order.company.name }

# Good
@orders = Order.includes(:company)
@orders.each { |order| order.company.name }
```

#### テストが遅い

```ruby
# FactoryBotの build_stubbed を使う
# Bad
let(:company) { create(:company) }

# Good（DBに保存しない）
let(:company) { build_stubbed(:company) }

# テスト並列実行
# spec/spec_helper.rb
RSpec.configure do |config|
  config.jobs = 4
end
```

#### Sidekiqジョブが動かない

```bash
# Redisの起動確認
redis-cli ping

# Sidekiqの起動
bundle exec sidekiq

# ジョブの状態確認
rails console
> Sidekiq::Queue.new.size
> Sidekiq::RetrySet.new.size
```

---

## 9. 開発環境のセットアップ

新しい開発者がプロジェクトに参加する場合の手順：

### 9.1 初回セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/masahirog/minnano_shashoku.git
cd minnano_shashoku

# 2. Ruby バージョン確認・インストール
rbenv install 3.1.4
rbenv local 3.1.4

# 3. 依存関係インストール
bundle install

# 4. データベース作成・マイグレーション
rails db:create
rails db:migrate
rails db:seed

# 5. 環境変数設定
cp .env.example .env
# .envファイルを編集（AWSキー等）

# 6. Redis起動
redis-server

# 7. サーバー起動
rails server

# 8. Sidekiq起動（別ターミナル）
bundle exec sidekiq

# 9. ブラウザで確認
open http://localhost:3000/admin
```

### 9.2 日常的なセットアップ

```bash
# サーバー起動前に毎回実行

# 1. 最新コードを取得
git pull origin main

# 2. 依存関係更新
bundle install

# 3. マイグレーション実行
rails db:migrate

# 4. サーバー起動
rails server
```

---

## 10. 便利なツール・コマンド

### 10.1 開発効率化

```bash
# Railsコンソール
rails console

# データベースコンソール
rails dbconsole

# ルーティング確認
rails routes | grep orders

# モデル一覧
rails console
> ApplicationRecord.descendants.map(&:name)

# テーブル一覧
rails console
> ActiveRecord::Base.connection.tables
```

### 10.2 デバッグ

```ruby
# binding.pry でブレークポイント
# Gemfile
gem 'pry-byebug', group: :development

# コード内
def some_method
  binding.pry  # ここで止まる
  # ...
end
```

### 10.3 コード品質

```bash
# Rubocop（静的解析）
rubocop

# 自動修正
rubocop -a

# Brakeman（セキュリティチェック）
gem install brakeman
brakeman

# SimpleCov（テストカバレッジ）
COVERAGE=true rspec
open coverage/index.html
```

---

## 11. ドキュメント管理

### 11.1 ドキュメントの種類

| ドキュメント | 場所 | 更新タイミング |
|-------------|------|---------------|
| 要件定義書 | `docs/requirements.md` | プロジェクト開始時・仕様変更時 |
| システム設計書 | `docs/system_design.md` | プロジェクト開始時・設計変更時 |
| DB設計 | `docs/database_design.md` | テーブル追加時 |
| Phase別実装計画 | `docs/phase1_implementation_plan.md` | 各Phase開始時 |
| Phase別チェックリスト | `docs/phase1_checklist.md` | 毎日 |
| 開発ワークフロー | `docs/development_workflow.md` | ルール変更時 |
| 操作マニュアル | `docs/user_manual.md` | 機能追加時 |
| README | `README.md` | 常時 |

### 11.2 README.md の構成

```markdown
# みんなの社食 - 管理システム

## 概要
（サービス概要）

## 技術スタック
- Ruby 3.1.4
- Rails 7.1.5
- PostgreSQL 15
- Redis 7
- Sidekiq
- AWS S3

## セットアップ
（初回セットアップ手順）

## 開発
（開発の進め方、ブランチ戦略）

## デプロイ
（デプロイ手順）

## Phase別機能
- Phase 1: スケジュール管理 ✅
- Phase 2: 請求・支払い 🚧
- Phase 3: 飲食店アプリ 📋
- ...

## ライセンス
```

---

## 12. まとめ

### 12.1 開発を始める前に

1. `docs/phase1_checklist.md` を開く
2. 今日やるタスクを確認
3. 関連する `docs/phase1_implementation_plan.md` を読む

### 12.2 開発中

1. ブランチを切る
2. 実装
3. テストを書く・実行
4. コミット・プッシュ
5. チェックリストを更新

### 12.3 困ったら

1. このドキュメント（development_workflow.md）を読む
2. エラーメッセージをよく読む
3. Railsガイド・Gem のドキュメントを読む
4. ログを確認する（`tail -f log/development.log`）
5. Railsコンソールで動作確認（`rails console`）

---

質問があれば、このドキュメントに追記していきましょう！
