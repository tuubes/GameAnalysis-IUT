# Chargement du package RJDBC
library(RJDBC)

# --- ParamÃ¨tres---
dbPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database_bofas" # Chemin de la base de donnÃ©es, sans le .mv.db Ã  la fin
dbmsPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion Ã  la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On rÃ©cupÃ¨re un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
data <- dbGetQuery(conn, "SELECT Size FROM Messages")
View(data)
summary(data)
boxplot(data, main="Distribution de la taille des messages", ylab="Nombre de caractÃ¨res")



# --- DÃ©connexion de la BDD ---
dbDisconnect(conn)