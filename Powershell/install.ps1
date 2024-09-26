
function printOK
{
  Write-Host "OK!" -ForegroundColor Green
}
function printFail
{
  param (
    $NextMessage
  )
  Write-Host "FAIL!`n" -ForegroundColor Red
  if ($null -ne $NextMessage) {
    Write-Host $NextMessage -ForegroundColor Green
  }
}
Write-Host "Check if service exists..." -NoNewline -ForegroundColor Green
$serviceName = "DreamcatcherService"
$installationFolder = "$env:ProgramData\Dreamcatcher"
$serviceExists = $false
try
{
  Get-Service $serviceName -ErrorAction Stop -ErrorVariable ex | Out-Null
  printOK
  $serviceExists = $true
}
catch
{
  printFail -NextMessage "Service does not exist."
}
if ($true -eq $serviceExists) {
  Write-Host "`tStop existing service..." -NoNewline -ForegroundColor Green
  try
  {
    Stop-Service $serviceName -ErrorAction Stop -ErrorVariable ex
    printOK
    Write-Host "`n`tDelete existing service..." -NoNewline -ForegroundColor Green
    sc.exe delete $serviceName | Out-Null
    printOK
  }
  catch
  {
    printFail  
    Write-Host $ex
  }
}

Write-Host "`nChecking destination folder..." -NoNewline -ForegroundColor Green
$dst = Get-Item -Path $installationFolder
printOK
if ($null -eq $dst) {
  $dst = New-Item -Path $installationFolder -Type Directory -Force
}else {
  Write-Host "`nDelete old content..." -ForegroundColor Green -NoNewline
  try {
    Remove-Item $dst -Recurse -Force -ErrorAction stop
  }
  catch {
  }
  printOK
}

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
    -StartupType Automatic -ErrorAction  stop  -ErrorVariable ex | Out-Null
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
printOK
sc.exe control $serviceName 234 >> Out-Null