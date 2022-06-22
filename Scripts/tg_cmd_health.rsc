##########################
# /hi text
# Just echo to check bot is alive
# Input:
#  params - parameters
#  chatid - id of chat
#  from - name of who sent command
:local send [:parse [/system script get tg_sendMessage source]]
:local ppp [:len [/ppp active find]]

:put $params
:put $chatid
:put $from
 
:local text "Router Id:* $[/system identity get name] * %0A\
Uptime: _$[/system resource get uptime]_%0A\
CPU: _$[/system resource get cpu-load]_%0A\
RAM: _$(([/system resource get total-memory]-[/system resource get free-memory])/(1024*1024))M/$([/system resource get total-memory]/(1024*1024))M_%0A\
Voltage: _$[:pick [/system health get voltage] 0 2]V_%0A\
Temp: _$[ /system health get temperature]C_%0A\
PPP users: _$ppp online_"
 
$send chat=$chatid text=$text mode="Markdown"
:return true