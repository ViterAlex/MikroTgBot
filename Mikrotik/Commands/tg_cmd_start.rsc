##########################################################################
# tg_cmd_start - Init message
#  Input: 
#     $1 — script name (information only)
#     params — no params for the moment
#  Output: 
#     On error:
#       {"error"="error message"}
#     On success:
#       {"info"="message from method";"replyMarkup"="inline buttons markup"}
##########################################################################
:put "Command $1 is executing";
#call main menu
:local script [:parse [/system script get tg_cmd_menu source]];
:return [$script "tg_cmd_menu" params="main"];