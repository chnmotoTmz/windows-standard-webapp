@echo off
echo 本管理アプリサーバーを起動します
echo 管理者権限で実行しています...

powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy', 'Bypass', '-File', '%~dp0server-debug.ps1' -Verb RunAs"

echo サーバーが起動しました。ブラウザが自動的に開きます。
echo 終了するには、PowerShellウィンドウを閉じてください。
pause 