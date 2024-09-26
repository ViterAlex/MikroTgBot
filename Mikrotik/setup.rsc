##########################################################################
#   setup - Setup new router
#  Input: 
#     none
#  Output: 
#    none
##########################################################################
:local logHeader "scriptBot:"
/log info "$logHeader Creating backup..."
/system backup save dont-encrypt="yes"
/log info "$logHeader Backup created"
:foreach s in={"scripts";"sched"} do={ 
  /log info "$logHeader Run '$s.rsc'!"
  /import ($s.".rsc")
  /log info "$logHeader '$s.rsc' finished!"
  /file remove ($s.".rsc")
 }
:local cfgFile [:parse [/system script get tg_config source]];
:local cfg [$cfgFile];
:local group ([toarray ($cfg->"ftp")]->0)
:local username ([toarray ($cfg->"ftp")]->1)
#check if group exists
:local g [user group print as-value where name=$group]
:if ([len $g]=0) do={ 
  /user group add name=$group \
    policy="ftp,read,write,!local,!telnet,!ssh,!reboot,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!api,!romon,!dude,!tikapp"
  /log info "$logHeader Group '$group' created!"
 } else={
  /log info "$logHeader Group '$group' exists!"
 }
 :local u [user print as-value where name=$username]
 :if ([len $u]=0) do={ 
    /user add address="127.0.0.1/32" group=$group name=$username password=""
    /log info "$logHeader User '$username' created!"
  } else={
    user  set disabled="no" $username
    /log info "$logHeader User '$username' exists!"
  }
/file remove setup.rsc