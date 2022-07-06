@echo off
powershell set-executionpolicy -ExecutionPolicy ByPass -Scope LocalMachine
powershell %cd%\install.ps1