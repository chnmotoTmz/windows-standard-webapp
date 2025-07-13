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
$gl_en = [System.Text.Encoding]::UTF8 # gl_en: グローバルエンコーディング (文字コード)
[Console]::OutputEncoding = $gl_en
$gl_po = 8080 # gl_po: グローバルポート (サーバーの待ち受けポート)
$gl_ur = "http://*:$($gl_po)/" # gl_ur: グローバルURL (サーバーのアドレス)
$gl_dd = Join-Path $PSScriptRoot "data" # gl_dd: グローバルデータディレクトリ (データフォルダの場所)
$gl_df = Join-Path $gl_dd "books.json" # gl_df: グローバルデータファイル (データファイルの場所)
$gl_mt = @{ # gl_mt: グローバルMIMEタイプ (ファイルの種類)
    ".html" = "text/html"
    ".js"   = "text/javascript"
    ".css"  = "text/css"
    ".json" = "application/json"
    ".xml"  = "application/xml"
}
#endregion

#region 初期化
function INIT { # INIT: 初期化
    $li = New-Object System.Net.HttpListener # li: リスナー (リクエストを待ち受ける)
    $li.Prefixes.Add($gl_ur)
    return $li
}

function START($li) { # START: 開始
    try {
        $li.Start()
        $ip = @(Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" } | Select-Object -ExpandProperty IPAddress) # ip: IPアドレス
        Write-Output "サーバーIP: $ip ポート: $($gl_po)"
        Write-Output "アクセスURL: http://$($ip):$($gl_po)/"

        if (-not (Test-Path $gl_dd)) {
            New-Item -ItemType Directory -Path $gl_dd | Out-Null
            Write-Output "作成しました: $($gl_dd)"
        }

        if (-not (Test-Path $gl_df)) {
            $ib = @( # ib: 初期書籍データ
                @{id=1;title="PowerShell Book";author="Yamada";publisher="Tech Pub";publishedDate="2024-01-01";isbn="978-4-7741-1234-5"},
                @{id=2;title="Windows Guide";author="Suzuki";publisher="IT Pub";publishedDate="2024-02-15";isbn="978-4-7981-5678-9"}
            )
            $ib | ConvertTo-Json | Set-Content $gl_df -Encoding UTF8
            Write-Output "作成しました: $($gl_df)"
        }

        Start-Process $gl_ur
        Write-Output "サーバー実行中..."
    }
    catch {
        Write-Output "サーバー開始中のエラー: $($_.Exception.Message)"
        throw
    }
}
#endregion

#region リクエスト処理
function HNDL($ct) { # HNDL: ハンドル (リクエストを処理する)
    $rq = $ct.Request # rq: リクエスト
    $rs = $ct.Response # rs: レスポンス
    $lp = $rq.Url.LocalPath.TrimStart('/') # lp: ローカルパス

    Write-Output "$($rq.HttpMethod) $($rq.Url.LocalPath)"

    if ($lp.StartsWith("api/")) {
        HAPI $rq $rs $lp
    } else {
        HFILE $rs $lp
    }

    $rs.Close()
}

function HAPI($rq, $rs, $lp) { # HAPI: APIハンドル
    $ap = $lp.Substring(4) # ap: APIパス
    $me = $rq.HttpMethod # me: メソッド

    # CORSヘッダー
    $rs.Headers.Add("Access-Control-Allow-Origin", "*")
    $rs.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    $rs.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

    if ($me -eq "OPTIONS") {
        $rs.StatusCode = 200
        return
    }

    switch ($ap) {
        "data/download" { HDWNLD $rs }
        "data/upload"   { HUPLD $rq $rs }
        "data/edit"     { HEDIT $rq $rs }
        "data/view"     { HVIEW $rs }
        "books"         { HBOOK $rq $rs }
        default {
            SNDRS $rs "不明なAPIパス: $ap" "text/plain" 404
        }
    }
}

function HFILE($rs, $lp) { # HFILE: ファイルハンドル
    $fp = if ([string]::IsNullOrEmpty($lp)) { # fp: ファイルパス
        Join-Path $PSScriptRoot "public\index.html"
    } else {
        Join-Path $PSScriptRoot "public\$lp"
    }

    if (Test-Path $fp -PathType Leaf) {
        $ex = [System.IO.Path]::GetExtension($fp) # ex: 拡張子
        $ct = $gl_mt[$ex] # ct: コンテンツタイプ
        if (-not $ct) { $ct = "application/octet-stream" }

        try {
            $fb = [System.IO.File]::ReadAllBytes($fp) # fb: ファイルバイト
            $rs.Headers.Add("Content-Type", $ct)
            $rs.ContentLength64 = $fb.Length
            $rs.OutputStream.Write($fb, 0, $fb.Length)
        }
        catch {
            SNDRS $rs "ファイル読み込みエラー" "text/plain" 500
        }
    } else {
        SNDRS $rs "見つかりません: $lp" "text/plain" 404
    }
}
#endregion

#region APIエンドポイント
function HDWNLD($rs) { # HDWNLD: ダウンロードハンドル
    try {
        if (Test-Path $gl_df) {
            $co = Get-Content $gl_df -Encoding UTF8 -Raw # co: コンテンツ
            $rs.Headers.Add("Content-Disposition", "attachment; filename=books.json")
            SNDRS $rs $co "application/json"
        } else {
            $rs.StatusCode = 404
        }
    } catch {
        $rs.StatusCode = 500
    }
}

function HUPLD($rq, $rs) { # HUPLD: アップロードハンドル
    try {
        $re = New-Object System.IO.StreamReader($rq.InputStream) # re: リーダー
        $co = $re.ReadToEnd() # co: コンテンツ
        $null = $co | ConvertFrom-Json # JSONを検証
        $co | Set-Content $gl_df -Encoding UTF8
        SNDRS $rs "OK" "text/plain" 200
    } catch {
        SNDRS $rs "エラー: $($_.Exception.Message)" "text/plain" 400
    }
}

function HEDIT($rq, $rs) { # HEDIT: 編集ハンドル
    try {
        $re = New-Object System.IO.StreamReader($rq.InputStream) # re: リーダー
        $co = $re.ReadToEnd() # co: コンテンツ
        $null = $co | ConvertFrom-Json # JSONを検証
        $co | Set-Content $gl_df -Encoding UTF8
        SNDRS $rs "OK" "text/plain" 200
    } catch {
        SNDRS $rs "エラー: $($_.Exception.Message)" "text/plain" 400
    }
}

function HVIEW($rs) { # HVIEW: 表示ハンドル
    try {
        if (Test-Path $gl_df) {
            $co = Get-Content $gl_df -Encoding UTF8 -Raw # co: コンテンツ
            SNDRS $rs $co "application/json"
        } else {
            $rs.StatusCode = 404
        }
    } catch {
        $rs.StatusCode = 500
    }
}

function HBOOK($rq, $rs) { # HBOOK: 書籍ハンドル
    switch ($rq.HttpMethod) {
        "GET"    { GETB $rs }
        "POST"   { ADDB $rq $rs }
        "PUT"    { UPDB $rq $rs }
        "DELETE" { DELB $rq $rs }
        default {
            $rs.StatusCode = 405 # メソッドは許可されていません
        }
    }
}

function GETB($rs) { # GETB: 書籍取得
    $bo = Get-Content $gl_df -Encoding UTF8 | ConvertFrom-Json # bo: 書籍
    $js = $bo | ConvertTo-Json # js: JSON
    SNDRS $rs $js "application/json"
}

function ADDB($rq, $rs) { # ADDB: 書籍追加
    try {
        $re = New-Object System.IO.StreamReader($rq.InputStream) # re: リーダー
        $bd = $re.ReadToEnd() # bd: ボディ
        $nbd = $bd | ConvertFrom-Json # nbd: 新規書籍データ

        $bo = Get-Content $gl_df -Encoding UTF8 | ConvertFrom-Json # bo: 書籍
        if ($bo -isnot [array]) { $bo = @($bo) }

        $mi = 0 # mi: 最大ID
        foreach ($b in $bo) { if ($b.id -gt $mi) { $mi = $b.id } }

        $nb = [PSCustomObject]@{ # nb: 新規書籍
            id = $mi + 1
            title = $nbd.title
            author = $nbd.author
            publisher = $nbd.publisher
            publishedDate = $nbd.publishedDate
            isbn = $nbd.isbn
        }

        $bo += $nb
        $bo | ConvertTo-Json | Set-Content $gl_df -Encoding UTF8

        $js = $nb | ConvertTo-Json # js: JSON
        SNDRS $rs $js "application/json" 201
    }
    catch {
        SNDRS $rs "エラー: $($_.Exception.Message)" "text/plain" 500
    }
}

function UPDB($rq, $rs) { # UPDB: 書籍更新
    try {
        $re = New-Object System.IO.StreamReader($rq.InputStream) # re: リーダー
        $bd = $re.ReadToEnd() # bd: ボディ
        $ub = $bd | ConvertFrom-Json # ub: 更新書籍

        $bo = Get-Content $gl_df -Encoding UTF8 | ConvertFrom-Json # bo: 書籍
        if ($bo -isnot [array]) { $bo = @($bo) }

        $bi = -1 # bi: 書籍インデックス
        for ($i = 0; $i -lt $bo.Length; $i++) {
            if ($bo[$i].id -eq $ub.id) { $bi = $i; break }
        }

        if ($bi -ge 0) {
            $bo[$bi] = $ub
            $bo | ConvertTo-Json | Set-Content $gl_df -Encoding UTF8
            $rs.StatusCode = 200
        } else {
            $rs.StatusCode = 404
        }
    }
    catch {
        $rs.StatusCode = 500
    }
}

function DELB($rq, $rs) { # DELB: 書籍削除
    try {
        $id = [int]$rq.QueryString["id"] # id: ID
        $bo = Get-Content $gl_df -Encoding UTF8 | ConvertFrom-Json # bo: 書籍
        if ($bo -isnot [array]) { $bo = @($bo) }

        $bo = $bo | Where-Object { $_.id -ne $id }
        $bo | ConvertTo-Json | Set-Content $gl_df -Encoding UTF8
        $rs.StatusCode = 204
    }
    catch {
        $rs.StatusCode = 500
    }
}

function SNDRS($rs, $co, $ct, $sc = 200) { # SNDRS: レスポンス送信
    $by = $gl_en.GetBytes($co) # by: バイト
    $rs.ContentType = $ct
    $rs.ContentLength64 = $by.Length
    $rs.StatusCode = $sc
    $rs.OutputStream.Write($by, 0, $by.Length)
}
#endregion

#region メインループ
function RUN($li) { # RUN: 実行
    while ($li.IsListening) {
        try {
            $ct = $li.GetContext() # ct: コンテキスト
            HNDL $ct
        }
        catch {
            Write-Output "サーバーループエラー: $($_.Exception.Message)"
        }
    }
}
#endregion

#region スクリプト実行
$li = $null # li: リスナー
try {
    $li = INIT
    START $li
    RUN $li
}
catch {
    Write-Output "致命的なエラー: $($_.Exception.Message)"
    Read-Host "Enterキーを押して終了"
}
finally {
    if ($li -ne $null) {
        $li.Stop()
        $li.Close()
    }
}
#endregion
