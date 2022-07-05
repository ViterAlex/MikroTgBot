##########################################################################
# tg_cmd_wolByName - WakeOnLan by hostname
#  Input: 
#     $1 — script name (information only)
#     params — hostname to Wake-On-LAN
#  Output: 
#    {"error"="error message"} on error 
#    {"info"="Method message to send to chat"}"success" on success
##########################################################################
:put "Command $1 is executing";
:local hostname $params;
#get mac from dhcp lease
:local mac ([/ip dhcp-server lease print as-value where host-name=$hostname]->0->"mac-address");
:if ([:typeof $mac]="nothing") do={ 
  #no mac in dhcp lease. Try dns static
  :local ip ([/ip dns static print as-value where name=$hostname]->0->"address");
  :set $mac ([/ip arp print as-value where address=$ip]->0->"mac-address")
  :if ([:typeof $mac]="nothing") do={
    :return {"error"="*<$hostname>* is not found neither in dhcp lease no in dns static"} ;
  }
}
#get interface from arp
:local ifc "bridge";
:local macs [/ip arp print as-value where mac-address=$mac];
:if ([:len $macs]!=0) do={ 
  :set $ifc ($macs->0->"interface");
 }

/tool wol mac=$mac interface=$ifc;
:return {"info"="*<$hostname>* is waked up!"};