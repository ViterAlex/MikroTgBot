function shutdown
{
  param (
    $params
  )
  #$params is mac-address

  $mac = $params.replace(":", "-")
  $count = (Get-NetAdapter | Where-Object { $_.MacAddress -eq $mac } | Measure-Object).Count
  if ($count -gt 0)
  {
    try
    {
      Stop-Service "DreamcatcherService"
    }
    catch
    {
      { 1:<#Do this if a terminating exception happens#> }
    }
    if (Test-Path -Path ".\Scripts\firstrun" -PathType Leaf)
    {
      Remove-Item -Path ".\Scripts\firstrun"
    }
    New-Item -Path ".\Scripts\firstrun"

    Stop-Computer -ComputerName $env:COMPUTERNAME -Force
    return @{"info" = "*$env:COMPUTERNAME*:%0AMa baby shot me down!" }
  }
  else
  {
    return @{"error" = "Not for me. Params are $params" }
  }
}
function health
{
  $uptime = (Get-CimInstance -ClassName Win32_OperatingSystem ).LastBootUpTime
  $uptime = ([System.DateTime]::Now - [System.DateTime]::Parse($uptime)).ToString("hh\:mm\:ss")
  #in KBytes
  $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1024
  #in KBytes
  $freeRam = (Get-CimInstance Win32_OperatingSystem | % FreePhysicalMemory)
  $usedRam = "{0:N2} GB" -f (($totalRam - $freeRam) / 1024 / 1024)
  $totalRam = "{0:N2} GB" -f ($totalRam / 1024 / 1024)
  $cpu = (Get-WmiObject Win32_Processor).LoadPercentage 
  $text = "PC: *$env:COMPUTERNAME*`n" + `
    "Uptime: _$($uptime)_`n" + `
    "CPU: _$($cpu)%_`n" + `
    "RAM: _$($usedRam) from $($totalRam)_ used"
  return @{"info" = $text }
  Write-Host "$($env:COMPUTERNAME) I'm OK!" -ForegroundColor Green
}

function online
{
  return @{"info" = "$env:COMPUTERNAME is here!" }
}