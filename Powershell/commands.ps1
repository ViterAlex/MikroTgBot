function shutdown
{
  param (
    $params
  )
  $name = $params
  if ($name -eq $env:COMPUTERNAME)
  {
    Stop-Computer -ComputerName $env:COMPUTERNAME -Force
    return @{"info"="*$env:COMPUTERNAME*:%0AMa baby shot me down!"}
  }
  else
  {
    return @{"error"="Not for me"}
  }
}
function health
{
  $uptime = (Get-CimInstance -ClassName Win32_OperatingSystem ).LastBootUpTime
  $uptime=([System.DateTime]::Now-[System.DateTime]::Parse($uptime)).ToString("hh\:mm\:ss")
  $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1024 / 1024
  $usedRam = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
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