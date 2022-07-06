##########################################################################
# tg_cmd_health - get router's state
#  Input: 
#     $1 — script name (information only)
#     params — no params
#  Output: 
#     On error:
#       {"error"="error message"}
#     On success:
#       {"info"="message from message"} on success
##########################################################################
:put "Command $1 is executing";

:local id [/system identity get name];
:local cpu [/system resource get cpu-load];
:local totalRam ([/system resource get total-memory]/(1024*1024));
:local freeRam ([/system resource get free-memory]/(1024*1024));
:local usedRam (($totalRam-$freeRam)."M");
:local text "Router:* $id * %0A\
Uptime: _$[/system resource get uptime]_%0A\
CPU: _$cpu%25_%0A\
RAM: _$usedRam from $totalRam used_"
:local v [:pick [/system health get voltage] 0 2];
:if (any v) do={ 
  :set $text ("%0A".$text.$v."V");
 }
:local t [/system health get temperature];
:if (any t) do={ 
  :set $text ("%0A".$text.$v."%C2%B0C");
 }
:return {"info"=$text}