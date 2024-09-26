#########################################################################
# getUpdates — get updates from Telegram bot and execute commands.
# Available commands
#   start - Start with bot
#
#########################################################################

#wrapper for /tool fetch
:global fFetch;
#parser for callback
:global fTGcallback;
#wrapper for sendMessage
:global fTGsend;
#converter Telegram result to msg object
:global fTGresultToMsg;

#executed messages
:global EXECMSG;

:local commitUpdate do={
 :global fFetch;
 $fFetch url=($url."&offset=".(($msg->"updateId")+1))
}
#local function to exit getUpdates routine.
:local finish do={
  #enable scheduler
  :put "Finish function called"
  # /system scheduler set disabled=no [find name=Get_TG_Updates]
}

#get config script and execute it to setup
:local fconfig [:parse [/system script get tg_config source]];
:local cfg [$fconfig];

#local variables for params
:local trusted  [:toarray ($cfg->"trusted")];
:local botAPI   ($cfg->"botAPI");
:local storage  ($cfg->"storage");
:local timeout  ($cfg->"timeout");


:local logfile ($storage."tg_fetch_log.txt");
#get messages
:local url ("https://api.telegram.org/bot$botAPI/getUpdates?limit=1");

:put "Reading updates..."

:local result [$fFetch url=$url resfile=$logfile];
:if (any ($result->"error")) do={
  :local msg ("Error getting updates\n".$result)
  $finish
  :put "Failed get updates";
  return $msg;
}
:put "Finished to read updates.\n";
:put $result;
:global JSONLoads;
#parse result
:set $result ([$JSONLoads ($result->"data")]->"result");
:if ([:len $result]=0) do={ 
  #no updates
  :local msg "No updates"
  $finish;
  return $msg;
 }
:local timeout ($cfg->"timeout");
#convert to msg
:put "Converting result to msg...";
:local msg [$fTGresultToMsg result=$result timeout=$timeout];
:put "------------------------MSG------------------------"
:put $msg;
#check for errors
:if (any ($msg->"error")) do={ 
  :put $msg;
  $finish;
  return $msg;
}

#check if any messages
:if (!any ($msg->"messageId")) do={ 
  :put "No new updates";
  $finish;
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
  $finish
  :return {"error"="You're not allowed to send commands"};
}

#check if message is expired
:if (($msg->"expired")=true) do={
  #message if command is just expired
  :local messageText "Command is expired. Repeat, please."
  :if (any $EXECMSG) do={ 
    #message if command was executed and expired
    :set $EXECMSG;
    :set messageText "Let's continue."
  }
  [$commitUpdate url=$url msg=$msg]
  #send main menu to chat
  $fTGsend  chat=($msg->"chatId") \
            text=$messageText;
  :local script [:parse [/system script get tg_cmd_menu source]];
  :local r [$script "tg_cmd_menu" params="main"];
  $fTGsend  text=($r->"info") \
                chat=($msg->"chatId") \
                mode="Markdown" \
                replyMarkup=($r->"replyMarkup")
  $finish;
  return {
    "info"="Message is expired and commited";
    "msg"=$msg
    };
}

#check if message was executed
:local isexecuted [:find $EXECMSG ($msg->"messageId")];
:if (any isexecuted) do={ 
  $finish;
  return {"info"=("command <".($msg->"command"->"verb")."> already executed.")}
}

#check if command should be ignored
:local cmdToIgnore [:find ($cfg->"ignore") ($msg->"command"->"verb")];
:if (any $cmdToIgnore) do={ 
  :put ("Do not commit on <".($msg->"command"->"verb").">. Skip it.");
  $finish;
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
} on-error={
  :put "no script $cmdScript";
  :log error "bot: $cmdScript isn't found";
}
:if ([:len $cmdScript]=0) do={
  $fTGSend  chat=$chatid \
            text=("No such command *<".($msg->"command"->"verb")."*>") \
            mode="Markdown";
  :log error ("bot: Command ".($msg->"command"->"verb")." isn't found");
} else={
  :put "Try to invoke $cmdScript";
  :local script [:parse [/system script get $cmdScript source]];
  :local cmdResult [$script $cmdScript \
                            params=($msg->"command"->"params") \
                            chatid=($msg->"chatId") \
                            from=($msg->"userName")];
  :if (any ($cmdResult->"error")) do={ 
    $fTGsend  text=($cmdResult->"error") \
              chat=($msg->"chatId") \
              mode="Markdown"
  } else={
    :if (any ($cmdResult->"info")) do={ 
      $fTGsend  text=($cmdResult->"info") \
                chat=($msg->"chatId") \
                mode="Markdown" \
                replyMarkup=($cmdResult->"replyMarkup")
      :log info ("bot: Command ".($msg->"command"->"verb").". Result: ".($cmdResult->"info"));
    }
  }
}

#check if command should be commited after execution
:local executeNotCommit [:find ($cfg->"executeNotCommit") ($msg->"command"->"verb")];
:if (any $executeNotCommit) do={ 
  :put ("Do not commit executed <".($msg->"command"->"verb").">.");
  #add executed messages to list in order to not repeat
  :if ($EXECMSG=($msg->"messageId")) do={ 
    $finish;
    return;
  } else={
    :set $EXECMSG ($msg->"messageId");
  }
  $finish;
  return {
    "info"="Execute but not commit";
    "msg"=$msg
    };
}

:put ("\n\nCommiting message on <".($msg->"command"->"verb").">...");
$commitUpdate url=$url msg=$msg;
$finish;
