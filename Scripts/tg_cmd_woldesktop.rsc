##########################
#WOL specified PC
#
:local send [:parse [/system script get tg_sendMessage source]];
:local mac "04:D9:F5:7D:3B:69";
:local ifc "bridge";

/tool wol mac=$mac interface=$ifc;
:local result "result";
:put $params
:put $chatid
:put $from
:local host [/ip dhcp-server lease print as-value where mac-address=$mac];
:set host ($host->0->"host-name");
$send chat=$chatid text=("WOL sent.%0A_Pinging..._*$host*") mode="Markdown";
:local hostIP ([/ip arp print as-value where mac-address=$mac]->0->"address");
:put "Host IP is $hostIP";
return true