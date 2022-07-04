##########################################################################
# tg_resultToMsg - converts result object to msg
# 
#  Input: 
#    result — result object from Telegram parsed from Json
#    timeout — seconds to consider a message expired
#  Output: 
#    {"error"="error message"} on error 
#    {
#       "updateId"=""; 
#       "messageId"=""; 
#       "fromId"=""; 
#       "chatId"="";
#       "expired"="";
#       "userName"="";
#       "firstName"="";
#       "lastName"="";
#       "text"="";
#       "command"={"verb"="verb"; "script"="scriptName"; "params"="params"};
#       "isCallback"="";
#    } on success
##########################################################################
:if (!any $result) do={ 
  return {"error"="No result object provided"}
 }
:if (!any $timeout) do={ 
  return {"error"="No timeout provided"}
 }
:put "<tg_resultToMsg>: Result from Telegram-----------------------------"
:set $result ($result->0);
:put ("\t".[:tostr $result]."\n");
#local function to get Unix time
:local EpochTime do={
  :local ds [/system clock get date];
  :local months;
  :local isLeap ((([:pick $ds 9 11]-1)/4) != (([:pick $ds 9 11])/4));
  :if ($isLeap) do={
    :set months {"jan"=0;"feb"=31;"mar"=60;"apr"=91;"may"=121;"jun"=152;"jul"=182;"aug"=213;"sep"=244;"oct"=274;"nov"=305;"dec"=335};
  } else={
    :set months {"jan"=0;"feb"=31;"mar"=59;"apr"=90;"may"=120;"jun"=151;"jul"=181;"aug"=212;"sep"=243;"oct"=273;"nov"=304;"dec"=334};
  }
  :local yy [:pick $ds 9 11];
  :local mmm [:pick $ds 0 3];
  :local dayOfMonth [:pick $ds 4 6];
  :local dayOfYear (($months->$mmm)+$dayOfMonth);
  :local y2k 946684800;
  :set ds (($yy*365)+(([:pick $ds 9 11]-1)/4)+$dayOfYear);
  :local ts [/system clock get time];
  :local hh [:pick $ts 0 2];
  :local mm [:pick $ts 3 5];
  :local ss [:pick $ts 6 8]
  :set ts (($hh*60*60)+($mm*60)+$ss);
  :return ($ds*24*60*60 + $ts + y2k - [/system clock get gmt-offset]);
}

:global fTGcallback;
:global fTGcommand;
:local msg {
  "updateId"=""; 
  "messageId"=""; 
  "fromId"=""; 
  "chatId"="";
  "expired"="";
  "userName"="";
  "firstName"="";
  "lastName"="";
  "text"="";
  "command"=[:toarray ""];
  "isCallback"="";
}
:set ($msg->"updateId") ($result->"update_id");
:set ($msg->"isCallback") (any ($result->"callback_query"));
:local curDate [$EpochTime];
:local tgDate;
:if ($msg->"isCallback") do={ 
  :set $tgDate ($result->"callback_query"->"message"->"date");
  :set ($msg->"messageId")  ($result->"callback_query"->"message"->"message_id");
  :set ($msg->"fromId")     ($result->"callback_query"->"from"->"id");
  :set ($msg->"chatId")     ($result->"callback_query"->"message"->"chat"->"id");
  :set ($msg->"userName")   ($result->"callback_query"->"from"->"username");
  :set ($msg->"firstName")  ($result->"callback_query"->"from"->"first_name");
  :set ($msg->"lastName")   ($result->"callback_query"->"from"->"last_name");
  :set ($msg->"text")       ($result->"callback_query"->"message"->"text");
  :set ($msg->"command")    [$fTGcallback query=($result->"callback_query"->"data")];
 } else={
  :set $tgDate ($result->"message"->"date");
  :set ($msg->"messageId")  ($result->"message"->"message_id");
  :set ($msg->"fromId")     ($result->"message"->"from"->"id");
  :set ($msg->"chatId")     ($result->"message"->"chat"->"id");
  :set ($msg->"userName")   ($result->"message"->"from"->"username");
  :set ($msg->"firstName")  ($result->"message"->"from"->"first_name");
  :set ($msg->"lastName")   ($result->"message"->"from"->"last_name");
  :set ($msg->"text")       ($result->"message"->"text");
  :set ($msg->"command")    [$fTGcommand text=($msg->"text")];
 }
:set ($msg->"expired")    (($curDate-$tgDate)>$timeout);
:return $msg;