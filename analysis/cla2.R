# Chargement du package RJDBC
library(RJDBC)

# --- Paramètres---
dbPath1 <- "C:/Users/clari/Documents/IUT/Projet tutoré/database_bofas"
dbmsPath1 <- "C:/Users/clari/Documents/IUT/Projet tutoré/h2-1.4.197.jar"
dbPath2 <- "C:/Users/clari/Documents/IUT/Projet tutoré/database_julien"
dbmsPath2 <- "C:/Users/clari/Documents/IUT/Projet tutoré/h2-1.4.197.jar"



# --- Connexion à la BDD ---
drv1 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath1, identifier.quote="`")
conn1 <- dbConnect(drv1, paste("jdbc:h2:", dbPath1, sep=""), "", "")

drv2 <-JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath2, identifier.quote="`")
conn2 <- dbConnect(drv2, paste("jdbc:h2:", dbPath2, sep=""), "", "")




# --- Analyses statistiques ---
#------Analyses Data1----------
data1<-dbGetQuery(conn1, "SELECT * FROM PlayerMoves")
View(data1)
summary(data1)
boxplot(data1[3:5], main="Distribution desdéplacements", ylab="Nombre de caractères")
##(1/n)Somme de (x-xbar)^2+(y-ybar)^2+(z-zbar)^2
##1/n*sum((x-mean(PLAYERID$CHUNKX))^2+(x-mean(PLAYERID$CHUNKY))^2+(x-mean(PLAYERID$CHUNKZ))^2)



moyx<-mean(data1$CHUNKX)
moyy<-mean(data1$CHUNKY)
moyz<-mean(data1$CHUNKZ)
somme<-0
for (i in seq(1,length(data1$CHUNKX),by=1)){
  somme<-somme+(data1[i,3]-moyx)^2+(data1[i,4]-moyy)^2+(data1[i,5]-moyz)^2
}
res<-1/length(data1$CHUNKX)*somme



#------Analyses Data2---------
dbGetQuery(conn2, "SHOW TABLES")
v<-dbGetQuery(conn2, "SELECT distinct(PlayerId) FROM PlayerMoves")
v
data2<-dbGetQuery(conn2, "SELECT * FROM PlayerMoves")
View(data2)
summary(data2)
boxplot(data2[3:5], main="Distribution des déplacements", ylab="Nombre de caractères")

moyx2<-mean(data2$CHUNKX)
moyy2<-mean(data2$CHUNKY)
moyz2<-mean(data2$CHUNKZ)
somme2<-0
for(id in v$PLAYERID) {
  data2
}
for (i in seq(1,length(data1$CHUNKX),by=1)){
  somme2<-somme2+(data2[i,3]-moyx)^2+(data2[i,4]-moyy)^2+(data2[i,5]-moyz)^2
}
res2<-1/length(data2$CHUNKX)*somme2

# --- Déconnexion de la BDD ---
print("disconnecting")
dbDisconnect(conn)