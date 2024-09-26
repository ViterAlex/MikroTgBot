##########################################################################
# tg_config - config for telegram bot
# 
#  Input: 
#    none
#  Output: 
#    {
#     "botAPI"="botapi";
#     "defaultChatID"="chatid";
#     "trusted"="chatid separated with commas";
#     "storage"="";
#     "PClist"="list of computers to manage with bot";
#     "ftp"="user group for FTP within router,user name for FTP within router";
#     "timeout"="elapsed seconds to consider message expired";
#     "ignore"="commands separated with commas";
#     "executeNotCommit"="commands separated with commas";
#     "wolInterfaces"="List of interfaces to use with WoL command. Separated with commas."
#     }
#  Using:
#    :local cfgFile [:parse [/system script get tg_config source]];
#    :local cfg [$cfgFile];
##########################################################################

:local config {
  "botAPI"="botapi";
  "defaultChatID"="chatid";
  "trusted"="chatid separated with commas";
  "storage"="";
  "PClist"="computers.txt";
  "timeout"=120;
  "ftp"="botFTP,botftp";
  "ignore"="shutdown";
  "executeNotCommit"="health,online";
  "wolInterfaces"="bridge,ether1,ether2,ether3"
}
:put "<tg_config>: Config------------------------------------------------"
:foreach k,v in=$config do={ :put "\t\"$k\" = \"$v\"" }
:put "\n"

return $config