##########################################################################
# TelegramBotFunctions - defines functions for using with polling Telegram-bot
# 
#  Input: 
#     none
#  Output: 
#    functions as global variables
#    
##########################################################################
##########################################################################
# fTGcallback - function for processing callback from inlinebutton.
# See tg_callback.rsc for implemetation
##########################################################################
:global fTGcallback;
:if (!any fTGcallback) do={ :global fTGcallback {
  :local callback [:parse [/system script get tg_callback source]];
  $callback query=$query;
} }

##########################################################################
# fTGcommand - function for processing command in message text. Command
# must start with /. May be followed with parameters separated with spaces.
# See tg_command.rsc for implemetation
##########################################################################
:global fTGcommand;
:if (!any fTGcommand) do={ :global fTGcommand {
  :local command [:parse [/system script get tg_command source]];
  $command text=$text;
} }

##########################################################################
# fTGsend - function for sending messages
# See tg_send.rsc for implemetation
##########################################################################
:global fTGsend;
:if (!any fTGsend) do={ :global fTGsend {
  :local send [:parse [/system script get tg_send source]];
  $send chat=$chat text=$text mode=$mode replyMarkup=$replyMarkup
} }

##########################################################################
# fTGgetUpdates - getting updates and execute commands
# See tg_getUpdates.rsc for implementation
##########################################################################
:global fTGgetUpdates;
:if (!any $fTGgetUpdates) do={ :global fTGgetUpdates {
  :local getUpdtates [:parse [/system script get tg_getUpdates source]]
  $getUpdates;
} }

##########################################################################
# fTGresultToMsg - converts result object to msg
# See tg_resultToMsg.rsc for implementation
##########################################################################
:global fTGresultToMsg;
:if (!any $fTGresultToMsg) do={ :global fTGresultToMsg {
  :local resultToMsg [:parse [/system script get tg_resultToMsg source]];
  $resultToMsg result=$result timeout=$timeout;
} }

##########################################################################
# fFetch - Wrapper for /tools fetch
# 
#  Input:
#    mode
#    upload=yes/no
#    user
#    password
#    address
#    host
#    httpdata
#    httpmethod
#    check-certificate
#    src-path
#    dst-path
#    ascii=yes/no
#    url
#    resfile
#  Output: 
#    {"error"="error message"}
#    {"data"=array; "downloaded"=num; "status"=string}
##########################################################################
:global fFetch;
:if (!any fFetch) do={ :global fFetch do={
  :local res "fetchresult.txt"
  :if ([:len $resfile]>0) do={:set res $resfile}

  :local cmd "/tool fetch"
  :if ([:len $mode]>0) do={:set cmd "$cmd mode=$mode"}
  :if ([:len $upload]>0) do={:set cmd "$cmd upload=$upload"}
  :if ([:len $user]>0) do={:set cmd "$cmd user=\"$user\""}
  :if ([:len $password]>0) do={:set cmd "$cmd password=\"$password\""}
  :if ([:len $address]>0) do={:set cmd "$cmd address=\"$address\""}
  :if ([:len $host]>0) do={:set cmd "$cmd host=\"$host\""}
  :if ([:len $"http-data"]>0) do={:set cmd "$cmd http-data=\"$"http-data"\""}
  :if ([:len $"http-method"]>0) do={:set cmd "$cmd http-method=\"$"http-method"\""}
  :if ([:len $"check-certificate"]>0) do={:set cmd "$cmd check-certificate=\"$"check-certificate"\""}
  :if ([:len $"src-path"]>0) do={:set cmd "$cmd src-path=\"$"src-path"\""}
  :if ([:len $"dst-path"]>0) do={:set cmd "$cmd dst-path=\"$"dst-path"\""}
  :if ([:len $ascii]>0) do={:set cmd "$cmd ascii=\"$ascii\""}
  :if ([:len $url]>0) do={:set cmd "$cmd url=\"$url\""}

  :set $cmd "$cmd output=user as-value"
  :put ">> $cmd"

  :global FETCHRESULT
  :set $FETCHRESULT [:toarray ""];

  :local script ":global FETCHRESULT [:toarray \"\"];
  :do {
    :set FETCHRESULT [$cmd];
  } on-error={
    :set FETCHRESULT {\"error\"=\"failed\"};
  }"
  :execute script=$script file=$res
  :local cnt 0
  :while ($cnt<100 and ([:len $FETCHRESULT]=0)) do={ 
    :delay 1s
    :set $cnt ($cnt+1)
  }
  :local result $FETCHRESULT;
  # :set $FETCHRESULT;
  
  :return $result;
} }

##########################################################################
# fTGclear - clears global functions related to Telegram
# 
#  Input: 
#    none
#  Output: 
#    none
##########################################################################
:global fTGclear;
:if (!any $fTGclear) do={ :global fTGclear do={
  :global fFetch;
  :set fFetch;
  :global fTGcallback;
  :set fTGcallback;
  :global fTGcommand;
  :set fTGcommand;
  :global fTGgetUpdates;
  :set fTGgetUpdates;
  :global fTGsend;
  :set fTGsend;
  :global fTGresultToMsg;
  :set fTGresultToMsg;
}}