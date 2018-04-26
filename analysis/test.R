# Chargement du package RJDBC
library(RJDBC)

# Chemin de la base de données, sans le .mv.db à la fin
dbPath <- "/home/guillaume/Documents/Minecraft/serv_a/plugins/GameAnalysisIUT2/database"
# Chemin du SGBD (DBMS en anglais) .jar
dbmsPath <- "/home/guillaume/h2.jar"

# Chargement du pilote de la base de données
print("loading h2")
drv <-
  JDBC(driverClass = "org.h2.Driver", classPath = dbmsPath, identifier.quote="`")

# Connexion à la base de données. Attention ! Si elle n'existe pas, une BDD vide sera crée.
print("connecting to the database")
conn <- dbConnect(drv, paste("jdbc:h2:", dbPath, sep=""), "", "") # On récupère un objet conn qui nous servira par la suite

# --- Utilisation de la BDD ---
print("executing requests")
dbListTables(conn) # Liste les tables de la BDD (y compris les tables crées par le SGBD et qui ne contiennent pas nos données)
dbGetQuery(conn, "SHOW TABLES") # Liste les tables de la BDD (uniquement celles que nous avons créées)

# Lecture d'une table entière de la BDD
data <- dbReadTable(conn, "PLAYERMOVES")
class(data) # On obtient un data frame avec le nom des colonnes
View(data)

# On peut aussi exécuter des requêtes SQL avec la fonction dbGetQuery
dbGetQuery(conn, "SELECT * FROM MESSAGES")
dbGetQuery(conn, "SELECT * FROM Messages")
dbGetQuery(conn, "SELECT * FROM BrokenBlocks")
dbGetQuery(conn, "SELECT * FROM PlayerMoves")

# Une fois toutes les requêtes effectuées, il faut se déconnecter de la base de données avec dbDisconnect
print("disconnecting")
dbDisconnect(conn)



