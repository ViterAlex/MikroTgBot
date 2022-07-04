##########################################################################
#   fTGcommand - function for processing command in message text. Command
# must start with /. May be followed with parameters separated with spaces.
#  Input: 
#     text - text from Telegram-message
#  Output: 
#    {"error"="error message"} on error 
#    {"verb"="verb"; "script"="scriptName"; "params"="params"}
##########################################################################
:local command {"verb"=""; "script"=""; "params"=""};
#Check if this is real command, i.e. start with /
:if ([:pick $text 0]!="/") do={
  :return {"error"="$text is not a command. Not started with /"};
}

#find position of first whitespace
:local pos [:find $text " "];
#Trim first symbol
:set $text [:pick $text 1 [:len $text]];
#set command name
:if ([:type $pos]="nil") do={
  #no spaces. Set script name
  :set ($command->"verb") $text;
  :set ($command->"script") ("tg_cmd_".($command->"verb"));
  :return $command;
}
#ok. There are spaces
:local params [:pick $text ($pos+1) [:len $text]];
:set ($command->"verb") [:pick $text 1 $pos];
:set ($command->"script") ("tg_cmd_".($command->"verb"));
:set ($command->"params") $params;
:return $command;