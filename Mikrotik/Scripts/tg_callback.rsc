##########################################################################
#   fTGcallback - function for processing callback from inlinebutton.
# then consider first word as command and the rest as parameters
#  Input: 
#     query - callback_query->data object from message
#  Output: 
#    {"error"="error message"} on error 
#    {"verb"="verb"; "script"="scriptName"; "params"="params"}
##########################################################################
#temporary variables
:local v;
:local p;
:local s;
#find position of first whitespace
:local pos [:find $query " "];
:if ([:type $pos]="nil") do={
  #no spaces.
  :set $v $query;
  :set $s ("tg_cmd_".$v);
  :return {"verb"=$v; "script"=$s; "params"=$p};
}
#There are spaces
:set $v [:pick $query 0 $pos];
:set $s ("tg_cmd_".$v);
:set $p [:pick $query ($pos+1) [:len $query]];
:return {"verb"=$v; "script"=$s; "params"=$p};