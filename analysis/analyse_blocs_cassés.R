### Analyse bofas

# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database_bofas" # Chemin de la base de données, sans le .mv.db à la fin
dbmsPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2.jar" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
# Comptage des blocs placés, avec leur nom
dbGetQuery(conn, "SELECT count(*) FROM BrokenBlocks")
1
# Nombre de blocs différents
n <- dbGetQuery(conn, "SELECT count(distinct(Id)) FROM BrokenBlocks")
n

# On ne met dans le graphique que les blocs placés >= a fois
a <- 7
biggestData <- data[data$`COUNT(BROKENBLOCKS.ID)`>=a, ]
smallestData <- data[data$`COUNT(BROKENBLOCKS.ID)`<a, ]

barplot(names.arg=biggestData$NAME, height=biggestData$`COUNT(BROKENBLOCKS.ID)`, las=3, col="skyblue", main="Blocs cassés plus de 7 fois")
#View(smallestData)

limit <- 10
headData <- head(data, limit)
barplot(names.arg=headData$NAME, height=headData$`COUNT(BROKENBLOCKS.ID)`, las=3,
        col="skyblue", main="Les 10 blocs les plus détruits",
        ylab="Nombre de destructions", cex.names=0.8)


# --- Déconnexion de la BDD ---
dbDisconnect(conn)



### Analyse Julien 

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
dbGetQuery(conn, "SELECT count(*) FROM BrokenBlocks")
1
# Nombre de blocs différents
n <- dbGetQuery(conn, "SELECT count(distinct(Id)) FROM BrokenBlocks")
n

# On ne met dans le graphique que les blocs placés >= a fois
a <- 7
biggestData <- data[data$`COUNT(BROKENBLOCKS.ID)`>=a, ]
smallestData <- data[data$`COUNT(BROKENBLOCKS.ID)`<a, ]

barplot(names.arg=biggestData$NAME, height=biggestData$`COUNT(BROKENBLOCKS.ID)`, las=3, col="skyblue", main="Blocs cassés plus de 7 fois")
#View(smallestData)

limit <- 10
headData <- head(data, limit)
barplot(names.arg=headData$NAME, height=headData$`COUNT(BROKENBLOCKS.ID)`, las=3,
        col="skyblue", main="Les 10 blocs les plus détruits",
        ylab="Nombre de destructions", cex.names=0.8)

# --- Déconnexion de la BDD ---
dbDisconnect(conn)

