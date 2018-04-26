library(RJDBC)

dbPath <-
  "jdbc:h2:C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/database"

print("loading h2")
drv <-
  JDBC(driverClass = "org.h2.Driver", classPath = "C:/Users/utilisateur/Desktop/Cours/Projet Tutoré/h2.jar", identifier.quote="`")

print("connecting to the database")
conn2 <- dbConnect(drv, dbPath, "", "")

print("executing requests")
dbListTables(conn2)

t <- dbReadTable(conn2, "PLAYERMOVES")
class(t)




data<-dbGetQuery(conn2, "SELECT * FROM BrokenBlocks")
print(data)





summary(data$PLAYERPLAYTIME)

data$CLASS_TIME<-cut(x=as.numeric(data$PLAYERPLAYTIME),breaks=c(0,66182,222351,375733,641285,1373254),labels=c("--","-","=","+","++"))
summary(data$CLASS_TIME)




nom_var1 <- "ID" ; var1 <- data[,nom_var1]
nom_var2 <- "CLASS_TIME"; var2 <- data[,nom_var2]

#1.a)création du tableau de contingence
TAB_Nij <- table(var1,var2)

table(var1)

table(var2)


#1.b) Marge du tableau de contingence

TAB_Ni. <- apply(TAB_Nij,1,sum) 
TAB_N.j <- apply(TAB_Nij,2,sum) 

#Distribution conditionnelle en ligne

PCT.LI <- sweep(TAB_Nij,1, TAB_Ni.,"/")*100

#Distribution conditionnelle en colonne

PCT.CO <- sweep(TAB_Nij,2, TAB_N.j,"/")*100

#Les graphiques

#En juxtaposée de service sachant site
barplot(TAB_Nij, beside=TRUE,legend.text=TRUE)


#En empilés 100% de service sachant site
q<-nlevels(var2) ; palette<-heat.colors(q) 
barplot( t(PCT.LI), beside=FALSE ,legend.text=TRUE,
         col=palette, main= paste("Distribution de la variable",nom_var2,"sachant",nom_var1)) 


#empilé 100% de site sachant service
p<-nlevels(var2) ; palette<-heat.colors(p) 
barplot( (PCT.CO), beside=FALSE ,legend.text=TRUE,
         col=palette(gray(seq(0, .9, len=25))), main= paste("Distribution de la variable",nom_var1,"sachant",nom_var2)) 

#en juxtaposés de site sachant service

barplot(t(TAB_Nij), beside=TRUE,legend.text=TRUE)



print("disconnecting")
dbDisconnect(conn2)


