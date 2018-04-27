library(RJDBC)

dbPath <-"jdbc:h2:H:/minecraft/database"

print("loading h2")
drv <-JDBC(driverClass = "org.h2.Driver", classPath = "H:/minecraft/h2-1.4.197.jar", identifier.quote="`")

print("connecting to the database")
conn2 <- dbConnect(drv, dbPath, "", "")

print("executing requests")
dbListTables(conn2)

t <- dbReadTable(conn2, "PLAYERMOVES")
class(t)
View(t)

dbGetQuery(conn2, "SELECT * FROM MESSAGES")
dbGetQuery(conn2, "SELECT * FROM Messages")
dbGetQuery(conn2, "SELECT * FROM BrokenBlocks")
dbGetQuery(conn2, "SELECT * FROM PlayerMoves")




ID<-dbGetQuery(conn2, "SELECT distinct(ID) FROM PlacedBlocks")
NombreBlocPlacés<-dbGetQuery(conn2, "SELECT count(ID) FROM PlacedBlocks")
InfoBlocPlacé<-dbGetQuery(conn2, "SELECT * FROM PlacedBlocks")
idJoueur<-dbGetQuery(conn2, "SELECT distinct(PLAYERID) FROM PLAYERMOVES")
sommeTempJeu<-dbGetQuery(conn2, "SELECT sum(PLAYERPLAYTIME) as n FROM PlacedBlocks")
dbGetQuery(conn2, "SELECT * FROM PlacedBlocks where group by ID ")


TAB1<-table(N$ID);print(TAB1)
class(TAB1)
df<-data.frame(rbind(TAB1))
df_final<-as.data.frame(t(df))
df_final$freq<-df_final$TAB1/10680

barplot( df_final$freq , main=paste("Distribution des types de blocs posés" ),  col="blue", ylab="Fréquences")  
ordre.dfreq<-order(df_final$freq,decreasing=TRUE) 
barplot( df_final$freq[ordre.dfreq] , main=paste0("Distribution des types de blocs posés"),  col= "#3399FF" , ylab= "Fréquences" ) 



print("disconnecting")
dbDisconnect(conn2)