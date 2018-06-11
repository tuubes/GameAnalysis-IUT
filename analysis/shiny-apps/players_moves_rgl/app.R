#
# Shiny Web App - Déplacements des joueurs, visualisation 3D
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, shinyjs, RJDBC, data.table, rgl
# Working directory : dossier de l'application, avec un dossier adjacent "db_data" contenant les BDD et h2.jar
# ATTENTION : il faut un serveur d'affichage fonctionnel avec les libs de développement 3D pour que l'application fonctionne sur le serveur Shiny

library(shiny)
library(shinyjs)
library(RJDBC)
library(data.table)
library(rgl)

source("../voxel_analysis.R")

# -- Récupération des données depuis la BDD H2 ---
print("Récupération des données depuis la BDD H2")
driverH2 <- sprintf("%s/../db_data/h2.jar", getwd())
dbBofas <- sprintf("%s/../db_data/database_bofas", getwd())
dbJulien <- sprintf("%s/../db_data/database_julien", getwd())

drv <- JDBC(driverClass = "org.h2.Driver", classPath = driverH2, identifier.quote="`")
connBofas <- dbConnect(drv, paste("jdbc:h2:", dbBofas, sep=""), "", "")
connJulien <- dbConnect(drv, paste("jdbc:h2:", dbJulien, sep=""), "", "")

dbGetQuery(connBofas, "SHOW TABLES")
dbGetQuery(connJulien, "SHOW TABLES")

# X,Y,Z pour tout le serveur, 1 XYZ par ligne
sqlAllMoves <- "SELECT ChunkX X, ChunkY Y, ChunkZ Z FROM PlayerMoves"
# X,Y,Z pour tout le serveur, chaque XYZ apparait une seule fois, avec son nombre d'occurences N:
sqlAllMovesFreq <- "SELECT ChunkX X, ChunkY Y, ChunkZ Z, count(*) N FROM PlayerMoves GROUP BY X,Y,Z ORDER BY N DESC"
dataBofas <- data.table(dbGetQuery(connBofas, sqlAllMovesFreq))
dataJulien <- data.table(dbGetQuery(connJulien, sqlAllMovesFreq))

dataBofasLog <- dataBofas
dataJulienLog <- dataJulien
dataBofasLog[, N := log10(N)+1]
dataJulienLog[, N := log10(N)+1]

dbDisconnect(connBofas)
dbDisconnect(connJulien)

# -- Interface Shiny --
ui <- fluidPage(
  # ShinyJS permet d'améliorer l'expérience Shiny, notamment en activant et désactivant les éléments
  useShinyjs(),
  titlePanel("Déplacements des joueurs : Visualisation 3D"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("serverChoice",
                  label="Choisissez le serveur de jeu",
                  choices = list("BOFAS", "Julien"),
                  selected = "Julien"),
      br(),
      checkboxInput("logScale",
                    "Échelle logarithmique",
                    value = TRUE),
      checkboxInput("spaceY",
                    "Espacer les couches Y",
                    value = TRUE),
      helpText(
        "La génération du modèle 3D peut prendre jusqu'à 30 secondes, merci de bien vouloir patienter."
      ),
      helpText(
        "La vue initiale est une vue de dessus. Utilisez la souris pour vous déplacer."
      )
    ),
    
    # Show a plot of the generated distribution
    mainPanel(rglwidgetOutput("amazing3D", width="100%"))
  )
)

# -- Serveur Shiny --
# Cache des visualisation 3D
# BOFAS, logScale=FALSE, spaceY=FALSE -> 1
# BOFAS,logScale=FALSE, spaceY=TRUE -> 2
# BOFAS,logScale=TRUE, spaceY=FALSE -> 3
# BOFAS,logScale=TRUE, spaceY=TRUE -> 4
# Julien, logScale=FALSE, spaceY=FALSE -> 5
# Julien,logScale=FALSE, spaceY=TRUE -> 6
# Julien,logScale=TRUE, spaceY=FALSE -> 7
# Julien,logScale=TRUE, spaceY=TRUE -> 8
glCache <- vector(mode="list", length=8)
server <- function(input, output) {
  save <- options(rgl.inShiny = TRUE)
  on.exit(options(save))
  
  cachedScene <- reactive({
    if(!input$logScale && !input$spaceY) {
      cacheIdx <- 1
    } else if(!input$logScale && input$spaceY) {
      cacheIdx <- 2
    } else if(input$logScale && !input$spaceY) {
      cacheIdx <- 3
    } else {
      cacheIdx <- 4
    }
    if(input$serverChoice == "BOFAS") {
      if(input$logScale) {
        data <- dataBofasLog
      } else {
        data <- dataBofas
      }
    } else {
      if(input$logScale) {
        data <- dataJulienLog
      } else {
        data <- dataJulien
      }
      cacheIdx <- cacheIdx + 4
    }
    if(input$spaceY) {
      zFactor <- 3
    } else {
      zFactor <- 1
    }
    if(input$logScale) {
      subtitle <- "Couleurs en fonction de log10(N)"
    } else {
      subtitle <- "Couleurs en fonction de N"
    }
    print(paste("cacheIdx:", cacheIdx))
    print(glCache)
    scene <- glCache[[cacheIdx]]
    if(is.null(scene)) {
      # Barre de progression
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      nbSteps <- nrow(data) + 1
      progress$set(message="Génération des cubes colorés...", value=0)
      
      # Désactivation des inputs pour éviter les bugs
      shinyjs::disable("serverChoice")
      shinyjs::disable("logScale")
      shinyjs::disable("spaceY")
      
      # Génération 3D et mise à jour de la progression
      rgl3D(data, xi=1, zi=2, yi=3, zf=zFactor, colorFunction=getColor,
            xlab="X", ylab="Z", zlab="Y", subtitle=subtitle,
            title="Déplacements des joueurs", notifyProgressFunction = function(x,y,z) {
              progress$inc(1/nbSteps, detail=sprintf("Tronçon (%i, %i, %i)", x, y, z))
            })
      progress$inc(0, message="Enregistrement des données...", detail="")
      scene <- scene3d()
      rgl.close()
      glCache[[cacheIdx]] <<- scene # <<- permet de modifier la variable dans l'environnement parent au lieu de modifier la référence locale
      shinyjs::enable("serverChoice")
      shinyjs::enable("logScale")
      shinyjs::enable("spaceY")
      progress$inc(1/nbSteps)
    }
    return(scene)
  })
  
  output$amazing3D <- renderRglwidget({
    rglwidget(x=cachedScene())
  })
}

# Run the application
shinyApp(ui = ui, server = server)
