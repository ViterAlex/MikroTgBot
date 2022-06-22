##########################
# Reply to coo-coo message
#
:local send [:parse [/system script get tg_sendMessage source]];
:local inlineButtons "{\"inline_keyboard\": [[{\"text\":\"buttonText\",\"callback_data\":\"hi\"}]]}";
:put "coo-coo";
:put ("params = $params");
:put ("chatid = $chatid");
:put ("from = $from")

$send chat=$chatid text="What to do?" mode="Markdown" replyMarkup=$inlineButtons;

return true