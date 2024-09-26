##########################################################################
# tg_cmd_wol - Wake-on-LAN
# 
#  Input: 
#     $1 — script name (information only)
#     params — mac-address for WoL command
#     chat — not used
#     from — not used
#  Output: 
#    -1 on error 
#    "success" on success
##########################################################################
:put "Command $1 is executing with mac-address=$params";
#load config
:local cfgFile [:parse [/system script get tg_config source]];
:local cfg [$cfgFile];
#get interfaces from config
:local interfaces [:toarray ($cfg->"wolInterfaces")]
#call WoL on all interfaces
:foreach i in=$interfaces do={
  /tool wol mac=$params interface=$i
}