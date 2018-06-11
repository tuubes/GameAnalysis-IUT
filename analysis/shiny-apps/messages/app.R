#
# Shiny Web App - Taille des messages
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC
# Working directory : dossier de l'application, avec un dossier adjacent "db_data" contenant les BDD et h2.jar

library(shiny)
library(RJDBC)

# -- Récupération des données depuis la BDD H2 ---
driverH2 <- sprintf("%s/../db_data/h2.jar", getwd())
dbBofas <- sprintf("%s/../db_data/database_bofas", getwd())
dbJulien <- sprintf("%s/../db_data/database_julien", getwd())

drv <- JDBC(driverClass = "org.h2.Driver", classPath = driverH2, identifier.quote="`")
connBofas <- dbConnect(drv, paste("jdbc:h2:", dbBofas, sep=""), "", "")
connJulien <- dbConnect(drv, paste("jdbc:h2:", dbJulien, sep=""), "", "")

dataBofas <- dbGetQuery(connBofas, "SELECT Size FROM Messages")
dataJulien <- dbGetQuery(connJulien, "SELECT Size FROM Messages")
dataAll <- rbind(dataBofas, dataJulien)

dbDisconnect(connBofas)
dbDisconnect(connJulien)

maxBofas <- max(dataBofas$SIZE)
maxJulien <- max(dataJulien$SIZE)
maxAll <- max(maxBofas, maxJulien)

# -- UI : interface web ---
ui <- fluidPage(
  # Application title
  titlePanel("Taille des messages envoyés dans le chat du jeu"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("serverChoice",
                  label="Choisissez le serveur de jeu",
                  choices = list("BOFAS", "Julien", "Données combinées", "Données comparées"),
                  selected = "Données comparées"),
      textOutput("nbObs"),
      br(),
      sliderInput(
        "sup",
        "Limite supérieure :",
        min = 1,
        max = maxBofas,
        value = maxBofas
      )
    ),
  
    mainPanel(
      plotOutput("boxplot", height=500),
      htmlOutput("comment"),
      br(),
      em("* Le serveur stocke les messages en UTF-16, avec exactement 2 octets par caractère."))
  )
)

# -- Partie serveur --
server <- function(input, output, session) {
  dataInput <- reactive({
    if(input$serverChoice == "BOFAS") {
      data <- dataBofas
      updateSliderInput(session, "sup", max=maxBofas)
    } else if(input$serverChoice == "Julien") {
      data <- dataJulien
      updateSliderInput(session, "sup", max=maxJulien)
    } else {
      data <- dataAll
      updateSliderInput(session, "sup", max=maxAll)
    }
    return(data)
  })
  
  output$boxplot <- renderPlot({
    #data <- data[data$SIZE <= input$sup, ]
    title <- sprintf("Distribution de la taille des messages")
    if(input$serverChoice == "Données comparées") {
      boxplot(c(dataBofas, dataJulien), names=c("BOFAS", "Julien"), main=title, ylab="Nombre de caractères", cex=2)
      abline(h = input$sup, col="red")
    } else {
      boxplot(dataInput(), main=title, ylab="Nombre de caractères", cex=2)
      abline(h = input$sup, col="red")
    }
  })
  output$comment <- renderUI({
    sup <- input$sup
    if(input$serverChoice == "Données comparées") {
      countBofas <- sum(dataBofas$SIZE <= sup)/nrow(dataBofas)*100
      countJulien <- sum(dataJulien$SIZE <= sup)/nrow(dataJulien)*100
      count <- sum(dataAll$SIZE <= sup)/nrow(dataAll)*100
      HTML(paste(
        sprintf("BOFAS : %.2f %% des messages font moins de %i caractères, et donc moins de %i octets*",
              countBofas, sup, sup*2),
        sprintf("Julien : %.2f %% des messages font moins de %i caractères, et donc moins de %i octets*",
              countJulien, sup, sup*2),
        sprintf("Données combinées : %.2f %% des messages font moins de %i caractères, et donc moins de %i octets*",
              count, sup, sup*2),
        sep="<br>")
      )
    } else {
      data <- dataInput()
      count <- sum(data$SIZE <= sup)/nrow(data)*100
      HTML(sprintf("%.2f %% des messages font moins de %i caractères, et donc moins de %i octets*",
              count, sup, sup*2))
    }
  })
  output$nbObs <- renderText({
    nbObs <- nrow(dataInput())
    sprintf("%i observations", nbObs)
  })
}

# -- Lancement de l'app --
shinyApp(ui = ui, server = server)

