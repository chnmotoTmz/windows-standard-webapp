@echo off
chcp 65001 > nul
title 本管理アプリ
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause 