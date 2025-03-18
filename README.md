# Windows標準機能で動作するWebアプリ開発学習テンプレート

**⚠️ 重要: このプロジェクトは現在開発中のため、正常に動作しません ⚠️**

現時点ではデバッグ中であり、正常に起動しない問題があります。修正作業を進めておりますので、ご了承ください。

## 開発環境について

### Cursor エディタの設定ファイル

本プロジェクトでは、Cursor エディタの設定ファイル（`.cursor`）を無視するように設定されています。これらのファイルは個人の開発環境に依存するため、バージョン管理から除外すべきものです。

- `.gitignore` ファイルに `.cursor` および `.cursor/**/*` のエントリが追加されています
- 新しい環境でプロジェクトを開く場合は、エディタ固有の設定を再設定してください

## アプリケーション実行方法

1. `run-server.bat` をダブルクリックで実行します（管理者権限が必要）
2. 自動的にブラウザが開き、アプリケーションが起動します
3. 終了するには、PowerShellのウィンドウを閉じてください

配布用の簡易説明書として `配布用README.txt` も用意していますが、最新かつ詳細な情報はこのREADME.mdをご参照ください。

## ネットワークアクセスについて

本アプリケーションは、同じネットワーク内の別PCからもアクセスできるように設定されています。

### 外部PCからアクセスする方法

1. **サーバーの起動**: `run-server.bat` をダブルクリックで実行します（管理者権限が必要）
2. **IPアドレスの確認**: サーバー起動時にコンソールに表示されるIPアドレスをメモします
3. **別PCからのアクセス**: 別PCのブラウザで `http://【サーバーのIP】:8080/` にアクセス

### 注意事項

- Windows Defenderファイアウォールでブロックされる場合は、ポート8080の通信を許可する設定が必要です
- 社内ネットワークなど、ネットワークポリシーによってはアクセスできない場合があります
- あくまで学習用なので、インターネット公開は推奨しません

## はじめに

情報システム部門の制約が厳しい環境でも利用できる「Webアプリ開発学習テンプレート」を作成しました。このテンプレートは、**Windows標準機能のみ**で動作し、追加インストールや管理者権限が一切不要です。データベースの基本からWebアプリケーション開発の基礎まで、すべてをブラウザとPowerShellで学べる教材となっています。

実装例として「本管理アプリ」を用意しましたが、このプロジェクトの本質は「厳格なIT環境でも使える学習ツール」である点が最大の特徴です。

## 教材の特徴

### 学習目標

1. **Windows標準機能によるデータ操作の基礎を学ぶ**
   - JSON/XMLを使ったデータの作成・読み取り・更新・削除(CRUD)操作を習得
   - PowerShellとブラウザの連携の仕組みを理解する

2. **フロントエンド開発の基本を体験**
   - HTML/CSS/JavaScriptの連携方法を実践的に学ぶ
   - イベント処理やDOM操作の基本を理解する

3. **実用的なアプリ開発スキルを養う**
   - Windows標準環境でのデータの永続化、検索、ソート機能の実装方法
   - 情報システム部門の承認なしで開発できるアプリケーション設計

### なぜWindows標準機能だけなのか？

- **IT部門の承認不要**：追加ソフトウェアのインストールや管理者権限が不要
- **どこでも学習可能**：制約の厳しい企業や学校環境でもすぐに始められる
- **即時フィードバック**：コード変更の結果がすぐに確認できる
- **実用的なスキル**：制約のある環境でも最大限の機能を実現する方法を学べる

## 技術的な特徴

### 変数名の簡略化について

当プロジェクトでは、以下の理由により変数名を極力短く簡略化しています：

- **非英語話者への配慮**：英語を母国語としないユーザーにとって、長い英語の変数名は認識・判別が困難な場合があります
- **画面表示の最適化**：狭い画面や低解像度環境での可読性向上
- **文字化け防止**：特殊文字を含む長い変数名が環境によって文字化けするリスクを軽減
- **タイプ量削減**：学習時にコードを手入力する際の負担軽減

主な変数の対応表：

| 短縮変数 | 元の変数名 | 役割 |
|---|---|---|
| $e | $outputEncoding | 文字エンコーディング |
| $l | $listener | HTTPリスナー |
| $p | $port | ポート番号 |
| $u | $url | サーバーURL |
| $d | $dataDir | データディレクトリ |
| $f | $booksFile | 書籍データファイル |
| $s | $response | HTTPレスポンス |
| $r | $request | HTTPリクエスト |

### 使用技術

- **フロントエンド**：HTML5, CSS3, JavaScript (ES6)
- **UIフレームワーク**：ピュアCSS（Bootstrap等の外部ライブラリに依存しない）
- **バックエンド**：PowerShell (Windows標準)
- **データストレージ**：JSON/XMLファイル (Windows標準)
- **Webサーバー**：System.Net.HttpListener (Windows標準)

### アーキテクチャ

学習の便宜を考え、シンプルな3層構造を採用しています：

1. **UIレイヤー**（HTML + CSS + main.js）
   - ユーザーインターフェースとイベント処理

2. **APIレイヤー**（PowerShellスクリプト）
   - HTTP経由でUIとデータをつなぐ中間層
   - データ操作に関するロジック

