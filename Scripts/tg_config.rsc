######################################
# Telegram bot API, VVS/BlackVS 2017
#                                Config file
######################################
:put "tg: Load config"

# to use config insert next lines:
#:local fconfig [:parse [/system script get tg_config source]]
#:local config [$fconfig]
#:put $config

######################################
# Common parameters
######################################

:local config {

"botAPI"="botapi";
"defaultChatID"="chatid";
"trusted"="chatid";
"storage"="";
"timeout"=1;
}

return $config