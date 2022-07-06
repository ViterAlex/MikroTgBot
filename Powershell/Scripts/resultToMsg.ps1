function getCommand {
  param (
    $text
  )
  if ($text.StartsWith("/")) {
    $text=$text.Substring(1)
  }
  $ar=$text.Split(" ")
  $command=@{
       params=""
       script="tg_cmd_$($ar[0]).ps1"
       verb=$ar[0]
      }
  if ($ar.Length -gt 1) {
    $command.params=$ar[1];
  }
  return $command
}
function resultToMsg {
  param (
    $result
  )
  $msg=@{
    updateId=$result.update_id
    messageId=""
    fromId=""
    chatId=""
    expired=""
    userName=""
    firstName=""
    lastName=""
    text=""
    command=@{
      params=""
      script=""
      verb=""
    }
    isCallback=($null -eq $result.message)
  }
  if ($msg.isCallback){
    $msg.messageId  = $result.callback_query.message.message_id
    $msg.fromId     = $result.callback_query.from.id
    $msg.chatId     = $result.callback_query.message.chat.id   
    $msg.userName   = $result.callback_query.from.userName
    $msg.firstName  = $result.callback_query.from.first_name
    $msg.lastName   = $result.callback_query.from.last_name
    $msg.text       = $result.callback_query.message.text
    $msg.command    = getCommand -text $result.callback_query.data
  }
  else {
    $msg.messageId  = $result.message.message_id
    $msg.fromId     = $result.message.from.id
    $msg.chatId     = $result.message.chat.id   
    $msg.userName   = $result.message.from.userName
    $msg.firstName  = $result.message.from.first_name
    $msg.lastName   = $result.message.from.last_name
    $msg.text       = $result.message.text
    $msg.command    = getCommand -text $result.message.text
  }
  return $msg
}