library(RJDBC)

dbPath <-
  "jdbc:h2:/home/guillaume/Documents/Minecraft/serv_a/plugins/GameAnalysisIUT2/database"

print("loading h2")
drv <-
  JDBC(driverClass = "org.h2.Driver", classPath = "/home/guillaume/h2.jar", identifier.quote="`")

print("connecting to the database")
conn2 <- dbConnect(drv, dbPath, "", "")

print("executing requests")
dbListTables(conn2)

t <- dbReadTable(conn2, "PLAYERMOVES")
class(t)

dbGetQuery(conn2, "SELECT * FROM MESSAGES")
dbGetQuery(conn2, "SELECT * FROM Messages")
dbGetQuery(conn2, "SELECT * FROM BrokenBlocks")
dbGetQuery(conn2, "SELECT * FROM PlayerMoves")

print("disconnecting")
dbDisconnect(conn2)



