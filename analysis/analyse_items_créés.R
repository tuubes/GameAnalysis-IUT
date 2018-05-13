# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "/home/guillaume/database" # Chemin de la base de données, sans le .mv.db à la fin
dbmsPath <- "/home/guillaume/h2.jar" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
# Comptage des items créés, avec leur nom
dbGetQuery(conn, "SELECT sum(Amount) FROM CreatedItems")
data <- dbGetQuery(conn,
"SELECT Name, sum(Amount) FROM CreatedItems, ItemRegistry
WHERE CreatedItems.Id = ItemRegistry.Id
GROUP BY CreatedItems.Id
ORDER BY sum(Amount) DESC")
#View(data)

# Nombre d'items différents
n <- dbGetQuery(conn, "SELECT count(distinct(Id)) FROM CreatedItems")
n

# On ne met dans le graphique que les items créés >= a fois
a <- 7
biggestData <- data[data$`SUM(AMOUNT)`>=a, ]
smallestData <- data[data$`SUM(AMOUNT)`<a, ]
barplot(names.arg=biggestData$NAME, height=biggestData$`SUM(AMOUNT)`, las=3, col="skyblue", main="Items créés plus de 7 fois")
#View(smallestData)

limit <- 10
headData <- head(data, limit)
barplot(names.arg=headData$NAME, height=headData$`SUM(AMOUNT)`, las=3,
        col="skyblue", main="Les 10 objets les plus fabriqués",
        ylab="Nombre d'unités fabriquées", cex.names=0.8)

# --- Déconnexion de la BDD ---
dbDisconnect(conn)
