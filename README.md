# MikroTgBot
This project allows to turn on/off computers in small office via Telegram-bot.
You can:
1. Check status of PC or router
1. Check whether device is online
1. Turn on PC's with WoL packet
1. Turn off PC
Project contains two semi-independent parts: a part hosted on the router, and a part running on PC
## How To Install
### Router
* copy files [script.rsc](https://github.com/ViterAlex/MikroTgBot/blob/master/Mikrotik/sched.rsc), [sched.rsc](https://github.com/ViterAlex/MikroTgBot/blob/master/Mikrotik/script.rsc), [setup.rsc](https://github.com/ViterAlex/MikroTgBot/blob/master/Mikrotik/setup.rsc) to the router and run **setup.rsc**. This will create backup and install all nessesary scripts.
* change script [tg_config](https://github.com/ViterAlex/MikroTgBot/blob/master/Mikrotik/Scripts/tg_config.rsc) on the router with real values:
```
:local config {
  "botAPI"="0123456789:dfdfadf";
  "defaultChatID"="chatid";
  "trusted"="1122445522";
  "storage"="";
  "timeout"=60;
  "ignore"="ignoreCommand";
  "executeNotCommit"="health,add,remove,online";
}
:put "<tg_config>: Config------------------------------------------------"
:foreach k,v in=$config do={ :put "\t\"$k\" = \"$v\"" }
:put "\n"
return $config
```
* reboot router
### Computer
* copy content of [Powershell](https://github.com/ViterAlex/MikroTgBot/tree/master/Powershell) folder to any place on the PC
* run script [install_run_as_admin.bat](https://github.com/ViterAlex/MikroTgBot/blob/master/Powershell/install_run_as_admin.bat) with elevated rights
* script will copy nessesary files to **%programdata%\Dreamcatcher** folder and will create a service DreamcatcherService
* create file config.json in the folder **%programdata%\Dreamcatcher**:
```
{
  "botapi": "0123456789:afdfadfadfad",
  "trusted": "1122334455",
  "allowed": "shutdown,health,online",
  "notCommit":" health,online"
}
```
### How it works
A script `tg_getUpdates` runs on the router every 1 second. After run this script disables scheduled run. Then it loads config from `tg_config` script. Then reads updates from Telegram. The answer from Telegram is sent to function `fTGresultToMsg`
