@echo off
powershell Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine
powershell %cd%\Scripts\runbot.ps1