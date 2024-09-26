##########################################################################
# tg_cmd_remove - command for removing computers
#  Input: 
#     $1 — script name (information only)
#     params — name of PC to remove
#  Output: 
#     On error:
#       {"error"="error message"}
#     On success:
#       {"info"="message from method";"replyMarkup"="inline buttons markup"}
##########################################################################
:put ("Len of params is ".([:len $params]))
:put "Params is '$params'"
:put ("Params is empty:".($params=""))
:put ("Type of params is ".([:typeof $params]))
:local menuScript [:parse [/system script get tg_cmd_menu source]];
:if ([:len $params]=0) do={ 
  #command with no params. So show up menu
  return [$menuScript "tg_cmd_menu" params="remove"];
}
:local cfgFile [:parse [/system script get tg_config source]];
:local cfg [$cfgFile];
:global JSONLoad;
:local computers [$JSONLoad ($cfg->"PClist")]
#remove quotes from computer name
:local name [pick $params 1 ([len $params]-1)]
:if (!any ($computers->$name)) do={ 
  return {"info"="Computer $name is already removed.";"replyMarkup"=""};
 }
:local mac ($computers->$name)
#clear
:set ($computers->$name)
#write to file
:global JsonFromArray;
 /file set ($cfg->"PClist") contents=[$JsonFromArray $computers]
return [$menuScript "tg_cmd_menu" text=("\"".$name."\" removed") params="remove"];;