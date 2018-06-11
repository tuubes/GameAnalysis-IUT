#!/usr/bin/Rscript
#
# RGL Déplacements des joueurs, visualisation 3D
# (c) Guillaume Raffin 2018
#
# Packages nécessaires : RJDBC, data.table, rgl
# Working directory : dossier de l'application, avec un dossier adjacent "db_data" contenant les BDD et h2.jar
# ATTENTION : il faut un serveur d'affichage fonctionnel avec les libs de développement 3D pour que l'application fonctionne sur le serveur Shiny

#library(shiny)
library(RJDBC)
library(data.table)
library(rgl)
library(plot3D)
library(raster)

mode <- "cubic" # cubes, spheres, points
cubeSparseFactor <- 2

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

# X,Y,Z,N pour tout le serveur, avec le temps où le chunk est visité pour la première fois
sqlAllMovesFreqTime <- "SELECT ChunkX X, ChunkY Y, ChunkZ Z, count(*) N, min(Time) T FROM PlayerMoves GROUP BY X,Y,Z ORDER BY T ASC"
dataBofasTime <- data.table(dbGetQuery(connBofas, sqlAllMovesFreqTime))
dataJulienTime <- data.table(dbGetQuery(connJulien, sqlAllMovesFreqTime))

sqlPlayers <- "SELECT distinct(PlayerId) PLAYER FROM PlayerMoves"
playersBofas <- data.table(dbGetQuery(connBofas, sqlPlayers))
playersJulien <- data.table(dbGetQuery(connJulien, sqlPlayers))

dbDisconnect(connBofas)
dbDisconnect(connJulien)

# Couleurs
print("Génération des couleurs")
maxBofas <- apply(dataBofas, 2, max)
minBofas <- apply(dataBofas, 2, min)
sumBofas <- sum(dataBofas$N)
maxJulien <- apply(dataJulien, 2, max)
minJulien <- apply(dataJulien, 2, min)
sumJulien <- sum(dataJulien$N)

#paletteGenerator <- colorRampPalette(c("#3182bd","#e6550d", "#de2d26"), interpolate="linear")
#colorsBofas <- paletteGenerator(maxBofas[4])
#colorsJulien <- paletteGenerator(maxJulien[4])

getColor <- function(n, sumN) {
  p<-n/sumN
  if(p > 0.02) {
    return("#de2d26")
  } else if(p > 0.002) {
    return("#ffeda0")
  } else if(n > 2) {#0.0002) {
    return("#addd8e")
  } else {
    return("#3182bd")
  }
}

data<-dataBofasTime
data<-dataJulienTime
glZFactor=3
# -- Visu RGL --
datavizChunk3D <- function(mode, data, sleep=10000, close=F, glZFactor=1) {
  sumN <- sum(data$N)

  open3d()
  par3d(windowRect = c(200,200,1000,800))
  view3d(theta = 0, phi = 0)
  rgl.pop("lights") # remove the current light sources
  light3d(theta=0, phi=0, viewpoint.rel=TRUE, ambient="white")
  bg3d("white")
  
  if (mode == "cubes") {
    print("Création des modèles de cubes pour les chunks utilisés")
    cube0 <- cube3d(lit=slow, smooth=TRUE, fog=FALSE)
    cube0$vb[cube0$vb == -1] <- 0
    cubes<-apply(data, 1, function(row) {
      # ATTENTION : dans RGL, la hauteur est Z, alors que c'est Y dans Minecraft.
      x<-row[1] # minecraft:X
      y<-row[3] # minecraft:Z
      z<-row[2] # minecraft:Y
      n<-row[4]
      #print(paste(x,y,z))
      cube <- translate3d(cube0, x,y,z*glZFactor)
      cube$material$col <- getColor(n, sumN)
      return(cube)
    })
    print("Affichage des cubes")
    
    # Attention ! Zone de lenteur :c
    for(cubit in cubes) {
      wire3d(cubit, add=TRUE, color = rgb(0,0,0))
      shade3d(cubit, add=TRUE, alpha=1)
      #plot3d(cubit, type="shade", add=T)
    }
    # Fin de la zone c:
  } else {
    vColors <- lapply(data$N, function(n) getColor(n, sumN))
    if(mode =="points") {
      plot3d(x=data$X, y=data$Z, z=data$Y, col=vColors, type="p", size=5)
    } else {
      plot3d(x=data$X, y=data$Z, z=data$Y, col=vColors, type="s", radius=0.5, top=T)
    }
  }
  print("Ajout d'un titre et d'axes")
  title3d("Déplacements des joueurs", xlab="X", ylab="Z", zlab="Y")
  axes3d("x")
  axes3d("y")
  axes3d("z")
  
  Sys.sleep(sleep)
  
  if (close) {
    print("Closing rgl")
    rgl.close()
  }
}

datavizChunk3D("spheres", data, sleep=0)
datavizChunk3D("points", data, sleep=0)
datavizChunk3D("cubes", data, sleep=0, glZFactor=1)
system.time(datavizChunk3D("cubes", data, sleep=0, glZFactor=1))

