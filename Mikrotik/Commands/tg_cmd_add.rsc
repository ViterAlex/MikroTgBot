##########################################################################
# tg_cmd_add - command for adding computers
#  Input: 
#     $1 — script name (information only)
#     params — message sent by user. Should be
#  Output: 
#     On error:
#       {"error"="error message"}
#     On success:
#       {"info"="message from method";"replyMarkup"="inline buttons markup"}
##########################################################################
:put "Command $1 is executing";
:local menuScript [:parse [/system script get tg_cmd_menu source]];
:global ACTIVECOMMAND;
:if (!any $ACTIVECOMMAND) do={
  #Here command is executing first time. So we need to set ACTIVECOMMAND and return text with back to menu button
  :global ACTIVECOMMAND "add"
  return [$menuScript text=("Provide list of computers in following format:%0A%0A". \ 
                  "%60%60%60json%0A". \
                  "%22Computer1 name%22%3A%22mac-address1%22,". \
                  "%22Computer2 name%22%3A%22mac-address2%22%0A". \
                  "%60%60%60%0A". \
                  "Mac-address format: %600a:1b:2c:3d:4e:5f%60%0A". \
                  "Pay attention at colons, quote marks and commas.") params="back"];
} else={
  #Here command is executing second time. So we process user's response passed with $params
  :local cfgFile [:parse [/system script get tg_config source]];
  :local cfg [$cfgFile];
  #read computers from file to array
  :global JSONLoad;
  :local computers [$JSONLoad ($cfg->"PClist")]
  :put "Message text: $params"
  #create array from user's input.
  :global JSONLoads;
  :local newComputers [$JSONLoads ("{".$params."}")]
  #compose message
  :local w ("*".[len $newComputers]."* computer")
  :if ([len $newComputers]>1) do={
    :set $w ($w."s")
  }
  :set $computers ($computers,$newComputers)
  :local list "";
  :local i 1;
  :foreach name,mac in=$computers do={ 
    :set $list ($list."$i  ".$name."%0A")
    :set $i ($i+1)
  }
  #write to file
  :global JsonFromArray;
  /file set ($cfg->"PClist") contents=[$JsonFromArray $computers]
  :set $ACTIVECOMMAND;
  #call main menu
  :return [$menuScript "tg_cmd_menu" text=("$w added.%0A```%0A$list%0A```") params="addmore"];
}