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
data <- dbGetQuery(conn,
"SELECT Name, sum(Amount) FROM CreatedItems, ItemRegistry
WHERE CreatedItems.Id = ItemRegistry.Id
GROUP BY CreatedItems.Id
ORDER BY sum(Amount) DESC")

View(data)

barplot(names.arg=data$NAME, height=data$`SUM(AMOUNT)`, las=3)


# --- Déconnexion de la BDD ---
dbDisconnect(conn)