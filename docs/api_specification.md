# みんなの社食 API仕様書

**バージョン:** 1.0
**最終更新日:** 2025-12-05
**ステータス:** 設計段階（将来のAPI化に備えた仕様定義）

---

## 目次

1. [概要](#概要)
2. [認証](#認証)
3. [共通仕様](#共通仕様)
4. [請求書API](#請求書api)
5. [入金API](#入金api)
6. [在庫API](#在庫api)
7. [案件API](#案件api)
8. [企業API](#企業api)
9. [エラーコード](#エラーコード)

---

## 概要

### ベースURL

```
開発環境: http://localhost:3000/api/v1
本番環境: https://your-production-url.com/api/v1
```

### サポートするフォーマット

- JSON (application/json)

### 文字エンコーディング

- UTF-8

---

## 認証

### 認証方式

APIトークンによる認証を使用します。

### リクエストヘッダー

```
Authorization: Bearer {API_TOKEN}
Content-Type: application/json
```

### トークンの取得

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@example.com",
  "password": "password"
}
```

**レスポンス例:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-06T10:00:00Z",
  "user": {
    "id": 1,
    "email": "admin@example.com"
  }
}
```

---

## 共通仕様

### ページネーション

リスト取得APIはページネーションをサポートします。

**クエリパラメータ:**

| パラメータ | 型 | 説明 | デフォルト |
|-----------|-----|------|----------|
| page | integer | ページ番号 | 1 |
| per_page | integer | 1ページあたりの件数 | 25 |

**レスポンス例:**

```json
{
  "data": [...],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 120,
    "per_page": 25
  }
}
```

### 日付フォーマット

ISO 8601形式を使用します。

```
日付: 2025-12-05
日時: 2025-12-05T10:30:00+09:00
```

### ステータスコード

| コード | 説明 |
|-------|------|
| 200 | OK - リクエスト成功 |
| 201 | Created - リソース作成成功 |
| 400 | Bad Request - リクエストが不正 |
| 401 | Unauthorized - 認証エラー |
| 403 | Forbidden - 権限エラー |
| 404 | Not Found - リソースが見つからない |
| 422 | Unprocessable Entity - バリデーションエラー |
| 500 | Internal Server Error - サーバーエラー |

---

## 請求書API

### 請求書一覧取得

```http
GET /api/v1/invoices
```

**クエリパラメータ:**

| パラメータ | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| company_id | integer | 企業ID | ✗ |
| status | string | ステータス（draft/sent/paid/overdue） | ✗ |
| payment_status | string | 支払状況（unpaid/partial/paid） | ✗ |
| issue_date_from | date | 発行日開始 | ✗ |
| issue_date_to | date | 発行日終了 | ✗ |
| payment_due_date_from | date | 支払期限開始 | ✗ |
| payment_due_date_to | date | 支払期限終了 | ✗ |

**レスポンス例:**

```json
{
  "data": [
    {
      "id": 1,
      "invoice_number": "INV-202512-001",
      "company": {
        "id": 1,
        "name": "テスト企業株式会社"
      },
      "issue_date": "2025-12-01",
      "payment_due_date": "2025-12-31",
      "billing_period_start": "2025-11-01",
      "billing_period_end": "2025-11-30",
      "subtotal": 100000,
      "tax_amount": 10000,
      "total_amount": 110000,
      "status": "sent",
      "payment_status": "unpaid",
      "created_at": "2025-12-01T10:00:00+09:00",
      "updated_at": "2025-12-01T10:00:00+09:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 75,
    "per_page": 25
  }
}
```

### 請求書詳細取得

```http
GET /api/v1/invoices/{id}
```

**レスポンス例:**

```json
{
  "id": 1,
  "invoice_number": "INV-202512-001",
  "company": {
    "id": 1,
    "name": "テスト企業株式会社",
    "formal_name": "テスト企業株式会社",
    "billing_email": "billing@test-company.com"
  },
  "issue_date": "2025-12-01",
  "payment_due_date": "2025-12-31",
  "billing_period_start": "2025-11-01",
  "billing_period_end": "2025-11-30",
  "subtotal": 100000,
  "tax_amount": 10000,
  "total_amount": 110000,
  "status": "sent",
  "payment_status": "unpaid",
  "notes": "",
  "items": [
    {
      "id": 1,
      "description": "11月分 社食サービス",
      "quantity": 100,
      "unit_price": 1000,
      "amount": 100000
    }
  ],
  "payments": [],
  "created_at": "2025-12-01T10:00:00+09:00",
  "updated_at": "2025-12-01T10:00:00+09:00"
}
```

### 請求書作成

```http
POST /api/v1/invoices
Content-Type: application/json

{
  "company_id": 1,
  "invoice_number": "INV-202512-002",
  "issue_date": "2025-12-05",
  "payment_due_date": "2025-12-31",
  "billing_period_start": "2025-11-01",
  "billing_period_end": "2025-11-30",
  "status": "draft",
  "payment_status": "unpaid",
  "notes": "",
  "items": [
    {
      "description": "11月分 社食サービス",
      "quantity": 100,
      "unit_price": 1000
    }
  ]
}
```

**レスポンス例:**

```json
{
  "id": 2,
  "invoice_number": "INV-202512-002",
  "company": {
    "id": 1,
    "name": "テスト企業株式会社"
  },
  "issue_date": "2025-12-05",
  "payment_due_date": "2025-12-31",
  "billing_period_start": "2025-11-01",
  "billing_period_end": "2025-11-30",
  "subtotal": 100000,
  "tax_amount": 10000,
  "total_amount": 110000,
  "status": "draft",
  "payment_status": "unpaid",
  "created_at": "2025-12-05T10:00:00+09:00",
  "updated_at": "2025-12-05T10:00:00+09:00"
}
```

### 請求書更新

```http
PUT /api/v1/invoices/{id}
Content-Type: application/json

{
  "status": "sent",
  "notes": "送付完了"
}
```

### 請求書削除

```http
DELETE /api/v1/invoices/{id}
```

**レスポンス例:**

```json
{
  "message": "請求書を削除しました"
}
```

### 月次請求書生成

```http
POST /api/v1/invoices/generate_monthly
Content-Type: application/json

{
  "year": 2025,
  "month": 12,
  "company_id": 1
}
```

**レスポンス例:**

```json
{
  "message": "請求書を1件生成しました",
  "invoices": [
    {
      "id": 3,
      "invoice_number": "INV-202512-003",
      "company": {
        "id": 1,
        "name": "テスト企業株式会社"
      },
      "total_amount": 110000
    }
  ]
}
```

### 請求書PDF取得

```http
GET /api/v1/invoices/{id}/pdf
```

**レスポンス:**

PDFファイル (application/pdf)

---

## 入金API

### 入金一覧取得

```http
GET /api/v1/payments
```

**クエリパラメータ:**

| パラメータ | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| invoice_id | integer | 請求書ID | ✗ |
| company_id | integer | 企業ID | ✗ |
| payment_date_from | date | 入金日開始 | ✗ |
| payment_date_to | date | 入金日終了 | ✗ |
| payment_method | string | 入金方法（bank_transfer/credit_card/cash/other） | ✗ |

**レスポンス例:**

```json
{
  "data": [
    {
      "id": 1,
      "invoice": {
        "id": 1,
        "invoice_number": "INV-202512-001"
      },
      "company": {
        "id": 1,
        "name": "テスト企業株式会社"
      },
      "payment_date": "2025-12-15",
      "amount": 110000,
      "payment_method": "bank_transfer",
      "notes": "株式会社テスト企業より振込",
      "created_at": "2025-12-15T10:00:00+09:00",
      "updated_at": "2025-12-15T10:00:00+09:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 2,
    "total_count": 50,
    "per_page": 25
  }
}
```

### 入金詳細取得

```http
GET /api/v1/payments/{id}
```

### 入金記録作成

```http
POST /api/v1/payments
Content-Type: application/json

{
  "invoice_id": 1,
  "payment_date": "2025-12-15",
  "amount": 110000,
  "payment_method": "bank_transfer",
  "notes": "株式会社テスト企業より振込"
}
```

**レスポンス例:**

```json
{
  "id": 1,
  "invoice": {
    "id": 1,
    "invoice_number": "INV-202512-001",
    "total_amount": 110000,
    "payment_status": "paid"
  },
  "payment_date": "2025-12-15",
  "amount": 110000,
  "payment_method": "bank_transfer",
  "notes": "株式会社テスト企業より振込",
  "created_at": "2025-12-15T10:00:00+09:00",
  "updated_at": "2025-12-15T10:00:00+09:00"
}
```

### 入金記録更新

```http
PUT /api/v1/payments/{id}
Content-Type: application/json

{
  "amount": 55000,
  "notes": "一部入金"
}
```

### 入金記録削除

```http
DELETE /api/v1/payments/{id}
```

---

## 在庫API

### 在庫一覧取得

```http
GET /api/v1/supplies
```

**クエリパラメータ:**

| パラメータ | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| category | string | カテゴリ（container/chopsticks/spoon/fork/hand_towel/other） | ✗ |
| status | string | ステータス（sufficient/low/out_of_stock） | ✗ |

**レスポンス例:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "弁当容器（大）",
      "category": "container",
      "current_stock": 500,
      "minimum_stock": 100,
      "unit": "piece",
      "status": "sufficient",
      "notes": "500ml用",
      "created_at": "2025-12-01T10:00:00+09:00",
      "updated_at": "2025-12-05T10:00:00+09:00"
    },
    {
      "id": 2,
      "name": "割り箸",
      "category": "chopsticks",
      "current_stock": 80,
      "minimum_stock": 100,
      "unit": "set",
      "status": "low",
      "notes": "1セット100膳",
      "created_at": "2025-12-01T10:00:00+09:00",
      "updated_at": "2025-12-05T10:00:00+09:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 15,
    "per_page": 25
  }
}
```

### 在庫詳細取得

```http
GET /api/v1/supplies/{id}
```

**レスポンス例:**

```json
{
  "id": 1,
  "name": "弁当容器（大）",
  "category": "container",
  "current_stock": 500,
  "minimum_stock": 100,
  "unit": "piece",
  "status": "sufficient",
  "notes": "500ml用",
  "transactions": [
    {
      "id": 1,
      "transaction_date": "2025-12-01",
      "transaction_type": "in",
      "quantity": 1000,
      "notes": "A社より納品"
    },
    {
      "id": 2,
      "transaction_date": "2025-12-05",
      "transaction_type": "out",
      "quantity": 500,
      "notes": "使用分"
    }
  ],
  "created_at": "2025-12-01T10:00:00+09:00",
  "updated_at": "2025-12-05T10:00:00+09:00"
}
```

### 在庫作成

```http
POST /api/v1/supplies
Content-Type: application/json

{
  "name": "弁当容器（大）",
  "category": "container",
  "current_stock": 500,
  "minimum_stock": 100,
  "unit": "piece",
  "notes": "500ml用"
}
```

### 在庫更新

```http
PUT /api/v1/supplies/{id}
Content-Type: application/json

{
  "current_stock": 450,
  "minimum_stock": 120
}
```

### 在庫削除

```http
DELETE /api/v1/supplies/{id}
```

### 入出庫記録作成

```http
POST /api/v1/supplies/{id}/transactions
Content-Type: application/json

{
  "transaction_date": "2025-12-05",
  "transaction_type": "out",
  "quantity": 50,
  "notes": "12月5日使用分"
}
```

**レスポンス例:**

```json
{
  "id": 3,
  "supply": {
    "id": 1,
    "name": "弁当容器（大）",
    "current_stock": 450
  },
  "transaction_date": "2025-12-05",
  "transaction_type": "out",
  "quantity": 50,
  "notes": "12月5日使用分",
  "created_at": "2025-12-05T10:00:00+09:00"
}
```

---

## 案件API

### 案件一覧取得

```http
GET /api/v1/orders
```

**クエリパラメータ:**

| パラメータ | 型 | 説明 | 必須 |
|-----------|-----|------|------|
| company_id | integer | 企業ID | ✗ |
| restaurant_id | integer | 飲食店ID | ✗ |
| status | string | ステータス（pending/confirmed/completed/cancelled） | ✗ |
| scheduled_date_from | date | 予定日開始 | ✗ |
| scheduled_date_to | date | 予定日終了 | ✗ |

**レスポンス例:**

```json
{
  "data": [
    {
      "id": 1,
      "company": {
        "id": 1,
        "name": "テスト企業株式会社"
      },
      "restaurant": {
        "id": 1,
        "name": "テスト飲食店"
      },
      "menu": {
        "id": 1,
        "name": "日替わり弁当"
      },
      "order_type": "regular",
      "scheduled_date": "2025-12-10",
      "default_meal_count": 50,
      "status": "confirmed",
      "collection_time": "12:00",
      "warehouse_pickup_time": "11:00",
      "is_trial": false,
      "created_at": "2025-12-01T10:00:00+09:00",
      "updated_at": "2025-12-01T10:00:00+09:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 250,
    "per_page": 25
  }
}
```

### 案件詳細取得

```http
GET /api/v1/orders/{id}
```

### 案件作成

```http
POST /api/v1/orders
Content-Type: application/json

{
  "company_id": 1,
  "restaurant_id": 1,
  "menu_id": 1,
  "order_type": "regular",
  "scheduled_date": "2025-12-10",
  "default_meal_count": 50,
  "status": "confirmed",
  "collection_time": "12:00",
  "warehouse_pickup_time": "11:00",
  "is_trial": false
}
```

### 案件更新

```http
PUT /api/v1/orders/{id}
Content-Type: application/json

{
  "status": "completed"
}
```

### 案件削除

```http
DELETE /api/v1/orders/{id}
```

---

## 企業API

### 企業一覧取得

```http
GET /api/v1/companies
```

**レスポンス例:**

```json
{
  "data": [
    {
      "id": 1,
      "name": "テスト企業",
      "formal_name": "テスト企業株式会社",
      "contract_status": "active",
      "billing_email": "billing@test-company.com",
      "created_at": "2025-12-01T10:00:00+09:00",
      "updated_at": "2025-12-01T10:00:00+09:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 10,
    "per_page": 25
  }
}
```

### 企業詳細取得

```http
GET /api/v1/companies/{id}
```

---

## エラーコード

### エラーレスポンス形式

```json
{
  "error": {
    "code": "validation_error",
    "message": "バリデーションエラーが発生しました",
    "details": [
      {
        "field": "issue_date",
        "message": "発行日を入力してください"
      }
    ]
  }
}
```

### エラーコード一覧

| コード | HTTPステータス | 説明 |
|-------|---------------|------|
| unauthorized | 401 | 認証エラー |
| forbidden | 403 | 権限エラー |
| not_found | 404 | リソースが見つからない |
| validation_error | 422 | バリデーションエラー |
| already_exists | 422 | リソースが既に存在する |
| cannot_delete | 422 | 削除できない（依存関係あり） |
| internal_error | 500 | サーバーエラー |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|---------|
| 1.0 | 2025-12-05 | 初版作成 |

---

## お問い合わせ

API仕様に関するお問い合わせは以下までご連絡ください：

- **開発担当**: Claude
- **GitHub Issues**: https://github.com/anthropics/claude-code/issues
