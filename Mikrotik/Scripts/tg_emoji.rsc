##########################################################################
# tg_emoji - list of emojis for buttons
# 
#  Input: 
#    none
#  Output: 
#    {
#     "wol"; \
#     "shutdown"; \
#     "health"; \
#     "online"; \
#     "edit"
#     }
#  Using:
#    :local emojiFile [:parse [/system script get tg_emoji source]];
#    :local emoji [$emojiFile];
##########################################################################

:local emoji { \
              "wol"="%E2%8F%B0"; \
              "shutdown"="%F0%9F%9B%8C"; \
              "health"="%F0%9F%A9%BA"; \
              "online"="%F0%9F%91%80"; \
              "edit"="%E2%9C%8E"; \
              "add"="%E2%9E%95"; \
              "remove"="%E2%9E%96"; \
              "menu"="%F0%9F%93%8B"; \
              "pc"="%F0%9F%96%A5";
              };
return $emoji;