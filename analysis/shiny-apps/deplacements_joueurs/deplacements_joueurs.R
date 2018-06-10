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
  } else if(p > 0.0002) {
    return("#addd8e")
  } else {
    return("#3182bd")
  }
}

# -- Visu RGL --
datavizChunk3D <- function(mode, data, sleep=10000, close=F, glZFactor=1) {
  sumN <- sum(data$N)

  open3d()
  par3d(windowRect = c(200,200,1000,800))
  rgl.viewpoint(theta = 0, phi = 0, zoom = 0.5)
  bg3d("white")
  
  if (mode == "cubes") {
    print("Création des modèles de cubes pour les chunks utilisés")
    cubes<-apply(data, 1, function(row) {
      # ATTENTION : dans RGL, la hauteur est Z, alors que c'est Y dans Minecraft.
      x<-row[1] # minecraft:X
      y<-row[3] # minecraft:Z
      z<-row[2] # minecraft:Y
      n<-row[4]
      cubit <- cube3d(col = getColor(n, sumN), lit=F)
      cubit$vb[cubit$vb == -1] <- 0
      cubit$vb[1,] <- cubit$vb[1,] + x
      cubit$vb[2,] <- cubit$vb[2,] + y
      cubit$vb[3,] <- cubit$vb[3,] + z*glZFactor
      #
      #mesh<-qmesh3d(cubit$vb, cubit$ib, material=cubit$material)
      return(cubit)
    })
    print("Affichage des cubes")
    colAlpha <- 0.8
    
    # Attention ! Zone de lenteur :c
    for(cubit in cubes) {
      #wire3d(cubit, add = TRUE, color = cubit$material$col)
      shade3d(cubit, add=T, alpha=colAlpha)
      #plot3d(cubit, type="shade", add=T)
    }
    # Fin de la zone c:
  } else if(mode=="timelapse") {
    
  } else {
    data<-dataBofas
    sumN<-sum(data$N)
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

datavizChunk3D("spheres", dataBofas, sleep=0)
datavizChunk3D("points", dataBofas, sleep=0)
datavizChunk3D("cubes", dataBofas, sleep=0, glZFactor=3)
