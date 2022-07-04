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
#     "timeout"="elapsed seconds to consider message expired";
#     "ignore"="commands separated with commas";
#     "executeNotCommit"="commands separated with commas";
#     }
#  Using:
#    :local fconfig [:parse [/system script get tg_config source]];
#    :local config [$fconfig];
#    :put $config;
##########################################################################

:local config {
  "botAPI"="botapi";
  "defaultChatID"="chatid";
  "trusted"="chatid separated with commas";
  "storage"="";
  "timeout"=120;
  "ignore"="shutdown";
  "executeNotCommit"="health";
}
:put "<tg_config>: Config------------------------------------------------"
:foreach k,v in=$config do={ :put "\t\"$k\" = \"$v\"" }
:put "\n"

return $config