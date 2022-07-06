
function printOK
{
  Write-Host "OK!" -ForegroundColor Green
}
function printFail
{
  param (
    $ex
  )
  Write-Host "FAIL!" -ForegroundColor Red
  Write-Host $ex
}
Write-Host "Check if service exists..." -NoNewline -ForegroundColor Green
$serviceName = "DreamcatcherService"
try
{
  Get-Service $serviceName -ErrorAction Stop -ErrorVariable ex | Out-Null
  printOK
  Write-Host "`tStop existing service..." -NoNewline -ForegroundColor Green
}
catch
{
  printFail $ex
}
try
{
  Stop-Service $serviceName -ErrorAction Stop -ErrorVariable ex
  Write-Host "`n`tDelete existing service..." -NoNewline -ForegroundColor Green
  sc.exe delete $serviceName | Out-Null
}
catch
{
  printFail $ex  
}

Write-Host "`nChecking destination folder..." -NoNewline -ForegroundColor Green
$dst = New-Item -Path "$env:ProgramData\Dreamcatcher" -Type Directory -Force
Write-Host "`nDelete old content..." -ForegroundColor Red
Remove-Item $dst -Recurse -Force
printOK

Write-Host "Copying files to $env:ProgramData..." -NoNewline -ForegroundColor Green
$src = $PSScriptRoot
Get-ChildItem $src -Exclude "install*.*" -File -Recurse | ForEach-Object {
  $newDir = ($_.DirectoryName).Replace($src, $dst)
  New-Item -Path $newDir -ItemType Directory -Force | Out-Null
  Copy-Item -Path $_.FullName -Destination $newDir
}
printOK


Write-Host "`nCreating service $serviceName..." -NoNewline -ForegroundColor Green
try
{
  New-Service -Name $serviceName `
    -BinaryPathName "$dst\svcbatch.exe run.bat" `
    -DisplayName "Dreamcatcher"`
    -StartupType Automatic -ErrorAction Stop -ErrorVariable ex | Out-Null
  printOK
}
catch
{
  Write-Host "FAIL!" -ForegroundColor Red
  Write-Host $ex
}
try
{
  Write-Host "Starting service $serviceName..." -NoNewline -ForegroundColor Green
  Start-Service $serviceName -ErrorAction Stop -ErrorVariable ex
  printOK
}
catch
{
  Write-Host "FAIL!" -ForegroundColor Red
  Write-Host $ex
  return
}

Write-Host "Enable logging to $dest\Logs..." -NoNewline -ForegroundColor Green
sc.exe control $serviceName 234