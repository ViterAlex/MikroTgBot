##########################################################################
# tg_getkey - get key in message
#  Input: 
#     text - source text
#     block - starting from which block to check for key
#     key
#  Output: 
#    -1 if not found 
#     value if found
##########################################################################

:local cur 0
:local lkey [:len $key]
:local res ""
:local p

:if ([:len $block]>0) do={
 :set p [:find $text $block $cur]
 :if ([:type $p]="nil") do={
  :return $res
 }
 :set cur ($p+[:len $block]+2)
}

:set p [:find $text $key $cur]
:if ([:type $p]!="nil") do={
 :set cur ($p+lkey+2)
 :set p [:find $text "," $cur]
 :if ([:type $p]!="nil") do={
   if ([:pick $text $cur]="\"") do={
    :set res [:pick $text ($cur+1) ($p-1)]
   } else={
    :set res [:pick $text $cur $p]
   }
 } 
}
:return $res