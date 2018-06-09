#
# Shiny Web App - Types d'entités, stats univariées
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC, data.table, ggplot2
# Working directory : dossier de l'application, avec un dossier adjacent "db_data" contenant les BDD et h2.jar

library(shiny)
library(RJDBC)
library(data.table)
library(ggplot2)

# -- Récupération des données depuis la BDD H2 ---
driverH2 <- sprintf("%s/../db_data/h2.jar", getwd())
dbBofas <- sprintf("%s/../db_data/database_bofas", getwd())
dbJulien <- sprintf("%s/../db_data/database_julien", getwd())

drv <- JDBC(driverClass = "org.h2.Driver", classPath = driverH2, identifier.quote="`")
connBofas <- dbConnect(drv, paste("jdbc:h2:", dbBofas, sep=""), "", "")
connJulien <- dbConnect(drv, paste("jdbc:h2:", dbJulien, sep=""), "", "")

dbGetQuery(connBofas, "SHOW TABLES")
dbGetQuery(connJulien, "SHOW TABLES")

sqlTypeCount <- "SELECT count(*) AS COUNT, EntityType AS TYPE FROM EntitySpawns GROUP BY EntityType ORDER BY count(*) DESC"
dataBofas <- data.table(dbGetQuery(connBofas, sqlTypeCount))
dataJulien <- data.table(dbGetQuery(connJulien, sqlTypeCount))
dataCombined <- data.table(rbind(dataBofas, dataJulien))

# Fusionne les count pour les données combinées :
dataCombined <- dataCombined[, sum(COUNT), by=TYPE]
setnames(dataCombined, "V1", "COUNT") # renomme la colonne V1=sum(COUNT) en "COUNT"
setorder(dataCombined, -COUNT) # ordre décroissant par COUNT

dbDisconnect(connBofas)
dbDisconnect(connJulien)

peacefulMobs <- c("BAT", "MAGMA_CUBE", "SQUID", "CHICKEN", "IRON_GOLEM", "SLIME", "PIG")

# -- UI : interface web ---
ui <- fluidPage(
  # Application title
  titlePanel("Apparition des entités non-joueurs"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("serverChoice",
                  label="Choisissez le serveur de jeu",
                  choices = list("BOFAS", "Julien", "Données combinées"),
                  selected = "Données combinées"),
      br(),
      checkboxGroupInput("dataChoice",
                         label="Données à afficher",
                         choices = c("Monstres hostiles" = "monster",
                                     "Animaux pacifiques" = "peaceful"),
                         selected = c("monster", "peaceful")),
      br(),
      sliderInput(
        "minPercent",
        "Pourcentage minimum",
        min = 0.5,
        max = 25,
        value = 7,
        step = 0.5
      ),
      helpText("Seuls les entités qui représentent plus que le pourcentage minimum sont affichées."),
      textOutput("nbObs"),
      br(),
      checkboxInput("usePercent",
                    label="Graphique en pourcentages",
                    value=TRUE)
    ),
    
    mainPanel(plotOutput("chart", height=600))
  )
)

# -- Partie serveur --
server <- function(input, output, session) {
  dataInput <- reactive({
    # Sélectionne le serveur
    if(input$serverChoice == "BOFAS") {
      data <- dataBofas
    } else if(input$serverChoice == "Julien") {
      data <- dataJulien
    } else {
      data <- dataCombined
    }
    print(input$dataChoice)
    if(length(input$dataChoice) == 1) {
      if("peaceful" %in% input$dataChoice) {
        data <- data[TYPE %in% peacefulMobs]
      } else {
        data <- data[!(TYPE %in% peacefulMobs)]
      }
    } else if(length(input$dataChoice) == 0) {
      data <- data.table(TYPE=character(), COUNT=integer()) # empty data
    }
   return(data)
  })
  filteredData <- reactive({
    # Applique la condition de seuil choisie par l'utilisateur
    aggregated <- dataInput()
    minCount <- ceiling(input$minPercent / 100.0 * totalCount())
    filtered <- aggregated[COUNT >= minCount]
    return(filtered)
  })
  totalCount <- reactive({
    aggregated <- dataInput()
    totalCount <- sum(aggregated$COUNT)
  })
  
  output$chart <- renderPlot({
    data <- filteredData()
    if(input$usePercent) {
      a <- aes(x=reorder(TYPE, -COUNT), y=COUNT/totalCount(), fill=TYPE)
      end <- scale_y_continuous(label=scales::percent)
      ylabel <- "% apparition"
    } else {
      a <- aes(x=reorder(TYPE, -COUNT), y=COUNT, fill=TYPE)
      end <- NULL
      ylabel <- "Nombre d'apparitions"
    }
    
    # Graphique avec ggplot2
    ggplot(data, a) +
      geom_bar(stat="identity") +
      ggtitle("Diagramme de Pareto des types d'entité\nnon-joueurs qui apparaissent en jeu") +
      xlab("\n\nType") +
      ylab(ylabel) +
      scale_fill_discrete() + # guide=F supprime la légende
      theme(
        text = element_text(size=20),
        axis.text.x = element_text(angle=45,vjust=0.5),
        plot.title = element_text(hjust=0.5)
      ) +
      end
  })
  
  output$nbObs <- renderText({
    data <- filteredData()
    nbTypes <- nrow(data)
    nbObs <- sum(data$COUNT)
    if (nbTypes == 0) {
      return("Aucune donnée ne correspond aux critères")
    } else if(nbTypes == 1) {
      sprintf("1 type totalisant %i utilisations", nbObs)
    } else {
      sprintf("%i types totalisant %i utilisations", nrow(data), sum(data$COUNT))
    }
  })
}

# -- Lancement de l'app --
shinyApp(ui = ui, server = server)

