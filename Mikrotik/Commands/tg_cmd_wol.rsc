##########################################################################
# tg_cmd_wol - inlinebuttons to WOL PC
# 
#  Input: 
#     $1 — script name (information only)
#     params
#     chat
#     from
#  Output: 
#    -1 on error 
#    "success" on success
##########################################################################
:put "Command $1 is executing";
#get references to functions from scripts
:local http [:parse [/system script get func_fetch source]];
:local fconfig [:parse [/system script get tg_config source]];
:local send [:parse [/system script get tg_sendMessage source]];

:global BUTTONS;
:if ([:typeof $BUTTONS]="nothing") do={ 
  $send text="No PCs added. Use menu to add one.";
        chat=$chat
  :return -1;
 }