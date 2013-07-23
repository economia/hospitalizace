library(shiny)

skupiny  <- read.csv("skupiny.csv")
kraje  <- read.csv("kraje.csv", sep=";", header=F)

# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
  
# Application title
  headerPanel("Všichni hospitalizovaní v České republice v letech 2007 - 2011"),
  
# Sidebar 
  sidebarPanel(
    selectInput("skupina", "1. Vyberte druh nemoci:", 
                choices = skupiny$V2),

    uiOutput("diagnozyVybrane"),
    
    helpText("Nemoci jsou rozděleny podle klasifikace OECD. Dokud nevyberete žádný druh nemoci, zobrazují se souhrnná data pro všechny pobyty v nemocnici. Nezvolíte-li přesnou diagnózu, uvidíte grafy a údaje pro celou kategorii. Některé kategorie nemocí se již dále nečlení, nelze proto vybrat přesnou diagnózu a k dispozici je jen volba \"Vše\"."),
    selectInput("kraj", "3. Zajímá-li vás jen určitý kraj, vyberte jej zde:", 
                choices = kraje$V2)    
  ),
  
# Show a plot of the generated distribution
  mainPanel(

  )
))
