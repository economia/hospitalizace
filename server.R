library(shiny)
library(ggplot2)

diagnozy  <- read.csv("diagnozy.csv", header=F)
hospitalizace  <- read.csv("hospitalizace.csv")

filtrujDiagnozy <- function(vybrano) {
  if (vybrano == "Vše") {
    return (diagnozy$V2)
  } else {
      filtrovane  <- diagnozy[substr(diagnozy$V1,1,2)==substr(diagnozy[diagnozy$V2==vybrano,]$V1,1,2),]$V2
      filtrovane  <- as.character(filtrovane)
      filtrovane[1]  <- "Vše"
      return(filtrovane)
    
  }
}

shinyServer(function(input, output) {
  
  output$diagnozyVybrane <- renderUI({
    vybranaSkupina <- filtrujDiagnozy(input$skupina)
    selectInput("diagnoza", "2. Upřesněte diagnózu:", 
                choices = vybranaSkupina)
  })
  
  
  })