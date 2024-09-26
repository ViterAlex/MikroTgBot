##########################################################################
#   fTGcommand - function for processing command in message text. Command
# must start with '/' symbol. May be followed with parameters separated with spaces.
#  Input: 
#     text - text from Telegram-message
#  Output: 
#    { "params"="params";"script"="scriptName";"verb"="verb"}
#  Error:
#     if text doesn't start with '/' or no ACTIVECOMMAND
##########################################################################
:global ACTIVECOMMAND;
#temporary variables
:local v;
:local p;
:local s;
:if (([:pick $text 0]="/")) do={
  #this is command started with /
  #find position of first whitespace
  :local pos [:find $text " "];
  #No spaces. So this is command with no params. Set command verb
  :if ([:type $pos]="nil") do={
    #Set verb (trim first symbol '/')
    :set $v [:pick $text 1 ([:len $text])];
  } else={
    :set $p [:pick $text ($pos+1) [:len $text]];
    :set $v [:pick $text 1 $pos];
  }
  :set $ACTIVECOMMAND;
} else={
  #this is not a command. Check if any ACTIVECOMMAND is present
  :if (!any $ACTIVECOMMAND) do={ 
    #no ACTIVECOMMAND. So an error.
    :set $ACTIVECOMMAND;
    :error "$text is not a command and no ACTIVECOMMAND";
  } else={
    #ACTIVECOMMAND is present and waiting for message from user
    :set $v $ACTIVECOMMAND;
    :set $p $text;  
  }
}
:set $s ("tg_cmd_".$v);
:return {"verb"=$v; "script"=$s; "params"=$p};