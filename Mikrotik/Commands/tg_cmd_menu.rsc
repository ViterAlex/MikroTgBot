##########################################################################
# tg_cmd_menu - Send menu
#  Input: 
#     $1 — script name (information only)
#     params — menu to be shown. One of: {wol, shutdown}
#  Output: 
#     On error:      
#       {"error"="error message"}
#     On success:
#       {"info"="message from method";"replyMarkup"="inline buttons markup"}
##########################################################################
:put "Command $1 is executing";
:local emoji { \
              "pc"="%F0%9F%92%BB";
              }
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
# :global fTGsend;
:local buttons { \
                "wol"={
                  "{\"text\":\"".($emoji->"pc")." Miner\",\"callback_data\":\"wolByName sic-chief-631\"}", \
                  "{\"text\":\"".($emoji->"pc")." Nimble Bell\",\"callback_data\":\"wolByName PC2\"}" \
                };
                "shutdown"={
                  "{\"text\":\"".($emoji->"pc")." Miner\",\"callback_data\":\"shutdown sic-chief-631\"}", \
                  "{\"text\":\"".($emoji->"pc")." Nimble Bell\",\"callback_data\":\"shutdown VM-BOT-TEST\"}" \
                }
               };
:put $buttons;
:local inlineButtons [$replaceChar ("{\"inline_keyboard\":[[ ".[:tostr ($buttons->$params)]."]]}") ";" "," ]
:put $inlineButtons;
return {"info"="Select PC";"replyMarkup"=$inlineButtons};
