# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath1 <- "C:/Users/Alexandre/Desktop/db_data/database_bofas"
dbmsPath1 <- "C:/Users/Alexandre/Desktop/db_data/h2-1.4.197.jar"

dbPath2 <- "C:/Users/Alexandre/Desktop/db_data/database_julien"
dbmsPath2 <- "C:/Users/Alexandre/Desktop/db_data/h2-1.4.197.jar"



# --- Connexion à la BDD ---
drv1 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath1, identifier.quote="`")
conn1 <- dbConnect(drv1, paste("jdbc:h2:", dbPath1, sep=""), "", "")

drv2 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath2, identifier.quote="`")
conn2 <- dbConnect(drv2, paste("jdbc:h2:", dbPath2, sep=""), "", "")




# --- Analyses statistiques ---
#------Analyses dispersion Data1----------
data1<-dbGetQuery(conn1, "SELECT * FROM PlayerMoves")
summary(data1)
boxplot(data1[3:5], main="Distribution des déplacements", ylab="Numéro de tronçons")






#------Analyses dispersion Data2---------
data2<-dbGetQuery(conn2, "SELECT * FROM PlayerMoves")
summary(data2)
boxplot(data2[3:5], main="Distribution des déplacements", ylab="Numéro de tronçons")



# --- Calcul corrélations-----

x1<-data1$CHUNKX
y1<-data1$CHUNKY
z1<-data1$CHUNKZ

x2<-data2$CHUNKX
y2<-data2$CHUNKY
z2<-data2$CHUNKZ

corxy1<-cor(x1, y1 , method = "pearson");corxy1
corxz1<-cor(x1, z1 , method = "pearson");corxz1
corzy1<-cor(z1, y1 , method = "pearson");corzy1

corxy2<-cor(x2, y2 , method = "pearson");corxy2
corxz2<-cor(x2, z2 , method = "pearson");corxz2
corzy2<-cor(z2, y2 , method = "pearson");corzy2



# --- Déconnexion de la BDD ---
print("disconnecting")
dbDisconnect(conn)
