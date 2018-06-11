#
# Shiny Web App - Blocs et items, stats bivariées (type + temps de jeu)
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC, data.table, ggplot2, rlist
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

# Découpage par demi-heure :
# 20 ticks par seconde * 1 heure = 20*3600 = 72000 ticks
ppt <- "(PlayerPlayTime/72000)"
sqlBroken <- sprintf("SELECT Name, %s AS PPT, count(*) AS Count FROM BrokenBlocks B, ItemRegistry I WHERE B.Id = I.Id GROUP BY Name, %s ORDER BY %s", ppt, ppt, ppt)
sqlBroken <- sprintf("SELECT Name, %s AS PPT, count(*) AS Count FROM BrokenBlocks B, ItemRegistry I WHERE B.Id = I.Id GROUP BY Name, %s ORDER BY %s", ppt, ppt, ppt)
sqlPlaced <- sprintf("SELECT Name, %s AS PPT, count(*) AS Count FROM PlacedBlocks B, ItemRegistry I WHERE B.Id = I.Id GROUP BY Name, %s ORDER BY %s", ppt, ppt, ppt)
sqlCreated <- sprintf("SELECT Name, %s AS PPT, sum(Amount) AS Count FROM CreatedItems C, ItemRegistry I WHERE C.Id = I.Id GROUP BY Name, %s ORDER BY %s", ppt, ppt, ppt)
#sqlConsumed <- "SELECT Name, count(C.Id) AS Count FROM ConsumedItems C, ItemRegistry I WHERE C.Id = I.Id GROUP BY Name ORDER BY count(C.Id) DESC"
# on a trop peu de données pour les objets consommés

sqlBrokenNames <- "SELECT distinct(Name) FROM BrokenBlocks B, ItemRegistry I WHERE B.Id = I.Id"
sqlPlacedNames <- "SELECT distinct(Name) FROM PlacedBlocks B, ItemRegistry I WHERE B.Id = I.Id"
sqlCreatedNames <- "SELECT distinct(Name) FROM CreatedItems C, ItemRegistry I WHERE C.Id = I.Id"

padWithZeros <- function(dataTable, minPPT, maxPPT, names) {
  # Remplit de zéros les plages sans données, pour que chaque NAME ait exactement une occurence par PPT
  # Exemple d'utilisation: padWithZeros(dataBofas[[1]], 0, maxPPT, namesBofas[[1]]$NAME)
  
  # (((Ancienne version moins opti)))
  # Etape 1: ajout des nouvelles lignes, avec COUNT=NA
  # newRows <- list(dataTable)
  # i <- 2
  # for(n in names) {
  #   for(t in minPPT:maxPPT) {
  #     newRows[[i]] <- data.frame(NAME=n, PPT=t, COUNT=NA)
  #     i <- i+1
  #   }
  # }
  # newData <- rbindlist(newRows)
  # Etape 2: transformation magique des NA en zéros
  # dataTable[is.na(dataTable[["COUNT"]]), "COUNT" := 0]
  
  # (((Nouvelle version opti avec les opérations de data.frame)))
  # Etape 1 : ajoute des lignes avec COUNT=0 pour chaque NAME et PPT
  range <- maxPPT-minPPT+1
  nbNames <- length(names)
  l <- list(dataTable, data.table(NAME=rep(names,each=range), PPT=rep(minPPT:maxPPT, times=nbNames), COUNT=0))
  newData <- rbindlist(l)

  # Etape 2 : Fusionne les données en ajoutant le COUNT pour les mêmes valeurs de PPT et NAME
  merged <- newData[, sum(COUNT), by=list(NAME, PPT)]
  return(merged)
}

dataBofas <- list(dbGetQuery(connBofas, sqlBroken),
                  dbGetQuery(connBofas, sqlPlaced),
                  dbGetQuery(connBofas, sqlCreated)
                  #,dbGetQuery(connBofas, sqlConsumed)
)

namesBofas <- list(dbGetQuery(connBofas, sqlBrokenNames),
                  dbGetQuery(connBofas, sqlPlacedNames),
                  dbGetQuery(connBofas, sqlCreatedNames)
                  #,dbGetQuery(connBofas, sqlConsumed)
)
allNamesBofas <- unique(unlist(sapply(namesBofas, function(table) table$NAME)))

dataJulien <- list(dbGetQuery(connJulien, sqlBroken),
                   dbGetQuery(connJulien, sqlPlaced),
                   dbGetQuery(connJulien, sqlCreated)
                   #,dbGetQuery(connJulien, sqlConsumed)
)
namesJulien <- list(dbGetQuery(connJulien, sqlBrokenNames),
                   dbGetQuery(connJulien, sqlPlacedNames),
                   dbGetQuery(connJulien, sqlCreatedNames)
                   #,dbGetQuery(connJulien, sqlConsumed)
)
allNamesJulien <- unique(unlist(sapply(namesJulien, function(table) table$NAME)))
allNamesCombined <- unique(c(allNamesBofas, allNamesJulien))

