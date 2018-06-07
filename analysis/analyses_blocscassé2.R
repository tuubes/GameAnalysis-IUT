

# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database_julien" # Chemin de la base de données, sans le .mv.db à la fin
dbmsPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2.jar" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
# Comptage des blocs placés, avec leur nom
dbGetQuery(conn, "SELECT count(*) FROM placedblocks")
data <- dbGetQuery(conn,
                   "SELECT ID, PlayerPlayTime FROM PlacedBlocks

ORDER BY PlayerPlayTime ASC")
#View(data)
data$PLAYERPLAYTIME<-cut(data$PLAYERPLAYTIME, breaks=seq(0,max(data$PLAYERPLAYTIME)+72000,72000))


