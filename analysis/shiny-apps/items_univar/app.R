#
# Shiny Web App - Blocs et items, stats univariées
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC
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

sqlBroken <- "SELECT Name, count(B.Id) AS Count FROM BrokenBlocks B, ItemRegistry I WHERE B.Id = I.Id GROUP BY Name ORDER BY count(B.Id) DESC"
sqlPlaced <- "SELECT Name, count(B.Id) AS Count FROM PlacedBlocks B, ItemRegistry I WHERE B.Id = I.Id GROUP BY Name ORDER BY count(B.Id) DESC"
sqlCreated <- "SELECT Name, sum(Amount) AS Count FROM CreatedItems C, ItemRegistry I WHERE C.Id = I.Id GROUP BY Name ORDER BY sum(Amount) DESC"
#sqlConsumed <- "SELECT Name, count(C.Id) AS Count FROM ConsumedItems C, ItemRegistry I WHERE C.Id = I.Id GROUP BY Name ORDER BY count(C.Id) DESC"
# on a trop peu de données pour les objets consommés

dataBofas <- list(dbGetQuery(connBofas, sqlBroken),
                  dbGetQuery(connBofas, sqlPlaced),
                  dbGetQuery(connBofas, sqlCreated)
                  #,dbGetQuery(connBofas, sqlConsumed)
                  )

dataJulien <- list(dbGetQuery(connJulien, sqlBroken),
                   dbGetQuery(connJulien, sqlPlaced),
                   dbGetQuery(connJulien, sqlCreated)
                   #,dbGetQuery(connJulien, sqlConsumed)
                   )

dataColors <- dbGetQuery(connBofas, "SELECT Name, Color FROM ItemRegistry")

# View(dataBofas[[1]])
# View(dataBofas[[3]])

dbDisconnect(connBofas)
dbDisconnect(connJulien)

# -- UI : interface web ---
ui <- fluidPage(
  # Application title
  titlePanel("Utilisation des blocs et objets"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("serverChoice",
                  label="Choisissez le serveur de jeu",
                  choices = list("BOFAS", "Julien", "Données combinées"),
                  selected = "BOFAS"),
      br(),
      checkboxGroupInput("dataChoice",
                         label="Données à afficher",
                         choices = c("Blocs cassés" = "broken",
                                     "Blocs posés" = "placed",
                                     "Objets fabriqués" = "created"),
                                     #"Objets consommés" = "consumed"),
                         selected = "broken"),
      br(),
      sliderInput(
        "minPercent",
        "Pourcentage minimum",
        min = 0.5,
        max = 25,
        value = 5,
        step = 0.5
      ),
      helpText("Seuls les blocs et objets dont l'utilisation est supérieure à la valeur choisie sont affichés."),
      textOutput("nbObs"),
      br(),
      checkboxInput("usePercent",
                    label="Diagramme en pourcentages",
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
      # dataAll
      data <- list(rbind(dataBofas[[1]], dataJulien[[1]]),
                   rbind(dataBofas[[2]], dataJulien[[2]]),
                   rbind(dataBofas[[3]], dataJulien[[3]]))
    }
    # Ajoute toutes les données choisies dans une liste, puis forme une data.table
    empty <- data.table(NAME=character(), COUNT=integer())
    tables <- list(empty)
    i <- 2
    if("broken" %in% input$dataChoice) {
      tables[[i]] <- data[[1]]
      i <- i+1
    }
    if("placed" %in% input$dataChoice) {
      tables[[i]] <- data[[2]]
      i <- i+1
    }
    if("created" %in% input$dataChoice) {
      tables[[i]] <- data[[3]]
      i <- i+1
    }
    #if("consumed" %in% input$dataChoice) {
    #  tables[[i]] <- data[[4]]
    #  i <- i+1
    #}
    di <- rbindlist(tables) # Faster than rbind
    
    # Fusionne les données en ajoutant le COUNT pour les mêmes valeurs de NAME
    aggregated <- di[, sum(COUNT), by=NAME]
    setnames(aggregated, "V1", "COUNT") # renomme la colonne V1=sum(COUNT) en "COUNT"
    setorder(aggregated, -COUNT) # ordre décroissant par COUNT
    return(aggregated)
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
    #data <- data[data$SIZE <= input$sup, ]
    hasBlocks <- "broken" %in% input$dataChoice || "placed" %in% input$dataChoice
    hasItems <- "created" %in% input$dataChoice # || "consumed" %in% input$dataChoice
    if(hasBlocks && hasItems) {
      title <- "Diagramme de Pareto de l'utilisation des blocs et objets"
    } else if(hasBlocks) {
      title <- "Diagramme de Pareto de l'utilisation des blocs"
    } else if(hasItems) {
      title <- "Diagramme de Pareto de l'utilisation des objets"
    } else {
      title <- "Aucune donnée"
    }
    data <- filteredData()
    if(input$usePercent) {
      a <- aes(x=reorder(NAME, -COUNT), y=COUNT/totalCount(), fill=NAME)
      end <- scale_y_continuous(label=scales::percent)
      ylabel <- "% utilisation"
    } else {
      a <- aes(x=reorder(NAME, -COUNT), y=COUNT, fill=NAME)
      end <- NULL
      ylabel <- "Nombre d'utilisations"
    }
    # Vecteur contenant les couleurs
    vColors <- dataColors$COLOR
    names(vColors) <- dataColors$NAME # vecteur nommé, avec le nom des types

    # Graphique avec ggplot2
    ggplot(data, a) +
      geom_bar(stat="identity") +
      ggtitle(title) +
      xlab("\n\nType") +
      ylab(ylabel) +
      scale_fill_manual(values = vColors, guide=F) + # guide=F supprime la légende
      theme(
        text = element_text(size=20),
        axis.text.x = element_text(angle=45,vjust=0.5)) +
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

