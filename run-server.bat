@echo off
chcp 65001 > nul
title 本管理アプリ - Windows標準機能版
echo ================================================
echo              本管理アプリ起動中
echo ================================================
echo.
echo 管理者権限でサーバーを起動しています...
echo ブラウザが自動的に開きます。
echo.
echo 終了するには、PowerShellウィンドウを閉じてください。
echo ================================================
echo.

powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', '%~dp0server-debug.ps1' -Verb RunAs"

echo.
echo サーバーが起動しました。
pause 