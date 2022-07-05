##########################################################################
# tg_cmd_coocoo - Init message
#  Input: 
#     $1 — script name (information only)
#     params — no params for the moment
#  Output: 
#    {"error"="error message"} on error 
#    {"info"="message from method";"replyMarkup"="inline buttons markup"} on success
##########################################################################
:put "Command $1 is executing";
:local replaceChar do={
  :for i from=0 to=([:len $1] - 1) do={
    :local char [:pick $1 $i]
    :if ($char = $2) do={
      :set $char $3
    }
    :set $output ($output . $char)
  }
  :return $output
}
:local emoji { \
              "wol"="%E2%8F%B0"; \
              "shutdown"="%F0%9F%9B%8C" \
              };
:local buttons { \
                ("{\"text\":\"".($emoji->"wol")." Wake up\",\"callback_data\":\"menu wol\"}"), \
                ("{\"text\":\"".($emoji->"shutdown")." Shutdown\",\"callback_data\":\"menu shutdown\"}") \
               };
:local inlineButtons [$replaceChar ("{\"inline_keyboard\":[[ ".[:tostr $buttons]."]]}") ";" "," ]
$fTGsend chat=$chatid text="What to do?" mode="Markdown" replyMarkup=$inlineButtons;

return {"info"="What to do?";"replyMarkup"=$inlineButtons};