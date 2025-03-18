# Web アプリ開発学習テンプレート API仕様書

本ドキュメントは、Windows標準機能で動作するWebアプリ開発学習テンプレートのAPI仕様を定義します。
このAPIは学習目的で設計されており、PowerShellのHTTPリスナー機能を使用して実装されています。

## 基本情報

- **ベースURL**: `http://<サーバーIP>:8080/api/`
- **応答形式**: JSON
- **文字コード**: UTF-8

## 認証

本APIでは認証機能は実装されていません（学習目的のため）。

## 共通ヘッダー

すべてのAPIレスポンスには以下のCORSヘッダーが含まれます：

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

## エンドポイント一覧

### 1. 書籍データAPI

#### 1.1 書籍一覧の取得

- **URL**: `/api/books`
- **メソッド**: GET
- **説明**: 登録されているすべての書籍情報を取得します
- **パラメータ**: なし
- **レスポンス**:
  - **成功時**: 200 OK
  ```json
  [
    {
      "id": 1,
      "title": "PowerShell Book",
      "author": "Yamada",
      "publisher": "Tech Pub",
      "publishedDate": "2024-01-01",
      "isbn": "978-4-7741-1234-5"
    },
    ...
  ]
  ```

#### 1.2 書籍の追加

- **URL**: `/api/books`
- **メソッド**: POST
- **説明**: 新しい書籍を追加します
- **リクエストボディ**:
  ```json
  {
    "title": "新しい本のタイトル",
    "author": "著者名",
    "publisher": "出版社",
    "publishedDate": "YYYY-MM-DD",
    "isbn": "ISBN番号"
  }
  ```
- **レスポンス**:
  - **成功時**: 201 Created
  ```json
  {
    "id": 3,
    "title": "新しい本のタイトル",
    "author": "著者名",
    "publisher": "出版社",
    "publishedDate": "YYYY-MM-DD",
    "isbn": "ISBN番号"
  }
  ```
  - **失敗時**: 500 Internal Server Error

#### 1.3 書籍の更新

- **URL**: `/api/books`
- **メソッド**: PUT
- **説明**: 既存の書籍情報を更新します
- **リクエストボディ**:
  ```json
  {
    "id": 1,
    "title": "更新後のタイトル",
    "author": "更新後の著者名",
    "publisher": "更新後の出版社",
    "publishedDate": "YYYY-MM-DD",
    "isbn": "更新後のISBN"
  }
  ```
- **レスポンス**:
  - **成功時**: 200 OK
  - **書籍が見つからない場合**: 404 Not Found
  - **失敗時**: 500 Internal Server Error

#### 1.4 書籍の削除

- **URL**: `/api/books?id={書籍ID}`
- **メソッド**: DELETE
- **説明**: 指定されたIDの書籍を削除します
- **パラメータ**:
  - `id`: 削除する書籍のID（必須）
- **レスポンス**:
  - **成功時**: 204 No Content
  - **失敗時**: 500 Internal Server Error

### 2. データ管理API

#### 2.1 JSONデータのダウンロード

- **URL**: `/api/data/download`
- **メソッド**: GET
- **説明**: 書籍データをJSONファイルとしてダウンロードします
- **レスポンス**:
  - **成功時**: 200 OK
    - Content-Type: application/json
    - Content-Disposition: attachment; filename=books.json
  - **ファイルが見つからない場合**: 404 Not Found
  - **失敗時**: 500 Internal Server Error

#### 2.2 JSONデータのアップロード

- **URL**: `/api/data/upload`
- **メソッド**: POST
- **説明**: JSONファイルをアップロードして書籍データを置き換えます
- **リクエストボディ**: JSON形式の書籍データ
- **レスポンス**:
  - **成功時**: 200 OK
    - レスポンスボディ: "OK"
  - **不正なJSONの場合**: 400 Bad Request
    - レスポンスボディ: "Error: {エラーメッセージ}"

#### 2.3 JSONデータの編集

- **URL**: `/api/data/edit`
- **メソッド**: POST
- **説明**: 書籍データをJSONテキストで直接編集します
- **リクエストボディ**: 編集後のJSON形式の書籍データ
- **レスポンス**:
  - **成功時**: 200 OK
    - レスポンスボディ: "OK"
  - **不正なJSONの場合**: 400 Bad Request
    - レスポンスボディ: "Error: {エラーメッセージ}"

#### 2.4 JSONデータの表示

- **URL**: `/api/data/view`
- **メソッド**: GET
- **説明**: 書籍データのJSONを直接表示します（ダウンロードではなく表示用）
- **レスポンス**:
  - **成功時**: 200 OK
    - Content-Type: application/json
  - **ファイルが見つからない場合**: 404 Not Found
  - **失敗時**: 500 Internal Server Error

## エラーコード

| ステータスコード | 説明 |
|------------|-----|
| 200 | 成功 |
| 201 | 作成成功 |
| 204 | 削除成功（コンテンツなし） |
| 400 | 不正なリクエスト |
| 404 | リソースが見つからない |
| 500 | サーバー内部エラー |

## データモデル

### 書籍モデル

```json
{
  "id": 1,              // 書籍ID（数値）
  "title": "string",    // タイトル
  "author": "string",   // 著者
  "publisher": "string", // 出版社
  "publishedDate": "YYYY-MM-DD", // 出版日（日付形式）
  "isbn": "string"     // ISBN番号
}
```

## 制限事項

1. このAPIは学習用であり、本番環境での使用は推奨されません
2. 認証機能は実装されていないため、データのセキュリティは保証されません
3. データは単一のJSONファイルに保存されるため、大量のデータ処理には適していません

## 実装例

### JavaScript からのAPIコール例

```javascript
// 書籍一覧の取得
async function getBooks() {
  const response = await fetch('/api/books');
  if (!response.ok) {
    throw new Error('書籍データの取得に失敗しました');
  }
  return await response.json();
}

// 書籍の追加
async function addBook(book) {
  const response = await fetch('/api/books', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(book)
  });
  
  if (!response.ok) {
    throw new Error('書籍の追加に失敗しました');
  }
  return await response.json();
}
``` 