3. **データアクセスレイヤー**（JSONファイル）
   - PowerShellで直接操作可能な標準データ形式

## 学習コンテンツの詳細

### 1. PowerShellによるAPIの実装

PowerShellの標準機能のみを使用したHTTPサーバーとAPIを実装しています。

```powershell
# PowerShellで標準HTTPリスナーを作成
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add('http://localhost:8080/')
$l.Start()

# APIエンドポイントの処理
while ($l.IsListening) {
    $c = $l.GetContext()
    $r = $c.Request
    $s = $c.Response
    
    if ($r.Url.LocalPath -eq "/api/books" -and $r.HttpMethod -eq "GET") {
        # JSONデータの取得と返送
        $k = Get-Content ".\data\books.json" | ConvertFrom-Json
        $j = $k | ConvertTo-Json
        $o = [System.Text.Encoding]::UTF8.GetBytes($j)
        $s.ContentType = "application/json"
        $s.ContentLength64 = $o.Length
        $s.OutputStream.Write($o, 0, $o.Length)
    }
    # その他のエンドポイント処理...
    
    $s.Close()
}
```

これにより、サードパーティライブラリに頼らずにAPIサーバーを構築する方法を学べます。

### 2. JSON/XMLベースのデータ操作

SQLiteなどの外部データベースを使わずに、Windows標準のデータ形式を活用します：

```javascript
// フロントエンドからのデータ取得
async function getBooks() {
    try {
        const response = await fetch('/api/books');
        const books = await response.json();
        return books;
    } catch (error) {
        console.error('データの取得に失敗しました:', error);
        return [];
    }
}

// 検索機能の実装
async function searchBooks(keyword) {
    const books = await getBooks();
    return books.filter(book => 
        book.title.includes(keyword) || 
        book.author.includes(keyword)
    );
}
```

### 3. コンポーネント設計の学習

アプリケーションはモジュール分割されており、各コンポーネントの役割が明確です：

```javascript
// APIサービス
class BookService {
    async getBooks() {
        // HTTPリクエスト処理
    }
    
    async addBook(book) {
        // 本の追加処理
    }
}

// UIコントローラ
class BookController {
    constructor(service) {
        this.service = service;
    }
    
    async displayBooks() {
        const books = await this.service.getBooks();
        // DOM操作でリスト表示
    }
}

// アプリケーション初期化
const app = new BookController(new BookService());
app.init();
```

## 授業での活用方法

### 初級者向け（中学生レベル）

1. **完成品を触ってみる**
   - アプリの動作確認
   - データの入力、検索、編集を体験

2. **HTMLの修正**
   - タイトルやラベルの変更
   - 色やデザインの調整

3. **簡単な機能追加**
   - 並び替えボタンの追加
   - 本の表紙URL入力欄の追加

### 中級者向け（高校生・大学生レベル）

1. **PowerShellスクリプトの理解**
   - バックエンドAPIの動作原理を学ぶ
   - 新しいAPIエンドポイントの追加

2. **機能の拡張**
   - 画像アップロード機能の追加
   - データのCSVエクスポート機能

3. **UIの改良**
   - モバイル対応の強化
   - データ可視化コンポーネントの追加

### 上級者向け（社会人・企業研修レベル）

1. **制約下での最適化**
   - パフォーマンス改善手法
   - セキュリティ強化

2. **機能の高度化**
   - キャッシュ機構の実装
   - サーバーレスアプリへの進化

## テンプレートからの発展例

このテンプレートは「本管理」に限定されません。以下のような応用が可能です：

1. **社内文書管理システム**
   - 文書のタグ付けと検索
   - アクセス履歴の管理

2. **プロジェクト管理ツール**
   - タスク割り当てと進捗管理
   - ガントチャート表示

3. **研修管理システム**
   - 受講履歴の記録
   - アンケート集計機能

## 始め方

1. GitHub（[リポジトリURL: windows-standard-webapp-template](https://github.com/chnmotoTmz/windows-standard-webapp)）からコードをダウンロード
2. `server.ps1` をダブルクリックで実行（管理者権限不要）
3. ブラウザで `http://localhost:8080` にアクセス
4. コードを読み解きながら機能を確認
5. 自分なりに機能を拡張してみる

## ファイル構成

```
.
├── server.ps1        # PowerShellバックエンド
├── data/             # データファイル
│   └── books.json    # 本のデータ
├── public/           # 静的ファイル
│   ├── index.html    # メインのHTMLファイル
│   ├── css/          # スタイルシート
│   └── js/           # JavaScript
│       ├── main.js   # メインアプリケーション
│       └── api.js    # APIクライアント
└── README.md         # このファイル
```

## まとめ

このテンプレートは「制約のある環境でも使える実践的なプログラミング学習」のために開発されました。追加のソフトウェアインストールや管理者権限を必要とせず、完全にWindows標準機能だけでWebアプリケーション開発の基礎概念を学べるよう設計されています。

特に情報システム部門の承認が必要な環境や、PCへのインストール権限がない教育機関などで、制約を乗り越えて本格的な開発手法を学ぶことができます。

教育現場や企業研修、自己学習に活用いただければ幸いです。

## ライセンス

MITライセンスの下で公開しています。教育目的での利用や改変は自由に行っていただけます。
