
. $PSScriptRoot\sendMessage.ps1
. $PSScriptRoot\resultToMsg.ps1
. $PSScriptRoot\..\commands.ps1
#Load config
$config = Get-Content $PSScriptRoot\..\config.json | ConvertFrom-Json
#url
$url = "https://api.telegram.org/bot$($config.botapi)/getUpdates"
function commitUpdate
{
  param (
    $msg
  )
  $url = "$url`?offset=$($msg.update_id+1)"
  return Invoke-RestMethod -Uri $url 
}

$msg = Invoke-RestMethod -Uri $url 
if ($msg.result.Length -eq 0)
{
  Write-Host "No new updates" -ForegroundColor Green
  return
}
# last processed but not commited message
$Global:EVETMSG
$msg = resultToMsg -result $msg.result[0]
if ($msg.messageId -eq $EVENTMSG) {
  #wait next message
  return
}
if ($null -eq $EVENTMSG) {
  $EVENTMSG = $msg.messageId
}

#check if trusted
if (-not $config.trusted.Contains($msg.chatId)) {
  send -text "You're not allowed to send commands to this bot" -chat $msg.chatId
  return
}

#check if allowed
if (!($config.allowed.Contains($msg.command.verb))) {
  Write-Host "Command " -NoNewline -ForegroundColor DarkRed
  Write-Host "$($msg.command.verb)" -NoNewline -ForegroundColor Red
  Write-Host " is not allowed" -ForegroundColor DarkRed
  return
}

$result = Invoke-Expression -Command "$($msg.command.verb) $($msg.command.params)" 
if ($null -ne $result.info) {
  send -text $result.info -chat $msg.chatId -mode "Markdown"
}
else {
  Write-Host $result.error -ForegroundColor Red
}
if (!($config.notCommit.Contains($msg.command.verb))) {
  Write-Host "Commiting message on <$($msg.command.verb)>..." -ForegroundColor Blue 
  commitUpdate $msg
}
$EVENTMSG = $msg.messageId