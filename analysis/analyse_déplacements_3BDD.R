# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath1 <- "C:/Users/Alexandre/Desktop/Données BDD/database_bofas"
dbmsPath1 <- "C:/Users/Alexandre/Desktop/h2-1.4.197.jar"

dbPath2 <- "C:/Users/Alexandre/Desktop/Données BDD/database_julien"
dbmsPath2 <- "C:/Users/Alexandre/Desktop/h2-1.4.197.jar"

dbPath3 <- "C:/Users/Alexandre/Desktop/Données BDD/database_perso"
dbmsPath3 <- "C:/Users/Alexandre/Desktop/h2-1.4.197.jar"

# --- Connexion à la BDD ---
drv1 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath1, identifier.quote="`")
conn1 <- dbConnect(drv1, paste("jdbc:h2:", dbPath1, sep=""), "", "")

drv2 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath2, identifier.quote="`")
conn2 <- dbConnect(drv2, paste("jdbc:h2:", dbPath2, sep=""), "", "")

drv3 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath3, identifier.quote="`")
conn3 <- dbConnect(drv3, paste("jdbc:h2:", dbPath3, sep=""), "", "")



# --- Analyses statistiques ---

data1<-dbGetQuery(conn1, "SELECT * FROM PlayerMoves")
View(data1)
summary(data1)
boxplot(data1[3:5], main="Distribution de la taille des messages", ylab="Nombre de caractères")

data2<-dbGetQuery(conn2, "SELECT * FROM PlayerMoves")
View(data2)
summary(data2)
boxplot(data2[3:5], main="Distribution de la taille des messages", ylab="Nombre de caractères")

data3<-dbGetQuery(conn3, "SELECT * FROM PlayerMoves")
View(data3)
summary(data3)
boxplot(data3[3:5], main="Distribution de la taille des messages", ylab="Nombre de caractères")

# --- Déconnexion de la BDD ---
print("disconnecting")
dbDisconnect(conn)
