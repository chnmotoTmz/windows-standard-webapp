<#
.SYNOPSIS
    ブックアプリサーバー
.DESCRIPTION
    書籍管理アプリケーション用のシンプルなWebサーバーです。
.NOTES
    作成者: あなたの名前
    日付: 2024-07-30
#>

#region サーバー設定
$e = [System.Text.Encoding]::UTF8 # e: エンコーディング (文字コード)
[Console]::OutputEncoding = $e
$p = 8080 # p: ポート (サーバーの待ち受けポート)
$u = "http://*:$($p)/" # u: URL (サーバーのアドレス)
$d = Join-Path $PSScriptRoot "data" # d: データディレクトリ (データフォルダの場所)
$f = Join-Path $d "books.json" # f: データファイル (データファイルの場所)
$m = @{ # m: MIMEタイプ (ファイルの種類)
    ".html" = "text/html"
    ".js"   = "text/javascript"
    ".css"  = "text/css"
    ".json" = "application/json"
    ".xml"  = "application/xml"
}
#endregion

#region 初期化
function INIT { # INIT: 初期化
    $l = New-Object System.Net.HttpListener # l: リスナー (リクエストを待ち受ける)
    $l.Prefixes.Add($u)
    return $l
}

function START($l) { # START: 開始
    try {
        $l.Start()
        $i = @(Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" } | Select-Object -ExpandProperty IPAddress) # i: IPアドレス
        Write-Output "サーバーIP: $i ポート: $($p)"
        Write-Output "アクセスURL: http://$($i):$($p)/"

        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d | Out-Null
            Write-Output "作成しました: $($d)"
        }

        if (-not (Test-Path $f)) {
            $b = @( # b: 初期書籍データ
                @{id=1;title="PowerShell Book";author="Yamada";publisher="Tech Pub";publishedDate="2024-01-01";isbn="978-4-7741-1234-5"},
                @{id=2;title="Windows Guide";author="Suzuki";publisher="IT Pub";publishedDate="2024-02-15";isbn="978-4-7981-5678-9"}
            )
            $b | ConvertTo-Json | Set-Content $f -Encoding UTF8
            Write-Output "作成しました: $($f)"
        }

        Start-Process $u
        Write-Output "サーバー実行中..."
    }
    catch {
        Write-Output "サーバー開始中のエラー: $($_.Exception.Message)"
        throw
    }
}
#endregion

#region リクエスト処理
function HNDL($c) { # HNDL: ハンドル (リクエストを処理する)
    $q = $c.Request # q: リクエスト
    $s = $c.Response # s: レスポンス
    $h = $q.Url.LocalPath.TrimStart('/') # h: ローカルパス

    Write-Output "$($q.HttpMethod) $($q.Url.LocalPath)"

    if ($h.StartsWith("api/")) {
        HAPI $q $s $h
    } else {
        HFILE $s $h
    }

    $s.Close()
}

function HAPI($q, $s, $h) { # HAPI: APIハンドル
    $a = $h.Substring(4) # a: APIパス
    $t = $q.HttpMethod # t: メソッド

    # CORSヘッダー
    $s.Headers.Add("Access-Control-Allow-Origin", "*")
    $s.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    $s.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

    if ($t -eq "OPTIONS") {
        $s.StatusCode = 200
        return
    }

    switch ($a) {
        "data/download" { HDWNLD $s }
        "data/upload"   { HUPLD $q $s }
        "data/edit"     { HEDIT $q $s }
        "data/view"     { HVIEW $s }
        "books"         { HBOOK $q $s }
        default {
            SNDRS $s "不明なAPIパス: $a" "text/plain" 404
        }
    }
}

function HFILE($s, $h) { # HFILE: ファイルハンドル
    $v = if ([string]::IsNullOrEmpty($h)) { # v: ファイルパス
        Join-Path $PSScriptRoot "public\index.html"
    } else {
        Join-Path $PSScriptRoot "public\$h"
    }

    if (Test-Path $v -PathType Leaf) {
        $x = [System.IO.Path]::GetExtension($v) # x: 拡張子
        $y = $m[$x] # y: コンテンツタイプ
        if (-not $y) { $y = "application/octet-stream" }

        try {
            $z = [System.IO.File]::ReadAllBytes($v) # z: ファイルバイト
            $s.Headers.Add("Content-Type", $y)
            $s.ContentLength64 = $z.Length
            $s.OutputStream.Write($z, 0, $z.Length)
        }
        catch {
            SNDRS $s "ファイル読み込みエラー" "text/plain" 500
        }
    } else {
        SNDRS $s "見つかりません: $h" "text/plain" 404
    }
}
#endregion

#region APIエンドポイント
function HDWNLD($s) { # HDWNLD: ダウンロードハンドル
    try {
        if (Test-Path $f) {
            $c = Get-Content $f -Encoding UTF8 -Raw # c: コンテンツ
            $s.Headers.Add("Content-Disposition", "attachment; filename=books.json")
            SNDRS $s $c "application/json"
        } else {
            $s.StatusCode = 404
        }
    } catch {
        $s.StatusCode = 500
    }
}

