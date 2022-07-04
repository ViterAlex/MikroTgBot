#########################################################################
# Bot commands:
#   coocoo - Invitation message to start
#   wol - WOL menu
#   shutdown - shutdown menu
#   add - Add new computer to manage
#   remove - Remove computer
#
#########################################################################
:global fFetch;
:global fTGcallback;
:global fTGcommand;
:global fTGsend;
:global fTGresultToMsg;

#flag to prevent duplicate run getUpdate
:global BEINGUPDATED;
:if (any BEINGUPDATED) do={ return; }
:set BEINGUPDATED true;
#executed messages
:global EXECMSG;

:local commitUpdate do={
 :global fFetch;
 $fFetch url=($url."&offset=".(($msg->"updateId")+1))
}

#get config script and execute it
:local fconfig [:parse [/system script get tg_config source]];
:local cfg [$fconfig];

#local variables for params
:local trusted [:toarray ($cfg->"trusted")];
:local botAPI ($cfg->"botAPI");
:local storage ($cfg->"storage");
:local timeout ($cfg->"timeout");


:local logfile ($storage."tg_fetch_log.txt");
#get messages
:local url ("https://api.telegram.org/bot$botAPI/getUpdates?limit=1");

:put "Reading updates..."

:local result [$fFetch url=$url resfile=$logfile];
:if ([:type ($result->"error")]!="nothing") do={
  :put "Error getting updates";
  :put $result;
  :set BEINGUPDATED;
  return "Failed get updates";
}
:put "Finished to read updates.\n";

:global JSONLoads;
#parse result
:set $result ([$JSONLoads ($result->"data")]->"result");
:local timeout ($cfg->"timeout");
#convert to msg
:put "Converting result to msg...";
:local msg [$fTGresultToMsg result=$result timeout=$timeout];

#check for errors
:if (any ($msg->"error")) do={ 
  :put $msg;
  :set BEINGUPDATED;
  return $msg;
}

#check if any messages
:if (!any ($msg->"messageId")) do={ 
  :put "No new updates";
  :set BEINGUPDATED;
  :return {"info"="no updates"};
}

#check if chatId or sender are trusted
:local allowed ( [:type [:find $trusted ($msg->"fromId")]]!="nil" or \
                 [:type [:find $trusted ($msg->"chatId")]]!="nil")
:if (!$allowed) do={
  :put "Unknown sender, keep silence";
  [$commitUpdate url=$url msg=$msg]
  $fTGsend  chat=($msg->"chatId") \
            text="You're not allowed to send commands";
  :set BEINGUPDATED;
  :return {"error"="You're not allowed to send commands"};
}

#check if message is expired
:if (($msg->"expired")=true) do={
  #remove from executed
  :local tempMsg;
  :foreach k,v in=[:toarray $EXECMSG] do={ 
    :if ($v!=($msg->"messageId")) do={ 
      :set $tempMsg ($tempMsg.$v);
      }
  }
  :set $EXECMSG $tempMsg;
  [$commitUpdate url=$url msg=$msg]
  # $fTGsend text=("*".[/system identity get name]."*%0A\
  # Command _".$msg->"command"->"verb"."_ expired and commited.") \
  #           chat=($msg->"chatId") \
  #           mode="Markdown"
  :set BEINGUPDATED;
  return {
    "info"="Message is expired and commited";
    "msg"=$msg
    };
}

#check if message was executed
:local isexecuted [:find $EXECMSG ($msg->"messageId")];
:if (any isexecuted) do={ 
  return {"info"=("command <".($msg->"command"->"verb")."> already executed.")}
}

#check if command should be ignored
:local cmdToIgnore [:find ($cfg->"ignore") ($msg->"command"->"verb")];
:if (any $cmdToIgnore) do={ 
  :put ("Do not commit on <".($msg->"command"->"verb").">. Skip it.");
  :set BEINGUPDATED;
  return {
    "info"="Ignore command";
    "msg"=$msg
    };
}

#trying to run a command
#set script name
:local cmdScript ($msg->"command"->"script");
#try to get script by its name
:do {
  :set $cmdScript [/system script get ($msg->"command"->"script") name];
} on-error={:put "no script $cmdScript"}
:if ([:len $cmdScript]=0) do={
  :local t ("No such command <".($msg->"command"->"verb").">");
  :put $t;
  $fTGSend chat=$chatid \
           text=$t;
} else={
  :put "Try to invoke $cmdScript";
  :local script [:parse [/system script get $cmdScript source]];
  [$script $cmdScript \
          params=($msg->"command"->"params") \
          chatid=($msg->"chatId") \
          from=($msg->"userName")];
}

#check if command should be commited after execution
:local executeNotCommit [:find ($cfg->"executeNotCommit") ($msg->"command"->"verb")];
:if (any $executeNotCommit) do={ 
  :put ("Do not commit executed <".($msg->"command"->"verb").">.");
  #add executed messages to list in order to not repeat
  :global EXECMSG;
  :if (any $EXECMSG) do={ 
    :set ("$EXECMSG,".($msg->"messageId"));
  } else={
    :set $EXECMSG ($msg->"messageId");
  }
  :set BEINGUPDATED;
  return {
    "info"="Execute but not commit";
    "msg"=$msg
    };
}

:put ("\n\nCommiting message on <".($msg->"command"->"verb").">...");
$commitUpdate url=$url msg=$msg;
:set BEINGUPDATED;