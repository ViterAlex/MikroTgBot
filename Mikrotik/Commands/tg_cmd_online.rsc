##########################################################################
# tg_cmd_online - To see who's online
#  Input: 
#     $1 — script name (information only)
#     params — no params for the moment
#  Output: 
#     On error:
#       {"error"="error message"}
#     On success:
#       {"info"="message from method"}
##########################################################################
:put "Command $1 is executing";
return {"info"=("*".[/system identity get name]."* is here!")};