##########################################################################
#   fTGcallback - function for processing callback from inlinebutton.
# then consider first word as command and the rest as parameters
#  Input: 
#     query - callback_query->data object from message
#  Output: 
#    {"error"="error message"} on error 
#    {"verb"="verb"; "script"="scriptName"; "params"="params"}
##########################################################################
:local command {"verb"=""; "script"=""; "params"=""};
#find position of first whitespace
:local pos [:find $query " "];
:if ([:type $pos]="nil") do={
  #no spaces.
  :set ($command->"verb") $query;
  :set ($command->"script") ("tg_cmd_".($command->"verb"));
  :return $command;
}
#There are spaces
:set ($command->"verb") [:pick $query 0 $pos];
:set ($command->"script") ("tg_cmd_".($command->"verb"));
:set ($command->"params") [:pick $query ($pos+1) [:len $query]];
:return $command;