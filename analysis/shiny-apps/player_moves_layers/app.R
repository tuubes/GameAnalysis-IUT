#
# Shiny Web App - Déplacements des joueurs, statistiques par couches Y=k
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
sqlAllMovesFreq <- "SELECT ChunkY Y, count(*) N FROM PlayerMoves GROUP BY Y ORDER BY N DESC"
dataBofas <- data.table(dbGetQuery(connBofas, sqlAllMovesFreq))
dataJulien <- data.table(dbGetQuery(connJulien, sqlAllMovesFreq))

layersBofas <- sort.int(unique(dataBofas[dataBofas$N > 0]$Y), decreasing=TRUE)
layersJulien <- sort.int(unique(dataJulien[dataJulien$N > 0]$Y), decreasing=TRUE)

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
      checkboxInput("usePercent",
                    "En pourcentages",
                    value=TRUE)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(plotOutput("layersGram"), width="600px")
  )
)

# -- Serveur Shiny --
server <- function(input, output) {
  output$layersGram <- renderPlot({
    if(input$serverChoice == "Julien") {
      data <- dataJulien
    } else {
      data <- dataBofas
    }
    if(input$usePercent) {
      ylabel<-"Proportion des déplacements dans la couche Y"
      aest<-aes(Y, N/sum(data$N))
      #above<-aes(x=Y, y=0, label=paste(format(round(N*100/sum(data$N), 2), nsmall=2), "%"), hjust=-0.7)
      above<-aes(label=paste(
                        format(round(N*100/sum(data$N), 2), nsmall=2),
                        "%")
                )
    } else {
      aest<-aes(Y, N)
      ylabel<-"Nombre de déplacement dans la couche Y"
      above<-aes(label=paste("", N))
    }
    ggplot(data, aest) +
      geom_bar(data=data, stat="identity", position="dodge", fill="skyblue") +
      geom_text(above, data=data[Y != 4], position=position_dodge(width=0.9), hjust=-0.1) +
      geom_text(above, data=data[Y==4], position=position_dodge(width=0.9), hjust=+1.1) +
      scale_x_continuous(breaks = layersBofas, minor_breaks = c()) +
      ylab(ylabel) +
      xlab("Y") +
      ggtitle("Diagramme en barre des déplacements pour chaque valeur de Y") +
      theme(
        text = element_text(size=18),
        plot.margin = unit(c(1,1,1,1), "cm")
      ) +
      coord_flip()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

