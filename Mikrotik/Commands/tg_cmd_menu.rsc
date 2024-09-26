##########################################################################
# tg_cmd_menu - Send menu
#  Input: 
#     $1 — script name (information only)
#     params — menu to be shown. One of: {main,wol,shutdown,edit,back,addmore}
#     text — message text if any.
#  Output: 
#     On error:      
#       {"error"="error message"}
#     On success:
#       {"info"="message from method";"replyMarkup"="inline buttons markup"}
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
#load emojis
:local emojiFile [:parse [/system script get tg_emoji source]];
:local emoji [$emojiFile];
#load config
:local cfgFile [:parse [/system script get tg_config source]];
:local cfg [$cfgFile];
#load list of computers from file
:global JSONLoad;
:local computers [$JSONLoad ($cfg->"PClist")]

#function to create buttons for computers. 
#$a argument is action {wol, shutdown, remove}
#$l argument is computers list as array
#$e argument is emojis
:local createButtons do={
  :local result [:toarray "";];
  :local line "";
  :local cmd "";
  :local i 0;
  :local j -1;
  :local btnLine "";
  :local btnText;
  :local uBound ([:len $l]-1)

  :foreach name,mac in=$l do={ 
    #command for 'wol' or 'shutdown' by default
    :set $cmd ($a."%20".$mac)
    :set $btnText (($e->"pc")."%20$name")
    #For 'remove' command put computer name instead of mac-address. Computer name must be enclosed in quotes
    :if ($a="remove") do={
      :set $cmd ($a." \\\"".$name."\\\"") 
    }
    :set $btnLine ("{\"text\":\"".$btnText."\",\"callback_data\":\"$cmd\"}")
    #form code for two columns of buttons
    :if ($i%2=0) do={ 
      :set $btnLine ("[".$btnLine)
      :if ($i=$uBound) do={ 
          :set $btnLine ($btnLine."]")
        } else={
          :set $btnLine ($btnLine.",")
        }
        :set $result ($result,$btnLine)
        :set $j ($j+1)
    }
    :if (($i%2)!=0) do={ 
      :set $btnLine ($btnLine."]")
      :set ($result->$j) (($result->$j).$btnLine)
    }
    :set $i ($i+1)
    # :set $line ("[{\"text\":\"".($e->"pc")."%20$name\",\"callback_data\":\"$cmd\"}]")
    # :set $result ($result, $line)
   }
  :return $result;
}
:local buttons { \
                "main"={ \
                  "[{\"text\":\"".($emoji->"wol")."%20Wake up\",\"callback_data\":\"menu wol\"}", \
                  "{\"text\":\"".($emoji->"shutdown")."%20Shutdown\",\"callback_data\":\"menu shutdown\"}]", \
                  "[{\"text\":\"".($emoji->"online")."%20Who's there?\",\"callback_data\":\"online\"}", \
                  "{\"text\":\"".($emoji->"health")."%20Health\",\"callback_data\":\"health\"}]", \
                  "[{\"text\":\"".($emoji->"edit")."%20Edit PCs\",\"callback_data\":\"menu edit\"}]" \ 
               };
                "edit"={
                  "[{\"text\":\"".($emoji->"add")."%20Add\",\"callback_data\":\"add\"}", \
                  "{\"text\":\"".($emoji->"remove")."%20Remove\",\"callback_data\":\"menu remove\"}]"
                };
                "remove"=[$createButtons a="remove" l=$computers e=$emoji];
                "wol"=[$createButtons a="wol" l=$computers e=$emoji];
                "shutdown"=[$createButtons a="shutdown" l=$computers e=$emoji];
                "back"={"[{\"text\":\"".($emoji->"menu")."%20Back to menu\",\"callback_data\":\"menu main\"}]"}
                "addmore"={
                  "[{\"text\":\"".($emoji->"add")."%20Add\",\"callback_data\":\"add\"}", \
                  "{\"text\":\"".($emoji->"menu")."%20Back to menu\",\"callback_data\":\"menu main\"}]"
                };
               };
#Add button to return to the main menu
:set ($buttons->"edit") (($buttons->"edit"),($buttons->"back"))
:set ($buttons->"wol") (($buttons->"wol"),($buttons->"back"))
:set ($buttons->"shutdown") (($buttons->"shutdown"),($buttons->"back"))
:set ($buttons->"remove") (($buttons->"remove"),($buttons->"back"))
:local msgText { \
                "main"="What to do?";
                "wol"="Select PC to wake up.";
                "shutdown"="Select PC to shutdown.";
                "remove"=($text."%0ASelect PC to remove.");
                "edit"="Here you can add or remove computers you want to manage.";
                "back"=$text;
                "addmore"=$text;
              };
#change semicolon to comma
:local inlineButtons [$replaceChar ("{\"inline_keyboard\":[ ".[:tostr ($buttons->$params)]."]}") ";" "," ]
:put $inlineButtons;
return {"info"=($msgText->$params);"replyMarkup"=$inlineButtons};
