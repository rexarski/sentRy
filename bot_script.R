# install.packages("telegram.bot")
library(telegram.bot)

# Initialize bot
bot <- Bot(token = "your-bot-token")

# Get bot info
# print(bot$getMe())

# Get updates
updates <- bot$getUpdates()

# Retrieve your chat id
# Note: you should text the bot before calling `getUpdates`
# chat_id <- updates[[1L]]$from_chat_id()
#
# bot$sendMessage(chat_id,
#                 text = "foo *bold* _italic_",
#                 parse_mode = "Markdown"
# )

# send to a channel, use username of the target channel.
# the channel cannot be private, the bot has to be an administrator.
bot$sendMessage(chat_id = "@targetpractice",
                text = "This *IS* a _test_",
                parse_mode = "Markdown")
