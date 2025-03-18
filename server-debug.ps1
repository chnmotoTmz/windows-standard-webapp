# Book App Server - Short var names for better compatibility
$e = [System.Text.Encoding]::UTF8
$OutputEncoding = $e
[Console]::OutputEncoding = $e

# Server settings
$p = 8080
$u = "http://*:${p}/"
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add($u)

try {
    $l.Start()
    # IPアドレス情報を表示
    $ip = @(Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1"} | Select-Object -ExpandProperty IPAddress)
    Write-Output "Server IP: $ip Port: $p"
    Write-Output "アクセス用URL: http://${ip}:$p/"
    
    # Data dir
    $d = Join-Path $PSScriptRoot "data"
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
        Write-Output "Created: $d"
    }
    
    # Data file
    $f = Join-Path $d "books.json"
    if (-not (Test-Path $f)) {
        $b = @(
            @{id=1;title="PowerShell Book";author="Yamada";publisher="Tech Pub";publishedDate="2024-01-01";isbn="978-4-7741-1234-5"},
            @{id=2;title="Windows Guide";author="Suzuki";publisher="IT Pub";publishedDate="2024-02-15";isbn="978-4-7981-5678-9"}
        )
        $b | ConvertTo-Json | Set-Content $f -Encoding UTF8
        Write-Output "Created: $f"
    }

    # Browser
    Start-Process $u
    
    # MIME
    $m = @{
        ".html"="text/html";".js"="text/javascript";".css"="text/css";
        ".json"="application/json";".xml"="application/xml"
    }
    
    # Main loop
    Write-Output "Running..."
    while ($l.IsListening) {
        $c = $l.GetContext()
        $r = $c.Request
        $s = $c.Response
        
        # Path
        $h = $r.Url.LocalPath.TrimStart('/')
        Write-Output "$($r.HttpMethod) $($r.Url.LocalPath)"
        
        # API
        if ($h.StartsWith("api/")) {
            $a = $h.Substring(4)
            $t = $r.HttpMethod
            
            # CORS
            $s.Headers.Add("Access-Control-Allow-Origin", "*")
            $s.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            $s.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            
            # OPTIONS
            if ($t -eq "OPTIONS") {
                $s.StatusCode = 200
                $s.Close()
                continue
            }
            
            # Data operations
            if ($a -eq "data/download") {
                try {
                    if (Test-Path $f) {
                        $x = Get-Content $f -Encoding UTF8 -Raw
                        $o = $e.GetBytes($x)
                        $s.ContentType = "application/json"
                        $s.Headers.Add("Content-Disposition", "attachment; filename=books.json")
                        $s.ContentLength64 = $o.Length
                        $s.OutputStream.Write($o, 0, $o.Length)
                    } else {
                        $s.StatusCode = 404
                    }
                } catch {
                    $s.StatusCode = 500
                }
            }
            elseif ($a -eq "data/upload" -and $t -eq "POST") {
                try {
                    $i = New-Object System.IO.StreamReader($r.InputStream)
                    $x = $i.ReadToEnd()
                    $null = $x | ConvertFrom-Json
                    $x | Set-Content $f -Encoding UTF8
                    
                    $s.StatusCode = 200
                    $g = "OK"
                    $o = $e.GetBytes($g)
                    $s.ContentType = "text/plain"
                    $s.ContentLength64 = $o.Length
                    $s.OutputStream.Write($o, 0, $o.Length)
                } catch {
                    $s.StatusCode = 400
                    $g = "Error: $($_.Exception.Message)"
                    $o = $e.GetBytes($g)
                    $s.ContentType = "text/plain"
                    $s.ContentLength64 = $o.Length
                    $s.OutputStream.Write($o, 0, $o.Length)
                }
            }
            elseif ($a -eq "data/edit" -and $t -eq "POST") {
                try {
                    $i = New-Object System.IO.StreamReader($r.InputStream)
                    $j = $i.ReadToEnd()
                    $null = $j | ConvertFrom-Json
                    $j | Set-Content $f -Encoding UTF8
                    
                    $s.StatusCode = 200
                    $g = "OK"
                    $o = $e.GetBytes($g)
                    $s.ContentType = "text/plain"
                    $s.ContentLength64 = $o.Length
                    $s.OutputStream.Write($o, 0, $o.Length)
                } catch {
                    $s.StatusCode = 400
                    $g = "Error: $($_.Exception.Message)"
                    $o = $e.GetBytes($g)
                    $s.ContentType = "text/plain"
                    $s.ContentLength64 = $o.Length
                    $s.OutputStream.Write($o, 0, $o.Length)
                }
            }
            elseif ($a -eq "data/view") {
                try {
                    if (Test-Path $f) {
                        $x = Get-Content $f -Encoding UTF8 -Raw
                        $o = $e.GetBytes($x)
                        $s.ContentType = "application/json"
                        $s.ContentLength64 = $o.Length
                        $s.OutputStream.Write($o, 0, $o.Length)
                    } else {
                        $s.StatusCode = 404
                    }
                } catch {
                    $s.StatusCode = 500
                }
            }
            # Books API
            elseif ($a -eq "books") {
                switch ($t) {
                    "GET" {
                        $k = Get-Content $f -Encoding UTF8 | ConvertFrom-Json
                        $j = $k | ConvertTo-Json
                        $o = $e.GetBytes($j)
                        $s.ContentType = "application/json"
                        $s.ContentLength64 = $o.Length
                        $s.OutputStream.Write($o, 0, $o.Length)
                    }
                    "POST" {
                        $i = New-Object System.IO.StreamReader($r.InputStream)
                        $w = $i.ReadToEnd()
                        $v = $w | ConvertFrom-Json
                        
                        try {
                            $k = Get-Content $f -Encoding UTF8 | ConvertFrom-Json
                            if ($k -isnot [array]) { $k = @($k) }
                            
                            $z = 0
                            foreach ($y in $k) { if ($y.id -gt $z) { $z = $y.id } }
                            
                            $n = [PSCustomObject]@{
                                id = $z + 1; title = $v.title; author = $v.author
                                publisher = $v.publisher; publishedDate = $v.publishedDate; isbn = $v.isbn
                            }
                            
                            $k += $n
                            $k | ConvertTo-Json | Set-Content $f -Encoding UTF8
                            
                            $s.StatusCode = 201
                            $j = $n | ConvertTo-Json
                            $o = $e.GetBytes($j)
                            $s.ContentType = "application/json"
                            $s.ContentLength64 = $o.Length
                            $s.OutputStream.Write($o, 0, $o.Length)
                        }
                        catch {
                            $s.StatusCode = 500
                            $g = "Error: $($_.Exception.Message)"
                            $o = $e.GetBytes($g)
                            $s.ContentType = "text/plain"
                            $s.ContentLength64 = $o.Length
                            $s.OutputStream.Write($o, 0, $o.Length)
                        }
                    }
                    "PUT" {
                        try {
                            $i = New-Object System.IO.StreamReader($r.InputStream)
                            $w = $i.ReadToEnd()
                            $q = $w | ConvertFrom-Json
                            
                            $k = Get-Content $f -Encoding UTF8 | ConvertFrom-Json
                            if ($k -isnot [array]) { $k = @($k) }
                            
                            $x = -1
                            for ($i = 0; $i -lt $k.Length; $i++) {
                                if ($k[$i].id -eq $q.id) { $x = $i; break }
                            }
                            
                            if ($x -ge 0) {
                                $k[$x] = $q
                                $k | ConvertTo-Json | Set-Content $f -Encoding UTF8
                                $s.StatusCode = 200
                            } else {
                                $s.StatusCode = 404
                            }
                        }
                        catch {
                            $s.StatusCode = 500
                        }
                    }
                    "DELETE" {
                        try {
                            $i = [int]$r.QueryString["id"]
                            $k = Get-Content $f -Encoding UTF8 | ConvertFrom-Json
                            if ($k -isnot [array]) { $k = @($k) }
                            
                            $k = $k | Where-Object { $_.id -ne $i }
                            $k | ConvertTo-Json | Set-Content $f -Encoding UTF8
                            $s.StatusCode = 204
                        }
                        catch {
                            $s.StatusCode = 500
                        }
                    }
                }
            }
            else {
                $s.StatusCode = 404
                $g = "Unknown: $a"
                $o = $e.GetBytes($g)
                $s.ContentType = "text/plain"
                $s.ContentLength64 = $o.Length
                $s.OutputStream.Write($o, 0, $o.Length)
            }
        }
        # Files
        else {
            if ([string]::IsNullOrEmpty($h)) {
                $v = Join-Path $PSScriptRoot "public\index.html"
            } else {
                $v = Join-Path $PSScriptRoot "public\$h"
            }
            
            if (Test-Path $v -PathType Leaf) {
                $x = [System.IO.Path]::GetExtension($v)
                $y = $m[$x]
                if (-not $y) { $y = "application/octet-stream" }
                
                try {
                    $z = [System.IO.File]::ReadAllBytes($v)
                    $s.Headers.Add("Content-Type", $y)
                    $s.ContentLength64 = $z.Length
                    $s.OutputStream.Write($z, 0, $z.Length)
                }
                catch {
                    $s.StatusCode = 500
                }
            }
            else {
                $s.StatusCode = 404
                $g = "Not found: $h"
                $o = $e.GetBytes($g)
                $s.ContentType = "text/plain"
                $s.ContentLength64 = $o.Length
                $s.OutputStream.Write($o, 0, $o.Length)
            }
        }
        
        $s.Close()
    }
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
    Read-Host
}
finally {
    if ($l -ne $null) {
        $l.Stop()
        $l.Close()
    }
} 