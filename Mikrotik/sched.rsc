
/system scheduler
:if ([:len [find name~"Get_TG_Update*"]]=0) do={ 
    add interval=5s name=Get_TG_Updates on-event="/system script run tg_getUpdates" policy=\
        read,write,sensitive \
        start-date=jun/29/2020 start-time=22:26:29
}
add name=PrepareTG on-event=Startup policy=read,write start-time=startup
