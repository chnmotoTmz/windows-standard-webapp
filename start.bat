@echo off
chcp 65001 > nul
title 本管理アプリ - Windows標準機能版
echo ================================================
echo              本管理アプリ起動中
echo ================================================
echo.
echo サーバーを起動しています...
echo ブラウザが自動的に開きます。
echo.
echo 終了するには、このウィンドウを閉じてください。
echo ================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server-debug.ps1"
pause 