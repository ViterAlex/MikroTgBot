@echo off
powershell set-executionpolicy -ExecutionPolicy ByPass -Scope LocalMachine
powershell %~dp0install.ps1
pause