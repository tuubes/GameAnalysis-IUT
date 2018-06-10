# Utilitaires pour la visualisation de déplacements 3D par tronçons
# (c) Guillaume Raffin 2018
#
library(RJDBC)
library(data.table)
library(ggplot2)
source("voxel_analysis.R")

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

# -- Couleurs en fonction de N --
getColor <- function(n, nMin, nMax) {
  p<-n/nMax
  if(p > 0.25) {
    return("#de2d26")
  } else if(p > 0.05) {
    return("#ffeda0")
  } else if(p > 0.005) {
    return("#addd8e")
  } else if(n > 0) {
    return("#3182bd")
  } else {
    return("#ffffff")
  }
}

# -- TEST Rgl3D --
rgl3D(dataJulienTime, xi=1, zi=2, yi=3, colorFunction = getColor)#, notifyProgressFunction = function(x,y,z) print(paste(x,y,z)))
system.time({
  rgl3D(dataJulienTime, xi=1, zi=2, yi=3, colorFunction = getColor)
})

# -- TEST ScatterPlot --
scatterPlot3D(dataJulien, xi=1, zi=2, yi=3, colorFunction=getColor)

# -- TEST Image2D --
image2D(dataJulien[Y == 3], xi=1, yi=3, ni=4, colorFunction = getColor, ylab="Z", # couleurs relatives à l'étage Y
        xMin=min(dataJulien$X), xMax=max(dataJulien$X),
        yMin=min(dataJulien$Z), yMax=max(dataJulien$Z))
title("Couche ChunkY = 3, intensité relative")
image2D(dataJulien[Y == 3], xi=1, yi=3, ni=4, colorFunction = getColor, ylab="Z",
        xMin=min(dataJulien$X), xMax=max(dataJulien$X),
        yMin=min(dataJulien$Z), yMax=max(dataJulien$Z),
        nMin=min(dataJulien$N), nMax=max(dataJulien$N)) # couleurs absolues, par rapport à toutes la map
title("Couche ChunkY = 3, intensité absolue")


xMinJ=min(dataJulien$X); xMaxJ=max(dataJulien$X)
yMinJ=min(dataJulien$Z); yMaxJ=max(dataJulien$Z)
image2D(dataJulien[Y == 4], xi=1, yi=3, ni=4, colorFunction = getColor, ylab="Z",
        xMin=min(xMinJ, yMinJ), xMax=max(xMaxJ, yMaxJ),
        yMin=min(xMinJ, yMinJ), yMax=max(xMaxJ, yMaxJ)) # couleurs absolues, par rapport à toutes la map
title("Couche ChunkY = 4, intensité relative")
image2D(dataJulien[Y == 4], xi=1, yi=3, ni=4, colorFunction = getColor, ylab="Z",
        xMin=min(xMinJ, yMinJ), xMax=max(xMaxJ, yMaxJ),
        yMin=min(xMinJ, yMinJ), yMax=max(xMaxJ, yMaxJ),
        nMin=min(dataJulien$N), nMax=max(dataJulien$N)) # couleurs absolues, par rapport à toutes la map
title("Couche ChunkY = 4, intensité absolue")

# -- TEST ggplot2 --
ggplot(dataJulien[Y == 4], aes(X, Z, fill=log10(N))) +
  geom_raster()

ggplot(dataJulien[Y == 4], aes(X, Z, fill=log10(N))) +
  geom_raster() +
  scale_fill_gradientn(colors=c("#3182bd", "#addd8e", "#de2d26"))

ggplot(dataJulien[Y == 4], aes(X, Z, fill=log10(N))) +
  geom_raster() +
  scale_fill_gradientn(colors=c("#3182bd", "#addd8e", "#de2d26"), guide="legend")

f<-scales::gradient_n_pal(c("#3182bd", "#addd8e", "#de2d26"))
f(0.5)
# La fonction gradient_n_pal retourne une fonction x->couleur pour x € [0;1]