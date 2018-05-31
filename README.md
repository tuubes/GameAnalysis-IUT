# GameAnalysis-IUT
First year student project, Grenoble Institute of Technology.
Projet tutoré de première année, IUT2 STID Grenoble.


## Tables
Les données récoltées sont enregistrées dans une base de données locale gérée par le sgbd Java H2.

### Mouvements

- `PlayerMoves (PlayerId UUID, Time LONG, ChunkX INT, ChunkY INT, ChunkZ INT, IsFlying BOOLEAN)` : déplacements inter-chunks des joueurs
- `EntityMoves (EntityId UUID, Time LONG, ChunkX INT, ChunkY INT, ChunkZ INT)` : déplacements inter-chunks des entités
- `EntitySpawns (EntityId UUID, Time LONG, EntityType VARCHAR, ChunkX INT, ChunkY INT, ChunkZ INT)` : apparitions des entités

Variables :

- `PlayerId/EntityId` : identifiant numérique (128 bits) unique du joueur/de l'entité non-joueur; *qualitative nominale*
- `Time` : nombre de millisecondes depuis le 1er Janvier 1970 jusqu'à l'instant où s'est produit l'évènement; *quantitative continue*.
- `ChunkX, ChunkY, ChunkZ` : coordonnées du chunk du joueur/de l'entité. Un "chunk" est un tronçon cubique de 16x16x16 blocs. Le premier tronçon contient les blocs (0,0,0) jusqu'à (15,15,15) inclus. Ce premier chunk a pour coordonnées (chunkX=0, chunkY=0, chunkZ=0). *Quantitative*
- `IsFlying` : booléan, TRUE si le joueur est en train de voler, FALSE sinon. *Qualitative nominale*
- `EntityType` : type de l'entité, sous forme de chaîne de caractères.



### Utilisation des blocs et objets

- `BrokenBlocks (Id INT, PlayerPlayTime LONG)` : blocs cassés
- `PlacedBlocks (Id INT, PlayerPlayTime LONG)` : blocs placés
- `CreatedItems (Id INT, Amount INT, PlayerPlayTime LONG)` : objets fabriqués
- `ConsumedItems (Id INT, PlayerPlayTime LONG)` : objets consommés (ex nourriture mangées)

Variables :

- `Id` : identifiant numérique du bloc/de l'objet; *qualitative nominale*.
- `PlayerPlayTime` : temps que le joueur a passé à jouer sur le serveur, en "ticks". 1 tick = 50ms, 1 seconde = 20 ticks.
- `Amount` : quantité fabriquée

### Autres

- `Messages (Size INT)` : taille des messages (y compris les commandes) envoyés par le joueur

Variables :

- `Size` : taille du message, en nombres de caractères UTF-16. 1 caractère = 2 octets