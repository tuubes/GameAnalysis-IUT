# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "C:/Users/pontcl/Downloads/database_bofas.mv.db" # Chemin de la base de données, sans le .mv.db à la fin
dbmsPath <- "C:/Users/pontcl/Downloads/database_bofas.mv.db" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
# Comptage des blocs placés, avec leur nom
dbGetQuery(conn, "SELECT count(*) FROM placedblocks")
data <- dbGetQuery(conn,
"SELECT ID, count(PlacedBlocks.Id) FROM PlacedBlocks
GROUP BY ID
ORDER BY count(PlacedBlocks.Id) DESC")
#View(data)

# Nombre de blocs différents
n <- dbGetQuery(conn, "SELECT count(distinct(Id)) FROM PlacedBlocks")
n

# On ne met dans le graphique que les blocs placés >= a fois
a <- 7
biggestData <- data[data$`COUNT(PLACEDBLOCKS.ID)`>=a, ]
smallestData <- data[data$`COUNT(PLACEDBLOCKS.ID)`<a, ]
barplot(names.arg=biggestData$NAME, height=biggestData$`COUNT(PLACEDBLOCKS.ID)`, las=3, col="skyblue", main="Blocs posés plus de 7 fois")
#View(smallestData)

limit <- 10
headData <- head(data, limit)
barplot(names.arg=headData$NAME, height=headData$`COUNT(PLACEDBLOCKS.ID)`, las=3,
        col="skyblue", main="Les 10 blocs les plus placés",
        ylab="Nombre de placements", cex.names=0.8)


# --- Déconnexion de la BDD ---
dbDisconnect(conn)