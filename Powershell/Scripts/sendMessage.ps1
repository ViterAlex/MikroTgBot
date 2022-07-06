$config = Get-Content "$PSScriptRoot\..\config.json" | ConvertFrom-Json
function send {
  param (
    [Parameter(Mandatory=$true)][string]$text,
    [Parameter(Mandatory=$true)][string]$chat,
    [Parameter(Mandatory=$false)][string]$mode
  )
  $url ="https://api.telegram.org/bot$($config.botapi)/sendMessage?text=$text&chat_id=$chat"
  if ($null -ne $mode) {
    $url = "$url&parse_mode=$mode"
  }
  Invoke-RestMethod -Uri $url  
  # Write-Host "text=$text`r`nchat=$chat`r`nmode=$mode`r`nurl=$url"
}