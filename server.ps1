# 文字コードの設定
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Output "管理者権限で再起動します..."
    Start-Sleep -Seconds 1
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$PSScriptRoot'; & '$PSCommandPath'`""
    exit
}

# HTTPリスナーの設定
$port = 8080
$url = "http://localhost:${port}/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

# ポートが使用中かチェック
try {
    $listener.Start()
} catch {
    Write-Output "Error: Port $port is in use."
    Write-Output "Please use a different port or close the application using this port."
    Write-Output "Press Enter to exit..."
    Read-Host
    exit
}

# データディレクトリの作成
$dataDir = Join-Path $PSScriptRoot "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

# サンプルデータの作成（存在しない場合）
$booksFile = Join-Path $dataDir "books.json"
if (-not (Test-Path $booksFile)) {
    $sampleBooks = @(
        @{
            id = 1
            title = "PowerShell入門"
            author = "山田太郎"
            publisher = "技術評論社"
            publishedDate = "2024-01-01"
            isbn = "978-4-7741-1234-5"
        },
        @{
            id = 2
            title = "Windows標準機能活用術"
            author = "鈴木花子"
            publisher = "翔泳社"
            publishedDate = "2024-02-15"
            isbn = "978-4-7981-5678-9"
        }
    )
    $sampleBooks | ConvertTo-Json | Set-Content $booksFile
}

Clear-Host
Write-Output "================================================="
Write-Output "               Book Manager Server                 "
Write-Output "================================================="
Write-Output ""
Write-Output "Server started at: $url"
Write-Output "Data directory: $dataDir"
Write-Output ""
Write-Output "Close this window to stop the server."
Write-Output "================================================="

# ブラウザを自動で開く
Start-Process $url

# MIMEタイプの設定
$mimeTypes = @{
    ".html" = "text/html"
    ".js"   = "text/javascript"
    ".css"  = "text/css"
    ".json" = "application/json"
    ".xml"  = "application/xml"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # リクエストされたパスの解析
        $requestPath = $request.Url.LocalPath.TrimStart('/')
        
        # APIエンドポイントの処理
        if ($requestPath.StartsWith("api/")) {
            $endpoint = $requestPath.Substring(4)
            $method = $request.HttpMethod
            
            # CORSヘッダーの設定
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            
            # OPTIONSリクエストの処理
            if ($method -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                continue
            }
            
            # 本のデータ操作
            if ($endpoint -eq "books") {
                switch ($method) {
                    "GET" {
                        # 本の一覧取得
                        $data = Get-Content $booksFile | ConvertFrom-Json
                        $jsonResponse = $data | ConvertTo-Json
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                    "POST" {
                        # 新規本の追加
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $newBook = $body | ConvertFrom-Json
                        
                        $books = Get-Content $booksFile | ConvertFrom-Json
                        $newBook.id = ($books | Measure-Object -Property id -Maximum).Maximum + 1
                        $books += $newBook
                        
                        $books | ConvertTo-Json | Set-Content $booksFile
                        
                        $response.StatusCode = 201
                        $jsonResponse = $newBook | ConvertTo-Json
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                    "PUT" {
                        # 本の更新
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $updatedBook = $body | ConvertFrom-Json
                        
                        $books = Get-Content $booksFile | ConvertFrom-Json
                        $index = $books | Select-Object -Index $updatedBook.id - 1
                        if ($index) {
                            $books[$updatedBook.id - 1] = $updatedBook
                            $books | ConvertTo-Json | Set-Content $booksFile
                            $response.StatusCode = 200
                        } else {
                            $response.StatusCode = 404
                        }
                    }
                    "DELETE" {
                        # 本の削除
                        $id = [int]$request.QueryString["id"]
                        $books = Get-Content $booksFile | ConvertFrom-Json
                        $books = $books | Where-Object { $_.id -ne $id }
                        $books | ConvertTo-Json | Set-Content $booksFile
                        $response.StatusCode = 204
                    }
                }
            }
        }
        # 静的ファイルの処理
        else {
            $localPath = Join-Path $PSScriptRoot "public" $(if ($requestPath) { $requestPath } else { "index.html" })
            if (Test-Path $localPath -PathType Leaf) {
                $extension = [System.IO.Path]::GetExtension($localPath)
                $contentType = $mimeTypes[$extension]
                if (-not $contentType) {
                    $contentType = "application/octet-stream"
                }
                $response.Headers.Add("Content-Type", $contentType)
                $content = [System.IO.File]::ReadAllBytes($localPath)
                $response.OutputStream.Write($content, 0, $content.Length)
            }
            else {
                $response.StatusCode = 404
            }
        }

        $response.Close()
    }
}
catch {
    Write-Output "`nAn error occurred:"
    Write-Output $_.Exception.Message
    Write-Output "`nPress Enter to exit..."
    Read-Host
}
finally {
    $listener.Stop()
    $listener.Close()
} 