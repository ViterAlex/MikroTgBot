##########################################################################
# fTGsend - function for sending messages
# 
#  Input: 
#    chat - if none send to default chat 
#    text - text to send
#    mode - empty or Markdown/HTML
#    replyMarkup — inline keyboard content if any
#  Output: 
#    {"error"="error message"} on error 
#    {"success"="true"; "reply"="reply text"} on success
##########################################################################
:local fconfig [:parse [/system script get tg_config source]]

:local cfg [$fconfig]
:local chatID ($cfg->"defaultChatID")
:local botID ($cfg->"botAPI")
:local storage ($cfg->"storage")

:if (any $chat) do={:set chatID $chat}

:local url "https://api.telegram.org/bot$botID/sendmessage\?chat_id=$chatID&text=$text"
:if (any $mode) do={
  :set url ($url."&parse_mode=$mode");
}
:if (any $replyMarkup) do={
  :set url ($url."&reply_markup=$replyMarkup");
}
:local file (($cfg->"storage")."tg_send_msgs.txt");
:local logfile (($cfg->"storage")."tg_send_log.txt");
:put ("url = $url");
:local reply ([/tool fetch url=$url output=user as-value ]->"data")
# /tool fetch url=$url keep-result=no
:return {"success"="true";"reply"=$reply}