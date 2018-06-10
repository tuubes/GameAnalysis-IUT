#
# Shiny Web App - Déplacements des joueurs, visualisation 3D
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : shiny, RJDBC, data.table, rgl
# Working directory : dossier de l'application, avec un dossier adjacent "db_data" contenant les BDD et h2.jar
# ATTENTION : il faut un serveur d'affichage fonctionnel avec les libs de développement 3D pour que l'application fonctionne sur le serveur Shiny

library(shiny)
library(RJDBC)
library(data.table)
library(rgl)

# -- Récupération des données depuis la BDD H2 ---
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

dbDisconnect(connBofas)
dbDisconnect(connJulien)

# Couleurs
maxBofas <- max(dataBofas$N)
maxJulien <- max(dataJulien$N)
paletteGenerator <- colorRampPalette(c("#3182bd","#e6550d", "#de2d26"), interpolate="linear")
colorsBofas <- paletteGenerator(maxBofas)
colorsJulien <- paletteGenerator(maxJulien)

# -- Test RGL --
open3d()
par3d(windowRect = c(200,200,1000,800))
rgl.viewpoint(theta = 0, phi = 0, zoom = 0.5)
bg3d("white")
cubes<-apply(dataBofas, 1, function(row) {
  # ATTENTION : dans RGL, la hauteur est Z, alors que c'est Y dans Minecraft.
  x<-row[1] # minecraft:X
  y<-row[3] # minecraft:Z
  z<-row[2] # minecraft:Y
  n<-row[4]
  cubit <- cube3d(col = colorsBofas[n], size=16, lit=F)
  cubit$vb[cubit$vb == -1] <- 0
  cubit$vb[1,] <- cubit$vb[1,] + x
  cubit$vb[2,] <- cubit$vb[2,] + y
  cubit$vb[3,] <- cubit$vb[3,] + z
  cubit$vb[4,] <- cubit$vb[4,]
  return(cubit)
})
colAlpha <- 0.8
for(cubit in cubes) {
  #shade3d(cubit, add = TRUE, alpha = 0.5)
  #wire3d(cubit, add = TRUE, color = cubit$material$col)
  shade3d(cubit, add=T, alpha=colAlpha)
  wire3d(cubit, add=T, alpha=colAlpha)
}
cubes[1:200]$col = rgb("black")
title3d("Déplacements des joueurs", xlab="X", ylab="Y (mc: Z)", zlab="Z (mc: Y)")
axes3d("x")
axes3d("y")
axes3d("z")
rgl.viewpoint(theta = 0, phi = 0, zoom = 1)
rgl.close()


# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Old Faithful Geyser Data"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         sliderInput("bins",
                     "Number of bins:",
                     min = 1,
                     max = 50,
                     value = 30)
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("distPlot")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$distPlot <- renderPlot({
      # generate bins based on input$bins from ui.R
      x    <- faithful[, 2] 
      bins <- seq(min(x), max(x), length.out = input$bins + 1)
      
      # draw the histogram with the specified number of bins
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

