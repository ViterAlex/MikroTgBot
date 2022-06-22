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

"botAPI"="5583145927:AAEhL3ky6wuBY2S0vvAjryFa3VkiQsokzko";
"defaultChatID"="153118558";
"trusted"="153118558";
"storage"="";
"timeout"=1;
}

return $config