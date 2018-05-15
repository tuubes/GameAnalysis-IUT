######BDD Bofas
# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database_bofas" # Chemin de la base de données, sans le .mv la fin
dbmsPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2.jar" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
data <- dbGetQuery(conn, "SELECT Size FROM Messages")
View(data)
summary(data)
boxplot(data, main="Distribution de la taille des messages", ylab="Nombre de caractères")



# --- Déconnexion de la BDD ---
dbDisconnect(conn)


######BDD Julien

# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database_julien" # Chemin de la base de données, sans le .mv.db à la fin
dbmsPath <- "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2" # Chemin du SGBD (DBMS en anglais) .jar

# --- Connexion à la BDD ---
drv <- JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Analyses statistiques ---
data <- dbGetQuery(conn, "SELECT Size FROM Messages")
View(data)
summary(data)
boxplot(data, main="Distribution de la taille des messages", ylab="Nombre de caractères")



# --- Déconnexion de la BDD ---
dbDisconnect(conn)