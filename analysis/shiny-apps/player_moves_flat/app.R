#
# Shiny Web App - Déplacements des joueurs, visualisation 2D
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC, data.table, ggplot2
# Working directory : dossier de l'application, avec le fichier voxel_analysis.R et avec un dossier adjacent "db_data" contenant les BDD et h2.jar

library(shiny)
library(RJDBC)
library(data.table)
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

# X,Y,Z pour tout le serveur, chaque XYZ apparait une seule fois, avec son nombre d'occurences N:
sqlAllMovesFreq <- "SELECT ChunkX X, ChunkY Y, ChunkZ Z, count(*) N FROM PlayerMoves GROUP BY X,Y,Z ORDER BY N DESC"
dataBofas <- data.table(dbGetQuery(connBofas, sqlAllMovesFreq))
dataJulien <- data.table(dbGetQuery(connJulien, sqlAllMovesFreq))

nrow(dataBofas)
nrow(dataJulien)
nrow(dataBofas[N < 5])/nrow(dataBofas)
nrow(dataJulien[N < 5])/nrow(dataJulien)

nrow(dataBofas[N ==1])/nrow(dataBofas)
nrow(dataJulien[N ==1])/nrow(dataJulien)

dbDisconnect(connBofas)
dbDisconnect(connJulien)

# -- Interface Shiny --
ui <- fluidPage(
  titlePanel("Déplacements des joueurs : Visualisation 2D"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("serverChoice",
                  label="Choisissez le serveur de jeu",
                  choices = list("BOFAS", "Julien"),
                  selected = "Julien"),
      br(),
      sliderInput("y",
                  "Couche Y à afficher",
                  min=0,
                  max=16,
                  value=4),
      br(),
      checkboxInput("logScale",
                    "Échelle logarithmique",
                    value = TRUE),
      checkboxInput("relativeScale",
                    "Échelle relative à cette couche Y",
                    value = FALSE),
      checkboxInput("autoZoom",
                    "Zoomer sur les chunks utilisés (déforme le rendu)",
                    value=FALSE)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(plotOutput("rasterPlot", width="100%", height="700px"))
  )
)

# -- Serveur Shiny --
server <- function(input, output) {
  output$rasterPlot <- renderPlot({
    if(input$serverChoice == "Julien") {
      fullData <- dataJulien
    } else {
      fullData <- dataBofas
    }
    data <- fullData[Y == input$y]
    title <- sprintf("Utilisation des tronçons X,Z pour Y=%i", input$y)
    
    if(input$logScale) {
      aes<-aes(X, Z, fill=log10(N))
    } else {
      aes<-aes(X, Z, fill=N)
    }

    if(nrow(data) == 0) {
      ggplot(data, aes) + geom_raster() +
        ggplot2::xlab("Tronçon X") +
        ggplot2::ylab("Tronçon Z") +
        ggtitle(paste(title, "(aucun déplacement dans cette zone)")) +
        theme(
          text = element_text(size=18),
          axis.text.x = element_text(angle=45,vjust=0.5)
        )
    } else {
      if(input$relativeScale) {
        cMin<-colorMin
        cMid<-colorMid
        cMax<-colorMax
      } else if(input$logScale){
        cMin<-colorGradient(1-(min(1+log10(data$N))/min(1+log10(fullData$N))))
        cMid<-colorGradient(0.5*(max(1+log10(data$N))/max(1+log10(fullData$N))))
        cMax<-colorGradient(max(1+log10(data$N))/max(1+log10(fullData$N)))
      } else {
        cMin<-colorGradient(1-(min(data$N)/min(fullData$N)))
        cMid<-colorGradient(0.5*(max(data$N)-min(data$N))/(max(fullData$N)-min(fullData$N)))
        cMax<-colorGradient(max(data$N)/max(fullData$N))
      }
      
      if(!input$autoZoom) {
        xMin <- min(fullData$X)
        xMax <- max(fullData$X)
        zMin <- min(fullData$Z)
        zMax <- max(fullData$Z)
        min <- min(xMin, zMin)
        max <- max(xMax, zMax)
        coord <- coord_equal(xlim=c(min, max), ylim=c(min, max))
      } else {
        coord <- NULL
      }
      ggplot(data, aes) +
        geom_tile(color="black") +
        scale_fill_gradientn(colors=c(cMin, cMid, cMax)) +
        ggplot2::xlab("Coordonnée X") +
        ggplot2::ylab("Coordonnée Z") +
        ggtitle(title) +
        theme(
          text = element_text(size=18),
          axis.text.x = element_text(angle=45,vjust=0.5)
        ) +
        coord
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