function HUPLD($q, $s) { # HUPLD: アップロードハンドル
    try {
        $r = New-Object System.IO.StreamReader($q.InputStream) # r: リーダー
        $c = $r.ReadToEnd() # c: コンテンツ
        $null = $c | ConvertFrom-Json # JSONを検証
        $c | Set-Content $f -Encoding UTF8
        SNDRS $s "OK" "text/plain" 200
    } catch {
        SNDRS $s "エラー: $($_.Exception.Message)" "text/plain" 400
    }
}

function HEDIT($q, $s) { # HEDIT: 編集ハンドル
    try {
        $r = New-Object System.IO.StreamReader($q.InputStream) # r: リーダー
        $c = $r.ReadToEnd() # c: コンテンツ
        $null = $c | ConvertFrom-Json # JSONを検証
        $c | Set-Content $f -Encoding UTF8
        SNDRS $s "OK" "text/plain" 200
    } catch {
        SNDRS $s "エラー: $($_.Exception.Message)" "text/plain" 400
    }
}

function HVIEW($s) { # HVIEW: 表示ハンドル
    try {
        if (Test-Path $f) {
            $c = Get-Content $f -Encoding UTF8 -Raw # c: コンテンツ
            SNDRS $s $c "application/json"
        } else {
            $s.StatusCode = 404
        }
    } catch {
        $s.StatusCode = 500
    }
}

function HBOOK($q, $s) { # HBOOK: 書籍ハンドル
    switch ($q.HttpMethod) {
        "GET"    { GETB $s }
        "POST"   { ADDB $q $s }
        "PUT"    { UPDB $q $s }
        "DELETE" { DELB $q $s }
        default {
            $s.StatusCode = 405 # メソッドは許可されていません
        }
    }
}

function GETB($s) { # GETB: 書籍取得
    $b = Get-Content $f -Encoding UTF8 | ConvertFrom-Json # b: 書籍
    $j = $b | ConvertTo-Json # j: JSON
    SNDRS $s $j "application/json"
}

function ADDB($q, $s) { # ADDB: 書籍追加
    try {
        $r = New-Object System.IO.StreamReader($q.InputStream) # r: リーダー
        $d = $r.ReadToEnd() # d: ボディ
        $n = $d | ConvertFrom-Json # n: 新規書籍データ

        $b = Get-Content $f -Encoding UTF8 | ConvertFrom-Json # b: 書籍
        if ($b -isnot [array]) { $b = @($b) }

        $i = 0 # i: 最大ID
        foreach ($o in $b) { if ($o.id -gt $i) { $i = $o.id } }

        $w = [PSCustomObject]@{ # w: 新規書籍
            id = $i + 1
            title = $n.title
            author = $n.author
            publisher = $n.publisher
            publishedDate = $n.publishedDate
            isbn = $n.isbn
        }

        $b += $w
        $b | ConvertTo-Json | Set-Content $f -Encoding UTF8

        $j = $w | ConvertTo-Json # j: JSON
        SNDRS $s $j "application/json" 201
    }
    catch {
        SNDRS $s "エラー: $($_.Exception.Message)" "text/plain" 500
    }
}

function UPDB($q, $s) { # UPDB: 書籍更新
    try {
        $r = New-Object System.IO.StreamReader($q.InputStream) # r: リーダー
        $d = $r.ReadToEnd() # d: ボディ
        $u = $d | ConvertFrom-Json # u: 更新書籍

        $b = Get-Content $f -Encoding UTF8 | ConvertFrom-Json # b: 書籍
        if ($b -isnot [array]) { $b = @($b) }

        $x = -1 # x: 書籍インデックス
        for ($i = 0; $i -lt $b.Length; $i++) {
            if ($b[$i].id -eq $u.id) { $x = $i; break }
        }

        if ($x -ge 0) {
            $b[$x] = $u
            $b | ConvertTo-Json | Set-Content $f -Encoding UTF8
            $s.StatusCode = 200
        } else {
            $s.StatusCode = 404
        }
    }
    catch {
        $s.StatusCode = 500
    }
}

function DELB($q, $s) { # DELB: 書籍削除
    try {
        $i = [int]$q.QueryString["id"] # i: ID
        $b = Get-Content $f -Encoding UTF8 | ConvertFrom-Json # b: 書籍
        if ($b -isnot [array]) { $b = @($b) }

        $b = $b | Where-Object { $_.id -ne $i }
        $b | ConvertTo-Json | Set-Content $f -Encoding UTF8
        $s.StatusCode = 204
    }
    catch {
        $s.StatusCode = 500
    }
}

function SNDRS($s, $c, $t, $k = 200) { # SNDRS: レスポンス送信
    $b = $e.GetBytes($c) # b: バイト
    $s.ContentType = $t
    $s.ContentLength64 = $b.Length
    $s.StatusCode = $k
    $s.OutputStream.Write($b, 0, $b.Length)
}
#endregion

#region メインループ
function RUN($l) { # RUN: 実行
    while ($l.IsListening) {
        try {
            $c = $l.GetContext() # c: コンテキスト
            HNDL $c
        }
        catch {
            Write-Output "サーバーループエラー: $($_.Exception.Message)"
        }
    }
}
#endregion

#region スクリプト実行
$l = $null # l: リスナー
try {
    $l = INIT
    START $l
    RUN $l
}
catch {
    Write-Output "致命的なエラー: $($_.Exception.Message)"
    Read-Host "Enterキーを押して終了"
}
finally {
    if ($l -ne $null) {
        $l.Stop()
        $l.Close()
    }
}
#endregion
