/system script
add dont-require-permissions=no name=tg_config owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_config - config for telegram bot\r\
    \n# \r\
    \n#  Input: \r\
    \n#    none\r\
    \n#  Output: \r\
    \n#    {\r\
    \n#     \"botAPI\"=\"botapi\";\r\
    \n#     \"defaultChatID\"=\"chatid\";\r\
    \n#     \"trusted\"=\"chatid separated with commas\";\r\
    \n#     \"storage\"=\"\";\r\
    \n#     \"timeout\"=\"elapsed seconds to consider message expired\";\r\
    \n#     \"ignore\"=\"commands separated with commas\";\r\
    \n#     \"executeNotCommit\"=\"commands separated with commas\";\r\
    \n#     }\r\
    \n#  Using:\r\
    \n#    :local fconfig [:parse [/system script get tg_config source]];\r\
    \n#    :local config [\$fconfig];\r\
    \n#    :put \$config;\r\
    \n########################################################################\
    ##\r\
    \n:local config {\r\
    \n  \"botAPI\"=\"5583145927:AAEhL3ky6wuBY2S0vvAjryFa3VkiQsokzko\";\r\
    \n  \"defaultChatID\"=\"chatid\";\r\
    \n  \"trusted\"=\"153118558\";\r\
    \n  \"storage\"=\"\";\r\
    \n  \"timeout\"=60;\r\
    \n  \"ignore\"=\"shutdown\";\r\
    \n  \"executeNotCommit\"=\"health,add,remove,online\";\r\
    \n}\r\
    \n:put \"<tg_config>: Config----------------------------------------------\
    --\"\r\
    \n:foreach k,v in=\$config do={ :put \"\\t\\\"\$k\\\" = \\\"\$v\\\"\" }\r\
    \n:put \"\\n\"\r\
    \nreturn \$config"
add dont-require-permissions=no name=tg_getUpdates owner=admin policy=read \
    source="##################################################################\
    #######\r\
    \n# getUpdates \97 get updates from Telegram bot and execute commands.\r\
    \n# Available commands\r\
    \n#   coocoo - Invitation message to start\r\
    \n#   wol - WOL menu\r\
    \n#   shutdown - shutdown menu\r\
    \n#   add - Add new computer to manage\r\
    \n#   remove - Remove computer\r\
    \n#\r\
    \n########################################################################\
    #\r\
    \n#flag to prevent duplicate run getUpdate\r\
    \n:global BEINGUPDATED;\r\
    \n:if (any BEINGUPDATED) do={ return; }\r\
    \n:set BEINGUPDATED true;\r\
    \n\r\
    \n#wrapper for /tool fetch\r\
    \n:global fFetch;\r\
    \n#parser for callback\r\
    \n:global fTGcallback;\r\
    \n#parser for command\r\
    \n:global fTGcommand;\r\
    \n#wrapper for sendMessage\r\
    \n:global fTGsend;\r\
    \n#converter Telegram result to msg object\r\
    \n:global fTGresultToMsg;\r\
    \n\r\
    \n#executed messages\r\
    \n:global EXECMSG;\r\
    \n\r\
    \n:local commitUpdate do={\r\
    \n :global fFetch;\r\
    \n \$fFetch url=(\$url.\"&offset=\".((\$msg->\"updateId\")+1))\r\
    \n}\r\
    \n\r\
    \n#get config script and execute it\r\
    \n:local fconfig [:parse [/system script get tg_config source]];\r\
    \n:local cfg [\$fconfig];\r\
    \n\r\
    \n#local variables for params\r\
    \n:local trusted  [:toarray (\$cfg->\"trusted\")];\r\
    \n:local botAPI   (\$cfg->\"botAPI\");\r\
    \n:local storage  (\$cfg->\"storage\");\r\
    \n:local timeout  (\$cfg->\"timeout\");\r\
    \n\r\
    \n\r\
    \n:local logfile (\$storage.\"tg_fetch_log.txt\");\r\
    \n#get messages\r\
    \n:local url (\"https://api.telegram.org/bot\$botAPI/getUpdates\?limit=1\"\
    );\r\
    \n\r\
    \n:put \"Reading updates...\"\r\
    \n\r\
    \n:local result [\$fFetch url=\$url resfile=\$logfile];\r\
    \n:if (any (\$result->\"error\")) do={\r\
    \n  :put \"Error getting updates\";\r\
    \n  :put \$result;\r\
    \n  :set BEINGUPDATED;\r\
    \n  return \"Failed get updates\";\r\
    \n}\r\
    \n:put \"Finished to read updates.\\n\";\r\
    \n\r\
    \n:global JSONLoads;\r\
    \n#parse result\r\
    \n:set \$result ([\$JSONLoads (\$result->\"data\")]->\"result\");\r\
    \n:local timeout (\$cfg->\"timeout\");\r\
    \n#convert to msg\r\
    \n:put \"Converting result to msg...\";\r\
    \n:local msg [\$fTGresultToMsg result=\$result timeout=\$timeout];\r\
    \n\r\
    \n#check for errors\r\
    \n:if (any (\$msg->\"error\")) do={ \r\
    \n  :put \$msg;\r\
    \n  :set BEINGUPDATED;\r\
    \n  return \$msg;\r\
    \n}\r\
    \n\r\
    \n#check if any messages\r\
    \n:if (!any (\$msg->\"messageId\")) do={ \r\
    \n  :put \"No new updates\";\r\
    \n  :set BEINGUPDATED;\r\
    \n  :return {\"info\"=\"no updates\"};\r\
    \n}\r\
    \n\r\
    \n#check if chatId or sender are trusted\r\
    \n:local allowed ( [:type [:find \$trusted (\$msg->\"fromId\")]]!=\"nil\" \
    or \\\r\
    \n                 [:type [:find \$trusted (\$msg->\"chatId\")]]!=\"nil\")\
    \r\
    \n:if (!\$allowed) do={\r\
    \n  :put \"Unknown sender, keep silence\";\r\
    \n  [\$commitUpdate url=\$url msg=\$msg]\r\
    \n  \$fTGsend  chat=(\$msg->\"chatId\") \\\r\
    \n            text=\"You're not allowed to send commands\";\r\
    \n  :set BEINGUPDATED;\r\
    \n  :return {\"error\"=\"You're not allowed to send commands\"};\r\
    \n}\r\
    \n\r\
    \n#check if message is expired\r\
    \n:if ((\$msg->\"expired\")=true) do={\r\
    \n  :set \$EXECMSG;\r\
    \n  [\$commitUpdate url=\$url msg=\$msg]\r\
    \n  # \$fTGsend text=(\"*\".[/system identity get name].\"*%0A\\\r\
    \n  # Command _\".\$msg->\"command\"->\"verb\".\"_ expired and commited.\"\
    ) \\\r\
    \n  #           chat=(\$msg->\"chatId\") \\\r\
    \n  #           mode=\"Markdown\"\r\
    \n  :set BEINGUPDATED;\r\
    \n  return {\r\
    \n    \"info\"=\"Message is expired and commited\";\r\
    \n    \"msg\"=\$msg\r\
    \n    };\r\
    \n}\r\
    \n\r\
    \n#check if message was executed\r\
    \n:local isexecuted [:find \$EXECMSG (\$msg->\"messageId\")];\r\
    \n:if (any isexecuted) do={ \r\
    \n  return {\"info\"=(\"command <\".(\$msg->\"command\"->\"verb\").\"> alr\
    eady executed.\")}\r\
    \n}\r\
    \n\r\
    \n#check if command should be ignored\r\
    \n:local cmdToIgnore [:find (\$cfg->\"ignore\") (\$msg->\"command\"->\"ver\
    b\")];\r\
    \n:if (any \$cmdToIgnore) do={ \r\
    \n  :put (\"Do not commit on <\".(\$msg->\"command\"->\"verb\").\">. Skip \
    it.\");\r\
    \n  :set BEINGUPDATED;\r\
    \n  return {\r\
    \n    \"info\"=\"Ignore command\";\r\
    \n    \"msg\"=\$msg\r\
    \n    };\r\
    \n}\r\
    \n\r\
    \n#trying to run a command\r\
    \n#set script name\r\
    \n:local cmdScript (\$msg->\"command\"->\"script\");\r\
    \n#try to get script by its name\r\
    \n:do {\r\
    \n  :set \$cmdScript [/system script get (\$msg->\"command\"->\"script\") \
    name];\r\
    \n} on-error={:put \"no script \$cmdScript\"}\r\
    \n:if ([:len \$cmdScript]=0) do={\r\
    \n  \$fTGSend  chat=\$chatid \\\r\
    \n            text=(\"No such command *<\".(\$msg->\"command\"->\"verb\").\
    \"*>\") \\\r\
    \n            mode=\"Markdown\";\r\
    \n} else={\r\
    \n  :put \"Try to invoke \$cmdScript\";\r\
    \n  :local script [:parse [/system script get \$cmdScript source]];\r\
    \n  :local cmdResult [\$script \$cmdScript \\\r\
    \n                            params=(\$msg->\"command\"->\"params\") \\\r\
    \n                            chatid=(\$msg->\"chatId\") \\\r\
    \n                            from=(\$msg->\"userName\")];\r\
    \n  :if (any (\$cmdResult->\"error\")) do={ \r\
    \n    \$fTGsend  text=(\$cmdResult->\"error\") \\\r\
    \n              chat=(\$msg->\"chatId\") \\\r\
    \n              mode=\"Markdown\"\r\
    \n  } else={\r\
    \n    :if (any (\$cmdResult->\"info\")) do={ \r\
    \n      \$fTGsend  text=(\$cmdResult->\"info\") \\\r\
    \n                chat=(\$msg->\"chatId\") \\\r\
    \n                mode=\"Markdown\" \\\r\
    \n                replyMarkup=(\$cmdResult->\"replyMarkup\")\r\
    \n    }\r\
    \n  }\r\
    \n}\r\
    \n\r\
    \n#check if command should be commited after execution\r\
    \n:local executeNotCommit [:find (\$cfg->\"executeNotCommit\") (\$msg->\"c\
    ommand\"->\"verb\")];\r\
    \n:if (any \$executeNotCommit) do={ \r\
    \n  :put (\"Do not commit executed <\".(\$msg->\"command\"->\"verb\").\">.\
    \");\r\
    \n  #add executed messages to list in order to not repeat\r\
    \n  :if (\$EXECMSG=(\$msg->\"messageId\")) do={ \r\
    \n    return;\r\
    \n  } else={\r\
    \n    :set \$EXECMSG (\$msg->\"messageId\");\r\
    \n  }\r\
    \n  :set BEINGUPDATED;\r\
    \n  return {\r\
    \n    \"info\"=\"Execute but not commit\";\r\
    \n    \"msg\"=\$msg\r\
    \n    };\r\
    \n}\r\
    \n\r\
    \n:put (\"\\n\\nCommiting message on <\".(\$msg->\"command\"->\"verb\").\"\
    >...\");\r\
    \n\$commitUpdate url=\$url msg=\$msg;\r\
    \n:set BEINGUPDATED;"
add dont-require-permissions=no name=tg_resultToMsg owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_resultToMsg - converts result object to msg\r\
    \n# \r\
    \n#  Input: \r\
    \n#    result \97 result object from Telegram parsed from Json\r\
    \n#    timeout \97 seconds to consider a message expired\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"} on error \r\
    \n#    {\r\
    \n#       \"updateId\"=\"\"; \r\
    \n#       \"messageId\"=\"\"; \r\
    \n#       \"fromId\"=\"\"; \r\
    \n#       \"chatId\"=\"\";\r\
    \n#       \"expired\"=\"\";\r\
    \n#       \"userName\"=\"\";\r\
    \n#       \"firstName\"=\"\";\r\
    \n#       \"lastName\"=\"\";\r\
    \n#       \"text\"=\"\";\r\
    \n#       \"command\"={\"verb\"=\"verb\"; \"script\"=\"scriptName\"; \"par\
    ams\"=\"params\"};\r\
    \n#       \"isCallback\"=\"\";\r\
    \n#    } on success\r\
    \n########################################################################\
    ##\r\
    \n:if (!any \$result) do={ \r\
    \n  return {\"error\"=\"No result object provided\"}\r\
    \n }\r\
    \n:if (!any \$timeout) do={ \r\
    \n  return {\"error\"=\"No timeout provided\"}\r\
    \n }\r\
    \n:put \"<tg_resultToMsg>: Result from Telegram---------------------------\
    --\"\r\
    \n:set \$result (\$result->0);\r\
    \n:put (\"\\t\".[:tostr \$result].\"\\n\");\r\
    \n#local function to get Unix time\r\
    \n:local EpochTime do={\r\
    \n  :local ds [/system clock get date];\r\
    \n  :local months;\r\
    \n  :local isLeap ((([:pick \$ds 9 11]-1)/4) != (([:pick \$ds 9 11])/4));\
    \r\
    \n  :if (\$isLeap) do={\r\
    \n    :set months {\"jan\"=0;\"feb\"=31;\"mar\"=60;\"apr\"=91;\"may\"=121;\
    \"jun\"=152;\"jul\"=182;\"aug\"=213;\"sep\"=244;\"oct\"=274;\"nov\"=305;\"\
    dec\"=335};\r\
    \n  } else={\r\
    \n    :set months {\"jan\"=0;\"feb\"=31;\"mar\"=59;\"apr\"=90;\"may\"=120;\
    \"jun\"=151;\"jul\"=181;\"aug\"=212;\"sep\"=243;\"oct\"=273;\"nov\"=304;\"\
    dec\"=334};\r\
    \n  }\r\
    \n  :local yy [:pick \$ds 9 11];\r\
    \n  :local mmm [:pick \$ds 0 3];\r\
    \n  :local dayOfMonth [:pick \$ds 4 6];\r\
    \n  :local dayOfYear ((\$months->\$mmm)+\$dayOfMonth);\r\
    \n  :local y2k 946684800;\r\
    \n  :set ds ((\$yy*365)+(([:pick \$ds 9 11]-1)/4)+\$dayOfYear);\r\
    \n  :local ts [/system clock get time];\r\
    \n  :local hh [:pick \$ts 0 2];\r\
    \n  :local mm [:pick \$ts 3 5];\r\
    \n  :local ss [:pick \$ts 6 8]\r\
    \n  :set ts ((\$hh*60*60)+(\$mm*60)+\$ss);\r\
    \n  :return (\$ds*24*60*60 + \$ts + y2k - [/system clock get gmt-offset]);\
    \r\
    \n}\r\
    \n\r\
    \n:global fTGcallback;\r\
    \n:global fTGcommand;\r\
    \n:local msg {\r\
    \n  \"updateId\"=\"\"; \r\
    \n  \"messageId\"=\"\"; \r\
    \n  \"fromId\"=\"\"; \r\
    \n  \"chatId\"=\"\";\r\
    \n  \"expired\"=\"\";\r\
    \n  \"userName\"=\"\";\r\
    \n  \"firstName\"=\"\";\r\
    \n  \"lastName\"=\"\";\r\
    \n  \"text\"=\"\";\r\
    \n  \"command\"=[:toarray \"\"];\r\
    \n  \"isCallback\"=\"\";\r\
    \n}\r\
    \n:set (\$msg->\"updateId\") (\$result->\"update_id\");\r\
    \n:set (\$msg->\"isCallback\") (any (\$result->\"callback_query\"));\r\
    \n:local curDate [\$EpochTime];\r\
    \n:local tgDate;\r\
    \n:if (\$msg->\"isCallback\") do={ \r\
    \n  :set \$tgDate (\$result->\"callback_query\"->\"message\"->\"date\");\r\
    \n  :set (\$msg->\"messageId\")  (\$result->\"callback_query\"->\"message\
    \"->\"message_id\");\r\
    \n  :set (\$msg->\"fromId\")     (\$result->\"callback_query\"->\"from\"->\
    \"id\");\r\
    \n  :set (\$msg->\"chatId\")     (\$result->\"callback_query\"->\"message\
    \"->\"chat\"->\"id\");\r\
    \n  :set (\$msg->\"userName\")   (\$result->\"callback_query\"->\"from\"->\
    \"username\");\r\
    \n  :set (\$msg->\"firstName\")  (\$result->\"callback_query\"->\"from\"->\
    \"first_name\");\r\
    \n  :set (\$msg->\"lastName\")   (\$result->\"callback_query\"->\"from\"->\
    \"last_name\");\r\
    \n  :set (\$msg->\"text\")       (\$result->\"callback_query\"->\"message\
    \"->\"text\");\r\
    \n  :set (\$msg->\"command\")    [\$fTGcallback query=(\$result->\"callbac\
    k_query\"->\"data\")];\r\
    \n } else={\r\
    \n  :set \$tgDate (\$result->\"message\"->\"date\");\r\
    \n  :set (\$msg->\"messageId\")  (\$result->\"message\"->\"message_id\");\
    \r\
    \n  :set (\$msg->\"fromId\")     (\$result->\"message\"->\"from\"->\"id\")\
    ;\r\
    \n  :set (\$msg->\"chatId\")     (\$result->\"message\"->\"chat\"->\"id\")\
    ;\r\
    \n  :set (\$msg->\"userName\")   (\$result->\"message\"->\"from\"->\"usern\
    ame\");\r\
    \n  :set (\$msg->\"firstName\")  (\$result->\"message\"->\"from\"->\"first\
    _name\");\r\
    \n  :set (\$msg->\"lastName\")   (\$result->\"message\"->\"from\"->\"last_\
    name\");\r\
    \n  :set (\$msg->\"text\")       (\$result->\"message\"->\"text\");\r\
    \n  :set (\$msg->\"command\")    [\$fTGcommand text=(\$msg->\"text\")];\r\
    \n }\r\
    \n:set (\$msg->\"expired\")    ((\$curDate-\$tgDate)>\$timeout);\r\
    \n:return \$msg;"
add dont-require-permissions=no name=tg_cmd_health owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_cmd_health - get router's state\r\
    \n#  Input: \r\
    \n#     \$1 \97 script name (information only)\r\
    \n#     params \97 no params\r\
    \n#  Output: \r\
    \n#     On error:\r\
    \n#       {\"error\"=\"error message\"}\r\
    \n#     On success:\r\
    \n#       {\"info\"=\"message from message\"} on success\r\
    \n########################################################################\
    ##\r\
    \n:put \"Command \$1 is executing\";\r\
    \n\r\
    \n:local id [/system identity get name];\r\
    \n:local cpu [/system resource get cpu-load];\r\
    \n:local totalRam ([/system resource get total-memory]/(1024*1024));\r\
    \n:local freeRam ([/system resource get free-memory]/(1024*1024));\r\
    \n:local usedRam ((\$totalRam-\$freeRam).\"M\");\r\
    \n:local text \"Router:* \$id * %0A\\\r\
    \nUptime: _\$[/system resource get uptime]_%0A\\\r\
    \nCPU: _\$cpu%25_%0A\\\r\
    \nRAM: _\$usedRam from \$totalRam used_\"\r\
    \n:local v [:pick [/system health get voltage] 0 2];\r\
    \n:if (any v) do={ \r\
    \n  :set \$text (\"%0A\".\$text.\$v.\"V\");\r\
    \n }\r\
    \n:local t [/system health get temperature];\r\
    \n:if (any t) do={ \r\
    \n  :set \$text (\"%0A\".\$text.\$v.\"%C2%B0C\");\r\
    \n }\r\
    \n:return {\"info\"=\$text}"
add dont-require-permissions=no name=tg_cmd_wol owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_cmd_wol - inlinebuttons to WOL PC\r\
    \n# \r\
    \n#  Input: \r\
    \n#     params\r\
    \n      chat\r\
    \n      from\r\
    \n#  Output: \r\
    \n#    -1 on error \r\
    \n#    \"success\" on success\r\
    \n########################################################################\
    ##\r\
    \n#get references to functions from scripts\r\
    \n:local http [:parse [/system script get func_fetch source]];\r\
    \n:local fconfig [:parse [/system script get tg_config source]];\r\
    \n:local send [:parse [/system script get tg_sendMessage source]];\r\
    \n\r\
    \n:global BUTTONS;\r\
    \n:if ([:typeof \$BUTTONS]=\"nothing\") do={ \r\
    \n  \$send text=\"No PCs added. Use menu to add one.\";\r\
    \n        chat=\$chat\r\
    \n  :return -1;\r\
    \n }"
add dont-require-permissions=no name=tg_cmd_coocoo owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #########################################################################\
    \r\
    \n# tg_cmd_coocoo - Init message\r\
    \n#  Input: \r\
    \n#     \$1 \97 script name (information only)\r\
    \n#     params \97 no params for the moment\r\
    \n#  Output: \r\
    \n#     On error:\r\
    \n#       {\"error\"=\"error message\"}\r\
    \n#     On success:\r\
    \n#       {\"info\"=\"message from method\";\"replyMarkup\"=\"inline butto\
    ns markup\"}\r\
    \n########################################################################\
    ##\r\
    \n:put \"Command \$1 is executing\";\r\
    \n:local replaceChar do={\r\
    \n  :for i from=0 to=([:len \$1] - 1) do={\r\
    \n    :local char [:pick \$1 \$i]\r\
    \n    :if (\$char = \$2) do={\r\
    \n      :set \$char \$3\r\
    \n    }\r\
    \n    :set \$output (\$output . \$char)\r\
    \n  }\r\
    \n  :return \$output\r\
    \n}\r\
    \n:local emoji { \\\r\
    \n              \"wol\"=\"%E2%8F%B0\"; \\\r\
    \n              \"shutdown\"=\"%F0%9F%9B%8C\"; \\\r\
    \n              \"health\"=\"%F0%9F%A9%BA\"; \\\r\
    \n              \"online\"=\"%F0%9F%91%80\" \\\r\
    \n              };\r\
    \n                # (\"{\\\"text\\\":\\\"\".(\$emoji->\"health\").\" Healt\
    h\\\",\\\"callback_data\\\":\\\"health\\\"}\") \\\r\
    \n:local buttons { \\\r\
    \n                (\"{\\\"text\\\":\\\"\".(\$emoji->\"wol\").\" Wake up\\\
    \",\\\"callback_data\\\":\\\"menu wol\\\"}\"), \\\r\
    \n                (\"{\\\"text\\\":\\\"\".(\$emoji->\"shutdown\").\" Shutd\
    own\\\",\\\"callback_data\\\":\\\"menu shutdown\\\"}\"), \\\r\
    \n                (\"{\\\"text\\\":\\\"\".(\$emoji->\"online\").\" Who's t\
    here\?\\\",\\\"callback_data\\\":\\\"online\\\"}\"), \\\r\
    \n                (\"{\\\"text\\\":\\\"\".(\$emoji->\"health\").\" \\\",\\\
    \"callback_data\\\":\\\"health\\\"}\") \\\r\
    \n               };\r\
    \n:local inlineButtons [\$replaceChar (\"{\\\"inline_keyboard\\\":[[ \".[:\
    tostr \$buttons].\"]]}\") \";\" \",\" ]\r\
    \n\$fTGsend chat=\$chatid text=\"What to do\?\" mode=\"Markdown\" replyMar\
    kup=\$inlineButtons;\r\
    \n\r\
    \nreturn {\"info\"=\"What to do\?\";\"replyMarkup\"=\$inlineButtons};"
add dont-require-permissions=no name=JParseFunctions owner=admin policy=\
    ftp,reboot,read,write,policy,test source="# ------------------------------\
    -- JParseFunctions ---------------------------------------------------\r\
    \n# ------------------------------- fJParsePrint -------------------------\
    ---------------------------------------\r\
    \n:global fJParsePrint\r\
    \n:if (!any \$fJParsePrint) do={ :global fJParsePrint do={\r\
    \n  :global JParseOut\r\
    \n  :local TempPath\r\
    \n  :global fJParsePrint\r\
    \n\r\
    \n  :if ([:len \$1] = 0) do={\r\
    \n    :set \$1 \"\\\$JParseOut\"\r\
    \n    :set \$2 \$JParseOut\r\
    \n   }\r\
    \n   \r\
    \n  :foreach k,v in=\$2 do={\r\
    \n    :if ([:typeof \$k] = \"str\") do={\r\
    \n      :set k \"\\\"\$k\\\"\"\r\
    \n    }\r\
    \n    :set TempPath (\$1. \"->\" . \$k)\r\
    \n    :if ([:typeof \$v] = \"array\") do={\r\
    \n      :if ([:len \$v] > 0) do={\r\
    \n        \$fJParsePrint \$TempPath \$v\r\
    \n      } else={\r\
    \n        :put \"\$TempPath = [] (\$[:typeof \$v])\"\r\
    \n      }\r\
    \n    } else={\r\
    \n        :put \"\$TempPath = \$v (\$[:typeof \$v])\"\r\
    \n    }\r\
    \n  }\r\
    \n}}\r\
    \n# ------------------------------- fJParsePrintVar ----------------------\
    ------------------------------------------\r\
    \n:global fJParsePrintVar\r\
    \n:if (!any \$fJParsePrintVar) do={ :global fJParsePrintVar do={\r\
    \n  :global JParseOut\r\
    \n  :local TempPath\r\
    \n  :global fJParsePrintVar\r\
    \n  :local fJParsePrintRet \"\"\r\
    \n\r\
    \n  :if ([:len \$1] = 0) do={\r\
    \n    :set \$1 \"\\\$JParseOut\"\r\
    \n    :set \$2 \$JParseOut\r\
    \n   }\r\
    \n   \r\
    \n  :foreach k,v in=\$2 do={\r\
    \n    :if ([:typeof \$k] = \"str\") do={\r\
    \n      :set k \"\\\"\$k\\\"\"\r\
    \n    }\r\
    \n    :set TempPath (\$1. \"->\" . \$k)\r\
    \n    :if (\$fJParsePrintRet != \"\") do={\r\
    \n      :set fJParsePrintRet (\$fJParsePrintRet . \"\\r\\n\")\r\
    \n    }    \r\
    \n    :if ([:typeof \$v] = \"array\") do={\r\
    \n      :if ([:len \$v] > 0) do={\r\
    \n        :set fJParsePrintRet (\$fJParsePrintRet . [\$fJParsePrintVar \$T\
    empPath \$v])\r\
    \n      } else={\r\
    \n        :set fJParsePrintRet (\$fJParsePrintRet . \"\$TempPath = [] (\$[\
    :typeof \$v])\")\r\
    \n      }\r\
    \n    } else={\r\
    \n        :set fJParsePrintRet (\$fJParsePrintRet . \"\$TempPath = \$v (\$\
    [:typeof \$v])\")\r\
    \n    }\r\
    \n  }\r\
    \n  :return \$fJParsePrintRet\r\
    \n}}\r\
    \n# ------------------------------- fJSkipWhitespace ---------------------\
    -------------------------------------------\r\
    \n:global fJSkipWhitespace\r\
    \n:if (!any \$fJSkipWhitespace) do={ :global fJSkipWhitespace do={\r\
    \n  :global Jpos\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :while (\$Jpos < [:len \$JSONIn] and ([:pick \$JSONIn \$Jpos] ~ \"[ \\\
    r\\n\\t]\")) do={\r\
    \n    :set Jpos (\$Jpos + 1)\r\
    \n  }\r\
    \n  :if (\$Jdebug) do={:put \"fJSkipWhitespace: Jpos=\$Jpos Char=\$[:pick \
    \$JSONIn \$Jpos]\"}\r\
    \n}}\r\
    \n# -------------------------------- fJParse -----------------------------\
    ----------------------------------\r\
    \n:global fJParse\r\
    \n:if (!any \$fJParse) do={ :global fJParse do={\r\
    \n  :global Jpos\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :global fJSkipWhitespace\r\
    \n  :local Char\r\
    \n\r\
    \n  :if (!\$1) do={\r\
    \n    :set Jpos 0\r\
    \n   }\r\
    \n  \r\
    \n  \$fJSkipWhitespace\r\
    \n  :set Char [:pick \$JSONIn \$Jpos]\r\
    \n  :if (\$Jdebug) do={:put \"fJParse: Jpos=\$Jpos Char=\$Char\"}\r\
    \n  :if (\$Char=\"{\") do={\r\
    \n    :set Jpos (\$Jpos + 1)\r\
    \n    :global fJParseObject\r\
    \n    :return [\$fJParseObject]\r\
    \n  } else={\r\
    \n    :if (\$Char=\"[\") do={\r\
    \n      :set Jpos (\$Jpos + 1)\r\
    \n      :global fJParseArray\r\
    \n      :return [\$fJParseArray]\r\
    \n    } else={\r\
    \n      :if (\$Char=\"\\\"\") do={\r\
    \n        :set Jpos (\$Jpos + 1)\r\
    \n        :global fJParseString\r\
    \n        :return [\$fJParseString]\r\
    \n      } else={\r\
    \n#        :if ([:pick \$JSONIn \$Jpos (\$Jpos+2)]~\"^-\\\?[0-9]\") do={\r\
    \n        :if (\$Char~\"[eE0-9.+-]\") do={\r\
    \n          :global fJParseNumber\r\
    \n          :return [\$fJParseNumber]\r\
    \n        } else={\r\
    \n\r\
    \n          :if (\$Char=\"n\" and [:pick \$JSONIn \$Jpos (\$Jpos+4)]=\"nul\
    l\") do={\r\
    \n            :set Jpos (\$Jpos + 4)\r\
    \n            :return []\r\
    \n          } else={\r\
    \n            :if (\$Char=\"t\" and [:pick \$JSONIn \$Jpos (\$Jpos+4)]=\"t\
    rue\") do={\r\
    \n              :set Jpos (\$Jpos + 4)\r\
    \n              :return true\r\
    \n            } else={\r\
    \n              :if (\$Char=\"f\" and [:pick \$JSONIn \$Jpos (\$Jpos+5)]=\
    \"false\") do={\r\
    \n                :set Jpos (\$Jpos + 5)\r\
    \n                :return false\r\
    \n              } else={\r\
    \n                :put \"Err.Raise 8732. No JSON object could be fJParseed\
    \"\r\
    \n                :set Jpos (\$Jpos + 1)\r\
    \n                :return []\r\
    \n              }\r\
    \n            }\r\
    \n          }\r\
    \n        }\r\
    \n      }\r\
    \n    }\r\
    \n  }\r\
    \n}}\r\
    \n\r\
    \n#-------------------------------- fJParseString ------------------------\
    ---------------------------------------\r\
    \n:global fJParseString\r\
    \n:if (!any \$fJParseString) do={ :global fJParseString do={\r\
    \n  :global Jpos\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :global fUnicodeToUTF8\r\
    \n  :local Char\r\
    \n  :local StartIdx\r\
    \n  :local Char2\r\
    \n  :local TempString \"\"\r\
    \n  :local UTFCode\r\
    \n  :local Unicode\r\
    \n\r\
    \n  :set StartIdx \$Jpos\r\
    \n  :set Char [:pick \$JSONIn \$Jpos]\r\
    \n  :if (\$Jdebug) do={:put \"fJParseString: Jpos=\$Jpos Char=\$Char\"}\r\
    \n  :while (\$Jpos < [:len \$JSONIn] and \$Char != \"\\\"\") do={\r\
    \n    :if (\$Char=\"\\\\\") do={\r\
    \n      :set Char2 [:pick \$JSONIn (\$Jpos + 1)]\r\
    \n      :if (\$Char2 = \"u\") do={\r\
    \n        :set UTFCode [:tonum \"0x\$[:pick \$JSONIn (\$Jpos+2) (\$Jpos+6)\
    ]\"]\r\
    \n        :if (\$UTFCode>=0xD800 and \$UTFCode<=0xDFFF) do={\r\
    \n# Surrogate pair\r\
    \n          :set Unicode  ((\$UTFCode & 0x3FF) << 10)\r\
    \n          :set UTFCode [:tonum \"0x\$[:pick \$JSONIn (\$Jpos+8) (\$Jpos+\
    12)]\"]\r\
    \n          :set Unicode (\$Unicode | (\$UTFCode & 0x3FF) | 0x10000)\r\
    \n          :set TempString (\$TempString . [:pick \$JSONIn \$StartIdx \$J\
    pos] . [\$fUnicodeToUTF8 \$Unicode])         \r\
    \n          :set Jpos (\$Jpos + 12)\r\
    \n        } else= {\r\
    \n# Basic Multilingual Plane (BMP)\r\
    \n          :set Unicode \$UTFCode\r\
    \n          :set TempString (\$TempString . [:pick \$JSONIn \$StartIdx \$J\
    pos] . [\$fUnicodeToUTF8 \$Unicode])\r\
    \n          :set Jpos (\$Jpos + 6)\r\
    \n        }\r\
    \n        :set StartIdx \$Jpos\r\
    \n        :if (\$Jdebug) do={:put \"fJParseString Unicode: \$Unicode\"}\r\
    \n      } else={\r\
    \n        :if (\$Char2 ~ \"[\\\\bfnrt\\\"]\") do={\r\
    \n          :if (\$Jdebug) do={:put \"fJParseString escape: Char+Char2 \$C\
    har\$Char2\"}\r\
    \n          :set TempString (\$TempString . [:pick \$JSONIn \$StartIdx \$J\
    pos] . [[:parse \"(\\\"\\\\\$Char2\\\")\"]])\r\
    \n          :set Jpos (\$Jpos + 2)\r\
    \n          :set StartIdx \$Jpos\r\
    \n        } else={\r\
    \n          :if (\$Char2 = \"/\") do={\r\
    \n            :if (\$Jdebug) do={:put \"fJParseString /: Char+Char2 \$Char\
    \$Char2\"}\r\
    \n            :set TempString (\$TempString . [:pick \$JSONIn \$StartIdx \
    \$Jpos] . \"/\")\r\
    \n            :set Jpos (\$Jpos + 2)\r\
    \n            :set StartIdx \$Jpos\r\
    \n          } else={\r\
    \n            :put \"Err.Raise 8732. Invalid escape\"\r\
    \n            :set Jpos (\$Jpos + 2)\r\
    \n          }\r\
    \n        }\r\
    \n      }\r\
    \n    } else={\r\
    \n      :set Jpos (\$Jpos + 1)\r\
    \n    }\r\
    \n    :set Char [:pick \$JSONIn \$Jpos]\r\
    \n  }\r\
    \n  :set TempString (\$TempString . [:pick \$JSONIn \$StartIdx \$Jpos])\r\
    \n  :set Jpos (\$Jpos + 1)\r\
    \n  :if (\$Jdebug) do={:put \"fJParseString: \$TempString\"}\r\
    \n  :return \$TempString\r\
    \n}}\r\
    \n\r\
    \n#-------------------------------- fJParseNumber ------------------------\
    ---------------------------------------\r\
    \n:global fJParseNumber\r\
    \n:if (!any \$fJParseNumber) do={ :global fJParseNumber do={\r\
    \n  :global Jpos\r\
    \n  :local StartIdx\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :local NumberString\r\
    \n  :local Number\r\
    \n\r\
    \n  :set StartIdx \$Jpos   \r\
    \n  :set Jpos (\$Jpos + 1)\r\
    \n  :while (\$Jpos < [:len \$JSONIn] and [:pick \$JSONIn \$Jpos]~\"[eE0-9.\
    +-]\") do={\r\
    \n    :set Jpos (\$Jpos + 1)\r\
    \n  }\r\
    \n  :set NumberString [:pick \$JSONIn \$StartIdx \$Jpos]\r\
    \n  :set Number [:tonum \$NumberString] \r\
    \n  :if ([:typeof \$Number] = \"num\") do={\r\
    \n    :if (\$Jdebug) do={:put \"fJParseNumber: StartIdx=\$StartIdx Jpos=\$\
    Jpos \$Number (\$[:typeof \$Number])\"}\r\
    \n    :return \$Number\r\
    \n  } else={\r\
    \n    :if (\$Jdebug) do={:put \"fJParseNumber: StartIdx=\$StartIdx Jpos=\$\
    Jpos \$NumberString (\$[:typeof \$NumberString])\"}\r\
    \n    :return \$NumberString\r\
    \n  }\r\
    \n}}\r\
    \n\r\
    \n#-------------------------------- fJParseArray -------------------------\
    --------------------------------------\r\
    \n:global fJParseArray\r\
    \n:if (!any \$fJParseArray) do={ :global fJParseArray do={\r\
    \n  :global Jpos\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :global fJParse\r\
    \n  :global fJSkipWhitespace\r\
    \n  :local Value\r\
    \n  :local ParseArrayRet [:toarray \"\"]\r\
    \n  \r\
    \n  \$fJSkipWhitespace    \r\
    \n  :while (\$Jpos < [:len \$JSONIn] and [:pick \$JSONIn \$Jpos]!= \"]\") \
    do={\r\
    \n    :set Value [\$fJParse true]\r\
    \n    :set (\$ParseArrayRet->([:len \$ParseArrayRet])) \$Value\r\
    \n    :if (\$Jdebug) do={:put \"fJParseArray: Value=\"; :put \$Value}\r\
    \n    \$fJSkipWhitespace\r\
    \n    :if ([:pick \$JSONIn \$Jpos] = \",\") do={\r\
    \n      :set Jpos (\$Jpos + 1)\r\
    \n      \$fJSkipWhitespace\r\
    \n    }\r\
    \n  }\r\
    \n  :set Jpos (\$Jpos + 1)\r\
    \n#  :if (\$Jdebug) do={:put \"ParseArrayRet: \"; :put \$ParseArrayRet}\r\
    \n  :return \$ParseArrayRet\r\
    \n}}\r\
    \n\r\
    \n# -------------------------------- fJParseObject -----------------------\
    ----------------------------------------\r\
    \n:global fJParseObject\r\
    \n:if (!any \$fJParseObject) do={ :global fJParseObject do={\r\
    \n  :global Jpos\r\
    \n  :global JSONIn\r\
    \n  :global Jdebug\r\
    \n  :global fJSkipWhitespace\r\
    \n  :global fJParseString\r\
    \n  :global fJParse\r\
    \n# Syntax :local ParseObjectRet ({}) don't work in recursive call, use [:\
    toarray \"\"] for empty array!!!\r\
    \n  :local ParseObjectRet [:toarray \"\"]\r\
    \n  :local Key\r\
    \n  :local Value\r\
    \n  :local ExitDo false\r\
    \n  \r\
    \n  \$fJSkipWhitespace\r\
    \n  :while (\$Jpos < [:len \$JSONIn] and [:pick \$JSONIn \$Jpos]!=\"}\" an\
    d !\$ExitDo) do={\r\
    \n    :if ([:pick \$JSONIn \$Jpos]!=\"\\\"\") do={\r\
    \n      :put \"Err.Raise 8732. Expecting property name\"\r\
    \n      :set ExitDo true\r\
    \n    } else={\r\
    \n      :set Jpos (\$Jpos + 1)\r\
    \n      :set Key [\$fJParseString]\r\
    \n      \$fJSkipWhitespace\r\
    \n      :if ([:pick \$JSONIn \$Jpos] != \":\") do={\r\
    \n        :put \"Err.Raise 8732. Expecting : delimiter\"\r\
    \n        :set ExitDo true\r\
    \n      } else={\r\
    \n        :set Jpos (\$Jpos + 1)\r\
    \n        :set Value [\$fJParse true]\r\
    \n        :set (\$ParseObjectRet->\$Key) \$Value\r\
    \n        :if (\$Jdebug) do={:put \"fJParseObject: Key=\$Key Value=\"; :pu\
    t \$Value}\r\
    \n        \$fJSkipWhitespace\r\
    \n        :if ([:pick \$JSONIn \$Jpos]=\",\") do={\r\
    \n          :set Jpos (\$Jpos + 1)\r\
    \n          \$fJSkipWhitespace\r\
    \n        }\r\
    \n      }\r\
    \n    }\r\
    \n  }\r\
    \n  :set Jpos (\$Jpos + 1)\r\
    \n#  :if (\$Jdebug) do={:put \"ParseObjectRet: \"; :put \$ParseObjectRet}\
    \r\
    \n  :return \$ParseObjectRet\r\
    \n}}\r\
    \n\r\
    \n# ------------------- fByteToEscapeChar ----------------------\r\
    \n:global fByteToEscapeChar\r\
    \n:if (!any \$fByteToEscapeChar) do={ :global fByteToEscapeChar do={\r\
    \n#  :set \$1 [:tonum \$1]\r\
    \n  :return [[:parse \"(\\\"\\\\\$[:pick \"0123456789ABCDEF\" ((\$1 >> 4) \
    & 0xF)]\$[:pick \"0123456789ABCDEF\" (\$1 & 0xF)]\\\")\"]]\r\
    \n}}\r\
    \n\r\
    \n# ------------------- fUnicodeToUTF8----------------------\r\
    \n:global fUnicodeToUTF8\r\
    \n:if (!any \$fUnicodeToUTF8) do={ :global fUnicodeToUTF8 do={\r\
    \n  :global fByteToEscapeChar\r\
    \n#  :local Ubytes [:tonum \$1]\r\
    \n  :local Nbyte\r\
    \n  :local EscapeStr \"\"\r\
    \n\r\
    \n  :if (\$1 < 0x80) do={\r\
    \n    :set EscapeStr [\$fByteToEscapeChar \$1]\r\
    \n  } else={\r\
    \n    :if (\$1 < 0x800) do={\r\
    \n      :set Nbyte 2\r\
    \n    } else={  \r\
    \n      :if (\$1 < 0x10000) do={\r\
    \n        :set Nbyte 3\r\
    \n      } else={\r\
    \n        :if (\$1 < 0x20000) do={\r\
    \n          :set Nbyte 4\r\
    \n        } else={\r\
    \n          :if (\$1 < 0x4000000) do={\r\
    \n            :set Nbyte 5\r\
    \n          } else={\r\
    \n            :if (\$1 < 0x80000000) do={\r\
    \n              :set Nbyte 6\r\
    \n            }\r\
    \n          }\r\
    \n        }\r\
    \n      }\r\
    \n    }\r\
    \n    :for i from=2 to=\$Nbyte do={\r\
    \n      :set EscapeStr ([\$fByteToEscapeChar (\$1 & 0x3F | 0x80)] . \$Esca\
    peStr)\r\
    \n      :set \$1 (\$1 >> 6)\r\
    \n    }\r\
    \n    :set EscapeStr ([\$fByteToEscapeChar (((0xFF00 >> \$Nbyte) & 0xFF) |\
    \_\$1)] . \$EscapeStr)\r\
    \n  }\r\
    \n  :return \$EscapeStr\r\
    \n}}\r\
    \n\r\
    \n# ------------------- Load JSON from arg -------------------------------\
    -\r\
    \nglobal JSONLoads\r\
    \nif (!any \$JSONLoads) do={ global JSONLoads do={\r\
    \n    global JSONIn \$1\r\
    \n    global fJParse\r\
    \n    local ret [\$fJParse]\r\
    \n    set JSONIn\r\
    \n    global Jpos; set Jpos\r\
    \n    global Jdebug; if (!\$Jdebug) do={set Jdebug}\r\
    \n    return \$ret\r\
    \n}}\r\
    \n\r\
    \n# ------------------- Load JSON from file ------------------------------\
    --\r\
    \nglobal JSONLoad\r\
    \nif (!any \$JSONLoad) do={ global JSONLoad do={\r\
    \n    if ([len [/file find name=\$1]] > 0) do={\r\
    \n        global JSONLoads\r\
    \n        return [\$JSONLoads [/file get \$1 contents]]\r\
    \n    }\r\
    \n}}\r\
    \n\r\
    \n# ------------------- Unload JSON parser library ----------------------\
    \r\
    \nglobal JSONUnload\r\
    \nif (!any \$JSONUnload) do={ global JSONUnload do={\r\
    \n    global JSONIn; set JSONIn\r\
    \n    global Jpos; set Jpos\r\
    \n    global Jdebug; set Jdebug\r\
    \n    global fByteToEscapeChar; set fByteToEscapeChar\r\
    \n    global fJParse; set fJParse\r\
    \n    global fJParseArray; set fJParseArray\r\
    \n    global fJParseNumber; set fJParseNumber\r\
    \n    global fJParseObject; set fJParseObject\r\
    \n    global fJParsePrint; set fJParsePrint\r\
    \n    global fJParsePrintVar; set fJParsePrintVar\r\
    \n    global fJParseString; set fJParseString\r\
    \n    global fJSkipWhitespace; set fJSkipWhitespace\r\
    \n    global fUnicodeToUTF8; set fUnicodeToUTF8\r\
    \n    global JSONLoads; set JSONLoads\r\
    \n    global JSONLoad; set JSONLoad\r\
    \n    global JSONUnload; set JSONUnload\r\
    \n}}\r\
    \n# ------------------- End JParseFunctions----------------------"
add dont-require-permissions=no name=tg_cmd_wolByName owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #########################################################################\
    \r\
    \n# tg_cmd_wolByName - WakeOnLan by hostname\r\
    \n#  Input: \r\
    \n#     \$1 \97 script name (information only)\r\
    \n#     params \97 hostname to Wake-On-LAN\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"} on error \r\
    \n#    {\"info\"=\"Method message to send to chat\"}\"success\" on success\
    \r\
    \n########################################################################\
    ##\r\
    \n:put \"Command \$1 is executing\";\r\
    \n:local hostname \$params;\r\
    \n#get mac from dhcp lease\r\
    \n:local mac ([/ip dhcp-server lease print as-value where host-name=\$host\
    name]->0->\"mac-address\");\r\
    \n:if ([:typeof \$mac]=\"nothing\") do={ \r\
    \n  #no mac in dhcp lease. Try dns static\r\
    \n  :local ip ([/ip dns static print as-value where name=\$hostname]->0->\
    \"address\");\r\
    \n  :set \$mac ([/ip arp print as-value where address=\$ip]->0->\"mac-addr\
    ess\")\r\
    \n  :if ([:typeof \$mac]=\"nothing\") do={\r\
    \n    :return {\"error\"=\"*<\$hostname>* is not found neither in dhcp lea\
    se no in dns static\"} ;\r\
    \n  }\r\
    \n}\r\
    \n#get interface from arp\r\
    \n:local ifc \"bridge\";\r\
    \n:local macs [/ip arp print as-value where mac-address=\$mac];\r\
    \n:if ([:len \$macs]!=0) do={ \r\
    \n  :set \$ifc (\$macs->0->\"interface\");\r\
    \n }\r\
    \n\r\
    \n/tool wol mac=\$mac interface=\$ifc;\r\
    \n:return {\"info\"=\"*<\$hostname>* is waked up!\"};"
add dont-require-permissions=no name=tg_cmd_shutdown owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_cmd_shutdown - inlinebuttons to shutdown PC\r\
    \n# \r\
    \n#  Input: \r\
    \n#     none\r\
    \n#  Output: \r\
    \n#    -1 on error \r\
    \n#    \"success\" on success\r\
    \n########################################################################\
    ##"
add dont-require-permissions=no name=TelegramBotFunctions owner=admin policy=\
    ftp,reboot,read,write,policy,test source="################################\
    ##########################################\r\
    \n# TelegramBotFunctions - defines functions for using with polling Telegr\
    am-bot\r\
    \n# \r\
    \n#  Input: \r\
    \n#     none\r\
    \n#  Output: \r\
    \n#    functions as global variables\r\
    \n#    \r\
    \n########################################################################\
    ##\r\
    \n########################################################################\
    ##\r\
    \n# fTGcallback - function for processing callback from inlinebutton.\r\
    \n# See tg_callback.rsc for implemetation\r\
    \n########################################################################\
    ##\r\
    \n:global fTGcallback;\r\
    \n:if (!any fTGcallback) do={ :global fTGcallback {\r\
    \n  :local callback [:parse [/system script get tg_callback source]];\r\
    \n  \$callback query=\$query;\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fTGcommand - function for processing command in message text. Command\
    \r\
    \n# must start with /. May be followed with parameters separated with spac\
    es.\r\
    \n# See tg_command.rsc for implemetation\r\
    \n########################################################################\
    ##\r\
    \n:global fTGcommand;\r\
    \n:if (!any fTGcommand) do={ :global fTGcommand {\r\
    \n  :local command [:parse [/system script get tg_command source]];\r\
    \n  \$command text=\$text;\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fTGsend - function for sending messages\r\
    \n# See tg_send.rsc for implemetation\r\
    \n########################################################################\
    ##\r\
    \n:global fTGsend;\r\
    \n:if (!any fTGsend) do={ :global fTGsend {\r\
    \n  :local send [:parse [/system script get tg_send source]];\r\
    \n  \$send chat=\$chat text=\$text mode=\$mode replyMarkup=\$replyMarkup\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fTGgetUpdates - getting updates and execute commands\r\
    \n# See tg_getUpdates.rsc for implementation\r\
    \n########################################################################\
    ##\r\
    \n:global fTGgetUpdates;\r\
    \n:if (!any \$fTGgetUpdates) do={ :global fTGgetUpdates {\r\
    \n  :local getUpdtates [:parse [/system script get tg_getUpdates source]]\
    \r\
    \n  \$getUpdates;\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fTGresultToMsg - converts result object to msg\r\
    \n# See tg_resultToMsg.rsc for implementation\r\
    \n########################################################################\
    ##\r\
    \n:global fTGresultToMsg;\r\
    \n:if (!any \$fTGresultToMsg) do={ :global fTGresultToMsg {\r\
    \n  :local resultToMsg [:parse [/system script get tg_resultToMsg source]]\
    ;\r\
    \n  \$resultToMsg result=\$result timeout=\$timeout;\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fFetch - Wrapper for /tools fetch\r\
    \n# \r\
    \n#  Input:\r\
    \n#    mode\r\
    \n#    upload=yes/no\r\
    \n#    user\r\
    \n#    password\r\
    \n#    address\r\
    \n#    host\r\
    \n#    httpdata\r\
    \n#    httpmethod\r\
    \n#    check-certificate\r\
    \n#    src-path\r\
    \n#    dst-path\r\
    \n#    ascii=yes/no\r\
    \n#    url\r\
    \n#    resfile\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"}\r\
    \n#    {\"data\"=array; \"downloaded\"=num; \"status\"=string}\r\
    \n########################################################################\
    ##\r\
    \n:global fFetch;\r\
    \n:if (!any fFetch) do={ :global fFetch do={\r\
    \n  :local res \"fetchresult.txt\"\r\
    \n  :if ([:len \$resfile]>0) do={:set res \$resfile}\r\
    \n\r\
    \n  :local cmd \"/tool fetch\"\r\
    \n  :if ([:len \$mode]>0) do={:set cmd \"\$cmd mode=\$mode\"}\r\
    \n  :if ([:len \$upload]>0) do={:set cmd \"\$cmd upload=\$upload\"}\r\
    \n  :if ([:len \$user]>0) do={:set cmd \"\$cmd user=\\\"\$user\\\"\"}\r\
    \n  :if ([:len \$password]>0) do={:set cmd \"\$cmd password=\\\"\$password\
    \\\"\"}\r\
    \n  :if ([:len \$address]>0) do={:set cmd \"\$cmd address=\\\"\$address\\\
    \"\"}\r\
    \n  :if ([:len \$host]>0) do={:set cmd \"\$cmd host=\\\"\$host\\\"\"}\r\
    \n  :if ([:len \$\"http-data\"]>0) do={:set cmd \"\$cmd http-data=\\\"\$\"\
    http-data\"\\\"\"}\r\
    \n  :if ([:len \$\"http-method\"]>0) do={:set cmd \"\$cmd http-method=\\\"\
    \$\"http-method\"\\\"\"}\r\
    \n  :if ([:len \$\"check-certificate\"]>0) do={:set cmd \"\$cmd check-cert\
    ificate=\\\"\$\"check-certificate\"\\\"\"}\r\
    \n  :if ([:len \$\"src-path\"]>0) do={:set cmd \"\$cmd src-path=\\\"\$\"sr\
    c-path\"\\\"\"}\r\
    \n  :if ([:len \$\"dst-path\"]>0) do={:set cmd \"\$cmd dst-path=\\\"\$\"ds\
    t-path\"\\\"\"}\r\
    \n  :if ([:len \$ascii]>0) do={:set cmd \"\$cmd ascii=\\\"\$ascii\\\"\"}\r\
    \n  :if ([:len \$url]>0) do={:set cmd \"\$cmd url=\\\"\$url\\\"\"}\r\
    \n\r\
    \n  :set \$cmd \"\$cmd output=user as-value\"\r\
    \n  :put \">> \$cmd\"\r\
    \n\r\
    \n  :global FETCHRESULT\r\
    \n  :set \$FETCHRESULT [:toarray \"\"];\r\
    \n\r\
    \n  :local script \":global FETCHRESULT [:toarray \\\"\\\"];\r\
    \n  :do {\r\
    \n    :set FETCHRESULT [\$cmd];\r\
    \n  } on-error={\r\
    \n    :set FETCHRESULT {\\\"error\\\"=\\\"failed\\\"};\r\
    \n  }\"\r\
    \n  :execute script=\$script file=\$res\r\
    \n  :local cnt 0\r\
    \n  :while (\$cnt<100 and ([:len \$FETCHRESULT]=0)) do={ \r\
    \n    :delay 1s\r\
    \n    :set \$cnt (\$cnt+1)\r\
    \n  }\r\
    \n  :local result \$FETCHRESULT;\r\
    \n  # :set \$FETCHRESULT;\r\
    \n  \r\
    \n  :return \$result;\r\
    \n} }\r\
    \n\r\
    \n########################################################################\
    ##\r\
    \n# fTGclear - clears global functions related to Telegram\r\
    \n# \r\
    \n#  Input: \r\
    \n#    none\r\
    \n#  Output: \r\
    \n#    none\r\
    \n########################################################################\
    ##\r\
    \n:global fTGclear;\r\
    \n:if (!any \$fTGclear) do={ :global fTGclear do={\r\
    \n  :global fFetch;\r\
    \n  :set fFetch;\r\
    \n  :global fTGcallback;\r\
    \n  :set fTGcallback;\r\
    \n  :global fTGcommand;\r\
    \n  :set fTGcommand;\r\
    \n  :global fTGgetUpdates;\r\
    \n  :set fTGgetUpdates;\r\
    \n  :global fTGsend;\r\
    \n  :set fTGsend;\r\
    \n  :global fTGresultToMsg;\r\
    \n  :set fTGresultToMsg;\r\
    \n}}"
add dont-require-permissions=no name=Refresh owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    global fTGclear;\r\
    \n\$fTGclear;\r\
    \n/system script run TelegramBotFunctions;"
add dont-require-permissions=no name=tg_callback owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #########################################################################\
    \r\
    \n# fTGcallback - function for processing callback from inlinebutton.\r\
    \n# then consider first word as command and the rest as parameters\r\
    \n#  Input: \r\
    \n#     query - callback_query->data object from message\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"} on error \r\
    \n#    {\"verb\"=\"verb\"; \"script\"=\"scriptName\"; \"params\"=\"params\
    \"}\r\
    \n########################################################################\
    ##\r\
    \n  :local command {\"verb\"=\"\"; \"script\"=\"\"; \"params\"=\"\"};\r\
    \n  #find position of first whitespace\r\
    \n  :local pos [:find \$query \" \"];\r\
    \n  :if ([:type \$pos]=\"nil\") do={\r\
    \n    #no spaces.\r\
    \n    :set (\$command->\"verb\") \$query;\r\
    \n    :set (\$command->\"script\") (\"tg_cmd_\".(\$command->\"verb\"));\r\
    \n    :return \$command;\r\
    \n  }\r\
    \n  #There are spaces\r\
    \n  :set (\$command->\"verb\") [:pick \$query 0 \$pos];\r\
    \n  :set (\$command->\"script\") (\"tg_cmd_\".(\$command->\"verb\"));\r\
    \n  :set (\$command->\"params\") [:pick \$query (\$pos+1) [:len \$query]];\
    \r\
    \n  :return \$command;"
add dont-require-permissions=no name=tg_command owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #########################################################################\
    \r\
    \n#   fTGcommand - function for processing command in message text. Comman\
    d\r\
    \n# must start with /. May be followed with parameters separated with spac\
    es.\r\
    \n#  Input: \r\
    \n#     text - text from Telegram-message\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"} on error \r\
    \n#    {\"verb\"=\"verb\"; \"script\"=\"scriptName\"; \"params\"=\"params\
    \"}\r\
    \n########################################################################\
    ##\r\
    \n:local command {\"verb\"=\"\"; \"script\"=\"\"; \"params\"=\"\"};\r\
    \n#Check if this is real command, i.e. start with /\r\
    \n:if ([:pick \$text 0]!=\"/\") do={\r\
    \n  :return {\"error\"=\"\$text is not a command. Not started with /\"};\r\
    \n}\r\
    \n\r\
    \n#find position of first whitespace\r\
    \n:local pos [:find \$text \" \"];\r\
    \n#Trim first symbol\r\
    \n:set \$text [:pick \$text 1 [:len \$text]];\r\
    \n#set command name\r\
    \n:if ([:type \$pos]=\"nil\") do={\r\
    \n  #no spaces. Set script name\r\
    \n  :set (\$command->\"verb\") \$text;\r\
    \n  :set (\$command->\"script\") (\"tg_cmd_\".(\$command->\"verb\"));\r\
    \n  :return \$command;\r\
    \n}\r\
    \n#ok. There are spaces\r\
    \n:local params [:pick \$text (\$pos+1) [:len \$text]];\r\
    \n:set (\$command->\"verb\") [:pick \$text 1 \$pos];\r\
    \n:set (\$command->\"script\") (\"tg_cmd_\".(\$command->\"verb\"));\r\
    \n:set (\$command->\"params\") \$params;\r\
    \n:return \$command;"
add dont-require-permissions=no name=tg_send owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    #########################################################################\
    \r\
    \n# fTGsend - function for sending messages\r\
    \n# \r\
    \n#  Input: \r\
    \n#    chat - if none send to default chat \r\
    \n#    text - text to send\r\
    \n#    mode - empty or Markdown/HTML\r\
    \n#    replyMarkup \97 inline keyboard content if any\r\
    \n#  Output: \r\
    \n#    {\"error\"=\"error message\"} on error \r\
    \n#    {\"success\"=\"true\"; \"reply\"=\"reply text\"} on success\r\
    \n########################################################################\
    ##\r\
    \n:local fconfig [:parse [/system script get tg_config source]]\r\
    \n\r\
    \n:local cfg [\$fconfig]\r\
    \n:local chatID (\$cfg->\"defaultChatID\")\r\
    \n:local botID (\$cfg->\"botAPI\")\r\
    \n:local storage (\$cfg->\"storage\")\r\
    \n\r\
    \n:if (any \$chat) do={:set chatID \$chat}\r\
    \n\r\
    \n:local url \"https://api.telegram.org/bot\$botID/sendmessage\\\?chat_id=\
    \$chatID&text=\$text\"\r\
    \n:if (any \$mode) do={\r\
    \n  :set url (\$url.\"&parse_mode=\$mode\");\r\
    \n}\r\
    \n:if (any \$replyMarkup) do={\r\
    \n  :set url (\$url.\"&reply_markup=\$replyMarkup\");\r\
    \n}\r\
    \n:local file ((\$cfg->\"storage\").\"tg_send_msgs.txt\");\r\
    \n:local logfile ((\$cfg->\"storage\").\"tg_send_log.txt\");\r\
    \n:put (\"url = \$url\");\r\
    \n:local reply ([/tool fetch url=\$url output=user as-value ]->\"data\")\r\
    \n# /tool fetch url=\$url keep-result=no\r\
    \n:return {\"success\"=\"true\";\"reply\"=\$reply}"
add dont-require-permissions=no name=tg_cmd_menu owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_cmd_menu - Send menu\r\
    \n#  Input: \r\
    \n#     \$1 \97 script name (information only)\r\
    \n#     params \97 menu to be shown. One of: {wol, shutdown}\r\
    \n#  Output: \r\
    \n#     On error:      \r\
    \n#       {\"error\"=\"error message\"}\r\
    \n#     On success:\r\
    \n#       {\"info\"=\"message from method\";\"replyMarkup\"=\"inline butto\
    ns markup\"}\r\
    \n########################################################################\
    ##\r\
    \n:put \"Command \$1 is executing\";\r\
    \n:local emoji { \\\r\
    \n              \"pc\"=\"%F0%9F%92%BB\";\r\
    \n              }\r\
    \n:local replaceChar do={\r\
    \n  :for i from=0 to=([:len \$1] - 1) do={\r\
    \n    :local char [:pick \$1 \$i]\r\
    \n    :if (\$char = \$2) do={\r\
    \n      :set \$char \$3\r\
    \n    }\r\
    \n    :set \$output (\$output . \$char)\r\
    \n  }\r\
    \n  :return \$output\r\
    \n}\r\
    \n# :global fTGsend;\r\
    \n:local buttons { \\\r\
    \n                \"wol\"={\r\
    \n                  \"{\\\"text\\\":\\\"\".(\$emoji->\"pc\").\" Miner\\\",\
    \\\"callback_data\\\":\\\"wolByName sic-chief-631\\\"}\", \\\r\
    \n                  \"{\\\"text\\\":\\\"\".(\$emoji->\"pc\").\" Nimble Bel\
    l\\\",\\\"callback_data\\\":\\\"wolByName PC2\\\"}\" \\\r\
    \n                };\r\
    \n                \"shutdown\"={\r\
    \n                  \"{\\\"text\\\":\\\"\".(\$emoji->\"pc\").\" Miner\\\",\
    \\\"callback_data\\\":\\\"shutdown sic-chief-631\\\"}\", \\\r\
    \n                  \"{\\\"text\\\":\\\"\".(\$emoji->\"pc\").\" Nimble Bel\
    l\\\",\\\"callback_data\\\":\\\"shutdown VM-BOT-TEST\\\"}\" \\\r\
    \n                }\r\
    \n               };\r\
    \n:put \$buttons;\r\
    \n:local inlineButtons [\$replaceChar (\"{\\\"inline_keyboard\\\":[[ \".[:\
    tostr (\$buttons->\$params)].\"]]}\") \";\" \",\" ]\r\
    \n:put \$inlineButtons;\r\
    \nreturn {\"info\"=\"Select PC\";\"replyMarkup\"=\$inlineButtons};\r\
    \n"
add dont-require-permissions=yes name=Startup owner=admin policy=\
    ftp,reboot,read,write,policy,test source="/system script run JParseFunctio\
    ns\r\
    \n/system script run TelegramBotFunctions"
add dont-require-permissions=no name=tg_cmd_online owner=admin policy=read \
    source="##################################################################\
    ########\r\
    \n# tg_cmd_online - To see who's online\r\
    \n#  Input: \r\
    \n#     \$1 \97 script name (information only)\r\
    \n#     params \97 no params for the moment\r\
    \n#  Output: \r\
    \n#     On error:\r\
    \n#       {\"error\"=\"error message\"}\r\
    \n#     On success:\r\
    \n#       {\"info\"=\"message from method\"}\r\
    \n########################################################################\
    ##\r\
    \n:put \"Command \$1 is executing\";\r\
    \nreturn {\"info\"=(\"*\".[/system identity get name].\"* is here!\")};"
