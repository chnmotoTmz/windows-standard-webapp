# Debug Server for Book Management App
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# HTTP server settings
$port = 8080
$url = "http://localhost:${port}/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)

# Start the server
try {
    $listener.Start()
    Write-Output "Server started successfully at $url"
    
    # Create data directory if not exists
    $dataDir = Join-Path $PSScriptRoot "data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir | Out-Null
        Write-Output "Created data directory: $dataDir"
    } else {
        Write-Output "Data directory exists: $dataDir"
    }
    
    # Create sample data if not exists
    $booksFile = Join-Path $dataDir "books.json"
    if (-not (Test-Path $booksFile)) {
        $sampleBooks = @(
            @{
                id = 1
                title = "PowerShell Book"
                author = "Yamada Taro"
                publisher = "Technical Publishing"
                publishedDate = "2024-01-01"
                isbn = "978-4-7741-1234-5"
            },
            @{
                id = 2
                title = "Windows Features Guide"
                author = "Suzuki Hanako"
                publisher = "IT Publishing"
                publishedDate = "2024-02-15"
                isbn = "978-4-7981-5678-9"
            }
        )
        $sampleBooks | ConvertTo-Json | Set-Content $booksFile -Encoding UTF8
        Write-Output "Created sample data: $booksFile"
    } else {
        Write-Output "Sample data exists: $booksFile"
    }

    # Open browser
    Write-Output "Opening browser..."
    Start-Process $url
    
    # MIME types
    $mimeTypes = @{
        ".html" = "text/html"
        ".js"   = "text/javascript"
        ".css"  = "text/css"
        ".json" = "application/json"
        ".xml"  = "application/xml"
    }
    
    # Main server loop
    Write-Output "Starting server loop..."
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Request path
        $requestPath = $request.Url.LocalPath.TrimStart('/')
        Write-Output "Request received: $($request.HttpMethod) $($request.Url.LocalPath)"
        
        # API endpoint handling
        if ($requestPath.StartsWith("api/")) {
            Write-Output "  API request: $requestPath"
            $endpoint = $requestPath.Substring(4)
            $method = $request.HttpMethod
            
            # CORS headers
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            
            # OPTIONS request
            if ($method -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                Write-Output "  OPTIONS request handled"
                continue
            }
            
            # Books API
            if ($endpoint -eq "books") {
                Write-Output "  Books API: $method"
                switch ($method) {
                    "GET" {
                        # Get books
                        $data = Get-Content $booksFile -Encoding UTF8 | ConvertFrom-Json
                        $jsonResponse = $data | ConvertTo-Json
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        Write-Output "  Sent books data: $($data.Length) books"
                    }
                    "POST" {
                        # Add book
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $newBook = $body | ConvertFrom-Json
                        
                        $books = Get-Content $booksFile -Encoding UTF8 | ConvertFrom-Json
                        $newBook.id = if ($books.Count -eq 0) { 1 } else { ($books | Measure-Object -Property id -Maximum).Maximum + 1 }
                        $books += $newBook
                        
                        $books | ConvertTo-Json | Set-Content $booksFile -Encoding UTF8
                        
                        $response.StatusCode = 201
                        $jsonResponse = $newBook | ConvertTo-Json
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        Write-Output "  Added new book: $($newBook.title)"
                    }
                    "PUT" {
                        # Update book
                        $reader = New-Object System.IO.StreamReader($request.InputStream)
                        $body = $reader.ReadToEnd()
                        $updatedBook = $body | ConvertFrom-Json
                        
                        $books = Get-Content $booksFile -Encoding UTF8 | ConvertFrom-Json
                        $index = $books.id.IndexOf($updatedBook.id)
                        if ($index -ge 0) {
                            $books[$index] = $updatedBook
                            $books | ConvertTo-Json | Set-Content $booksFile -Encoding UTF8
                            $response.StatusCode = 200
                            Write-Output "  Updated book: $($updatedBook.title)"
                        } else {
                            $response.StatusCode = 404
                            Write-Output "  Book not found: ID $($updatedBook.id)"
                        }
                    }
                    "DELETE" {
                        # Delete book
                        $id = [int]$request.QueryString["id"]
                        $books = Get-Content $booksFile -Encoding UTF8 | ConvertFrom-Json
                        $books = $books | Where-Object { $_.id -ne $id }
                        $books | ConvertTo-Json | Set-Content $booksFile -Encoding UTF8
                        $response.StatusCode = 204
                        Write-Output "  Deleted book: ID $id"
                    }
                }
            }
        }
        # Static files
        else {
            Write-Output "  Static file request: $requestPath"
            
            # 修正: Join-Pathの使い方を修正
            if ([string]::IsNullOrEmpty($requestPath)) {
                $localPath = Join-Path $PSScriptRoot "public\index.html"
            } else {
                $localPath = Join-Path $PSScriptRoot "public\$requestPath"
            }
            
            Write-Output "  Looking for file: $localPath"
            
            if (Test-Path $localPath -PathType Leaf) {
                $extension = [System.IO.Path]::GetExtension($localPath)
                $contentType = $mimeTypes[$extension]
                if (-not $contentType) {
                    $contentType = "application/octet-stream"
                }
                
                try {
                    $content = [System.IO.File]::ReadAllBytes($localPath)
                    $response.Headers.Add("Content-Type", $contentType)
                    $response.ContentLength64 = $content.Length
                    $response.OutputStream.Write($content, 0, $content.Length)
                    Write-Output "  Sent file: $localPath ($($content.Length) bytes)"
                }
                catch {
                    Write-Output "  Error reading file: $($_.Exception.Message)"
                    $response.StatusCode = 500
                }
            }
            else {
                Write-Output "  File not found: $localPath"
                $response.StatusCode = 404
                $errorMessage = "File not found: $requestPath"
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
                $response.ContentType = "text/plain"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        
        $response.Close()
    }
}
catch {
    Write-Output "An error occurred:"
    Write-Output $_.Exception.Message
    Write-Output $_.ScriptStackTrace
    Write-Output "Press Enter to exit..."
    Read-Host
}
finally {
    if ($listener -ne $null) {
        $listener.Stop()
        $listener.Close()
    }
} 