maxPPTBofas <- max(sapply(dataBofas, function(table) max(table$PPT)))
maxPPTJulien <- max(sapply(dataJulien, function(table) max(table$PPT)))
maxPPTCombined <- max(maxPPTBofas, maxPPTJulien) # le plus grand PPT trouvé dans chaque table de dataBofas et dataJulien

assertthat::are_equal(length(dataBofas), length(dataJulien))
for(i in 1:length(dataBofas)) {
  dataBofas[[i]] <- padWithZeros(dataBofas[[i]], 0, maxPPTCombined, allNamesCombined)
  dataJulien[[i]] <- padWithZeros(dataJulien[[i]], 0, maxPPTCombined, allNamesCombined)
}
# ne fonctionne pas comme attendu:
# dataBofas <- sapply(dataBofas, function(table) padWithZeros(table, 0, maxPPTCombined, allNamesCombined), simplify="array")
# dataJulien <- sapply(dataJulien, function(table) padWithZeros(table, 0, maxPPTCombined, allNamesCombined))

dataColors <- dbGetQuery(connBofas, "SELECT Name, Color FROM ItemRegistry")
vColors <- dataColors$COLOR # Vecteur contenant les couleurs
names(vColors) <- dataColors$NAME # nomme le vecteurs de couleurs avec le nom des types

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
      selectInput("typeChoice",
                  label="Types à afficher",
                  choices = list("Stone", "Wood", "Torch"), # les choix seront calculés en fonction de dataChoice
                  selected = list("Stone", "Wood", "Torch"),
                  multiple = TRUE),
      br(),
      sliderInput(
        "timeRange",
        "Temps de jeu (heures)",
        min = 0,
        max = 100,
        value = c(0,10),
        step = 1
      ),
      checkboxInput("useGameColors",
                    label="Utiliser les couleurs du jeu pour les types d'objets/blocs",
                    value=FALSE)
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
    empty <- data.table(NAME=character(), PPT=integer(), COUNT=integer())
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
    
    # Fusionne les données en ajoutant le COUNT pour les mêmes valeurs de PPT et NAME
    aggregated <- di[, sum(COUNT), by=list(NAME, PPT)]
    setnames(aggregated, "V1", "COUNT") # renomme la colonne V1=sum(COUNT) en "COUNT"
    #setorder(aggregated, PPT, -COUNT) # ordre croissant par PPT et, en second, décroissant par COUNT
    
    # Mets à jour la liste des types
    types <- unique(aggregated$NAME)
    oldSelection <- input$typeChoice
    updateSelectInput(session, "typeChoice", choices=types, selected=intersect(types, oldSelection))
    return(aggregated)
  })
  filteredData <- reactive({
    # Ne garde que les types choisis par l'utilisateur
    aggregated <- dataInput()
    filtered <- aggregated[NAME %in% input$typeChoice]
    
    if(nrow(filtered) > 0) {
      if(input$serverChoice == "BOFAS") {
        maxTime <- maxPPTBofas # max(filtered$PPT)
      } else if(input$serverChoice == "Julien") {
        maxTime <- maxPPTJulien
      } else {
        maxTime <- maxPPTCombined
      }
      
      if(input$timeRange[2] == 0) {
        updateSliderInput(session, "timeRange", max=maxTime, value=c(0,maxTime))
      } else {
        updateSliderInput(session, "timeRange", max=maxTime)
      }
    } else {
      updateSliderInput(session, "timeRange", max=0)
    }
    
    rangeMin <- input$timeRange[1]
    rangeMax <- input$timeRange[2]
    filtered <- filtered[PPT >= rangeMin][PPT <= rangeMax]
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
      title <- "Graphique chronologique de l'utilisation des blocs et objets"
    } else if(hasBlocks) {
      title <- "Graphique chronologique de l'utilisation des blocs"
    } else if(hasItems) {
      title <- "Graphique chronologique de l'utilisation des objets"
    } else {
      title <- "Aucune donnée"
    }
    data <- filteredData()
    
    if(input$useGameColors) {
      coloration <- scale_color_manual(values = vColors)
    } else {
      coloration <- scale_color_discrete()
    }
    
    # Graphique avec ggplot2
    ggplot(data, aes(x=PPT, y=COUNT, group=NAME, color=NAME)) +
      geom_line() +
      geom_point() +
      ggtitle(title) +
      xlab("Temps de jeu du joueur sur ce serveur (heures)") +
      ylab("Nombre d'utilisations") +
      coloration +
      theme(
        text = element_text(size=18),
        legend.key.width = unit(50, "pt")
      ) # legend.position = "bottom"
  })
}

# -- Lancement de l'app --
shinyApp(ui = ui, server = server)

