#
# Shiny Web App - Déplacements des joueurs, visualisation 3D, version + rapide à base de spheres
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, shinyjs, RJDBC, data.table, rgl
# Working directory : dossier de l'application, avec le fichier voxel_analysis.R et avec un dossier adjacent "db_data" contenant les BDD et h2.jar
# ATTENTION : il faut un serveur d'affichage fonctionnel avec les libs de développement 3D pour que l'application fonctionne sur le serveur Shiny

library(shiny)
library(shinyjs)
library(RJDBC)
library(data.table)
library(rgl)
library(ggplot2)

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

dataBofasLog <- data.table(dbGetQuery(connBofas, sqlAllMovesFreq))
dataJulienLog <- data.table(dbGetQuery(connJulien, sqlAllMovesFreq))
dataBofasLog[, N := log10(N)+1]
dataJulienLog[, N := log10(N)+1]

dbDisconnect(connBofas)
dbDisconnect(connJulien)

#' extract Legend from ggplot2 plot 
g_legend <- function(a.gplot) { 
  tmp <- ggplot_gtable(ggplot_build(a.gplot)) 
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box") 
  legend <- tmp$grobs[[leg]] 
  return(legend)
}

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
      helpText(
        "La vue initiale est une vue de dessus. Utilisez la souris pour vous déplacer."
      ),
      br(),
      helpText("Légende :"),
      imageOutput("legend", height="120px"),
      helpText("N est le nombre de fois qu'un tronçon a été visité, c'est-à-dire qu'un joueur
               a changé de tronçon pour venir dans celui-ci.")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(rglwidgetOutput("amazing3D", width="100%"))
  )
)

# -- Serveur Shiny --
server <- function(input, output) {
  save <- options(rgl.inShiny = TRUE)
  on.exit(options(save))
  
  output$amazing3D <- renderRglwidget({
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
    }
    scatterPlot3D(data, xi=1, zi=2, yi=3, colorFunction = getColor, xlab="X",ylab="Z",zlab="Y",
                  title="Tronçons les plus fréquentés");
    s<-scene3d()
    rgl.close()
    rglwidget(s)
  })
  
  output$legend <- renderImage({
    if(input$serverChoice == "BOFAS") {
      if(input$logScale) {
        thePath<-"echelle_bofas_logn.png"
      } else {
        thePath<-"echelle_bofas_nn.png"
      }
    } else {
      if(input$logScale) {
        thePath<-"echelle_julien_logn.png"
      } else {
        thePath<-"echelle_julien_nn.png"
      }
    }
    filename <- normalizePath(file.path(getwd(), thePath))
    list(src=filename,alt="")
  }, deleteFile = FALSE)
}

# Run the application
shinyApp(ui = ui, server = server)
