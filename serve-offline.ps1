$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8000
$prefix = "http://localhost:$port/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)

try {
  $listener.Start()
} catch {
  Write-Host "Unable to start server on $prefix"
  Write-Host "Another process may already be using port $port."
  throw
}

$mimeTypes = @{
  ".css"  = "text/css"
  ".gif"  = "image/gif"
  ".htm"  = "text/html"
  ".html" = "text/html"
  ".ico"  = "image/x-icon"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".js"   = "application/javascript"
  ".json" = "application/json"
  ".png"  = "image/png"
  ".svg"  = "image/svg+xml"
  ".txt"  = "text/plain"
  ".webp" = "image/webp"
  ".woff" = "font/woff"
  ".woff2" = "font/woff2"
}

Write-Host "Serving $root"
Write-Host "Open $prefix"
Write-Host "Press Ctrl+C to stop."

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    try {
      $relativePath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath.TrimStart("/"))
      if ([string]::IsNullOrWhiteSpace($relativePath)) {
        $relativePath = "index.html"
      }

      $filePath = Join-Path $root $relativePath
      $resolvedPath = [System.IO.Path]::GetFullPath($filePath)
      if (-not $resolvedPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $response.StatusCode = 403
        $response.Close()
        continue
      }

      if ((Test-Path -LiteralPath $resolvedPath) -and (Get-Item -LiteralPath $resolvedPath).PSIsContainer) {
        $resolvedPath = Join-Path $resolvedPath "index.html"
      }

      if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        $response.StatusCode = 404
        $bytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.ContentType = "text/plain; charset=utf-8"
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.Close()
        continue
      }

      $extension = [System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()
      $contentType = $mimeTypes[$extension]
      if (-not $contentType) {
        $contentType = "application/octet-stream"
      }

      $response.StatusCode = 200
      $response.ContentType = $contentType
      $buffer = [System.IO.File]::ReadAllBytes($resolvedPath)
      $response.ContentLength64 = $buffer.Length
      $response.OutputStream.Write($buffer, 0, $buffer.Length)
      $response.Close()
    } catch {
      if ($response.OutputStream.CanWrite) {
        $response.StatusCode = 500
        $bytes = [System.Text.Encoding]::UTF8.GetBytes("500 Internal Server Error")
        $response.ContentType = "text/plain; charset=utf-8"
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
      }
      $response.Close()
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
