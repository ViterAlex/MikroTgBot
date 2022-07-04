
/system scheduler
add interval=15s name=Get_TG_Updates on-event="\$fTGgetUpdates" policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=jun/29/2020 start-time=22:26:29
add name=PrepareTG on-event=Startup policy=read,write start-time=startup
