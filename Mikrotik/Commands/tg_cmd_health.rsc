##########################################################################
# tg_cmd_healt - get router's state
#  Input: 
#     $1 — script name (information only)
#     params — hostname to Wake-On-LAN
#  Output: 
#    "err_msg" on error 
#    "success" on success
##########################################################################
:put "Command $1 is executing";
:global fTGsend;
:local ppp [:len [/ppp active find]]

:if (any $params) do={ 
  :put "params = $params";
 }
:if (any $chatid) do={ 
  :put "chatid = $params";
 }
:if (any $from) do={ 
  :put "from = $from";
 }
:local id [/system identity get name];
:local cpu [/system resource get cpu-load];
:local totalRam ([/system resource get total-memory]/(1024*1024));
:local freeRam ([/system resource get free-memory]/(1024*1024));
:local usedRam (($totalRam-$freeRam)."M");
:local text "Router Id:* $id * %0A\
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
$fTGsend chat=$chatid text=$text mode="Markdown"
:return true