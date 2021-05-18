library(tidyverse)
library(shiny)
library(aws.s3)

s3BucketName <- "your-s3-bucket-name"
Sys.setenv("AWS_ACCESS_KEY_ID" = "*********************",
           "AWS_SECRET_ACCESS_KEY" = "*********************")

loadData <- function(file) {

  obj <- get_object(paste0("s3://", s3BucketName, "/", file))
  csvcharobj <- rawToChar(obj)
  con <- textConnection(csvcharobj)
  loaded <- read.csv(con, col.names = c(
    "condition", "error_time", "detail", "is_notified",
    "server", "notify_time"), stringsAsFactors = FALSE)
  loaded <- as_tibble(loaded) %>%
    mutate(error_time = lubridate::as_datetime(error_time),
           is_notified = as.logical(is_notified),
           notify_time = lubridate::as_datetime(notify_time))
  close(con)
  return(loaded)
}

ui <- fluidPage(
  title = "sentRy",
  sidebarLayout(
    sidebarPanel(
      conditionalPanel(
        'input.dataset === "notification"',
        helpText("In development")
      )
    ),
    mainPanel(
      tabsetPanel(
        id = 'dataset',
        tabPanel("notification", DT::dataTableOutput("mytable"))
      )
    )
  )
)

server <- function(input, output) {
  notif <- loadData("notification.csv")
  notif <- dplyr::arrange(notif, desc(error_time))
  output$mytable <- DT::renderDataTable({
    DT::datatable(notif, options = list(orderClasses = TRUE))
  })

}

shinyApp(ui, server)