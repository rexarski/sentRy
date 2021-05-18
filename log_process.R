library(tidyverse)
library(telegram.bot)
library(cronR)
library(shinyFiles)

# Initialize bot
bot <- Bot(token = "your-bot-token")
updates <- bot$getUpdates()

# show time in log
print(Sys.time())

source("/home/rexarski/sentRy/global.R")

# production server
system("scp /home/centos/k2l-platform/k2l_platform/logs/error.log ~/sentRy/error.log")
.server <- "prod"
latest <- lubridate::ymd_hms(read_csv("~/sentRy/settings.csv")$latest)
logs <- read_file("~/sentRy/error.log")

# patterns (strictly capitalized)
p1 <- "^(ERROR|WARNING|CRITICAL)"
p2 <- "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"
type_time <- paste0("(", p1, ") ", p2)

logs <- str_split(logs, pattern = regex("\n")) %>% unlist()

txt <- tibble(
  'meta0' = logs
) %>%
  filter(str_detect(meta0, p1))

if (nrow(txt)!=0) {

  meta1 <- str_extract_all(txt$meta0, pattern = regex(type_time, ignore_case = FALSE)) %>%
    unlist()

  meta2 <- str_split(txt$meta0, pattern = regex(type_time, ignore_case = FALSE)) %>%
    lapply(function(x) x[!x %in% ""]) %>%
    unlist()

  output <- tibble(
    "meta" = meta1,
    "detail" = meta2,
    "notified" = FALSE,
    "server" = .server,
    "local_noti_time" = Sys.time()
  ) %>%
    separate(meta, into = c("type", "time"), sep = " ",
             remove = TRUE, extra = "merge") %>%
    # mutate(time = str_replace(time, ",", ".")) %>%
    mutate(time = lubridate::ymd_hms(time)) %>%
    filter(time > latest)

  if (nrow(output) > 0) {

    if (nrow(output) > 1) {
      message <- paste0(
        "<b>SYS TIME</b>: ", output[1,]$local_noti_time, "\n",
        "<b>ERROR COUNT SINCE LAST UPDATE</b>: ", nrow(output), "\n\n",
        "<b>ALERT</b>: ", output[1,]$type, "\n",
        "<b>ERROR TIME</b>: ", output[1,]$time, " (UTC) \n",
        "<b>SERVER</b>: ", output[1,]$server, "\n",
        "<b>DETAIL</b>: ", output[1,]$detail, "\n\n",
        "<b>ALERT</b>: ", output[nrow(output),]$type, "\n",
        "<b>ERROR TIME</b>: ", output[nrow(output),]$time, " (UTC) \n",
        "<b>SERVER</b>: ", output[nrow(output),]$server, "\n",
        "<b>DETAIL</b>: ", output[nrow(output),]$detail, "\n\n",
        "See this for more details. https://rexarski.shinyapps.io/sentRy/"
      )
      bot$sendMessage(chat_id = "@targetpractice",
                      text = message,
                      parse_mode = "html")
    } else {
      message <- paste0(
        "<b>SYS TIME</b>: ", output[1,]$local_noti_time, "\n",
        "<b>ERROR COUNT SINCE LAST UPDATE</b>: ", 1, "\n\n",
        "<b>ALERT</b>: ", output[1,]$type, "\n",
        "<b>ERROR TIME</b>: ", output[1,]$time, " (UTC) \n",
        "<b>SERVER</b>: ", output[1,]$server, "\n",
        "<b>DETAIL</b>: ", output[1,]$detail, "\n\n",
        "See this for more details. https://rexarski.shinyapps.io/sentRy/"
      )
      bot$sendMessage(chat_id = "@targetpractice",
                      text = message,
                      parse_mode = "html")
    }

    # save data to local file
    write_delim(output, "~/sentRy/notification.csv", delim = ",",
                col_names = !file.exists("~/sentRy/notification.csv"), append = T)

    # send an image

    testing <- read_csv("~/sentRy/notification.csv", col_names = c("type", "time", "detail",
                                                          "notified", "server", "local_noti_time"),
                        col_types = cols(col_character(), col_datetime(), col_character(),
                                         col_logical(), col_character(), col_datetime()))

    t <- Sys.time()

    data_plot <- testing %>%
      filter(t - time <= 12 * 60)

    ggplot(data_plot, aes(x=time)) +
      geom_histogram(binwidth = 300, colour="white") +
      scale_x_datetime(breaks = scales::date_breaks("1 hour")) +
      ylab("Error frequency") + xlab("Time") +
      ggtitle("Error alert in last 12 hours") +
      theme_bw() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    ggsave("12hourplot.png")

    bot$sendPhoto(
      chat_id = "@targetpractice",
      photo = "12hourplot.png",
      caption = "last 12 hours"
    )

    # make a copy on s3 bucket as well
    # system("scp notification.csv dashboard/notification.csv")
    saveData()

    # update to latest time tracking
    latest <- max(output$time)
    write_csv2(data.frame(latest=latest), "~/sentRy/settings.csv")
  }
}

# cleanup wd
# rm(list=ls())
# gc()
