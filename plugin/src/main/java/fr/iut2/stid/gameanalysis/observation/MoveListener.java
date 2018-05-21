package fr.iut2.stid.gameanalysis.observation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import org.bukkit.Location;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.CreatureSpawnEvent;
import org.bukkit.event.player.PlayerMoveEvent;
import org.bukkit.plugin.Plugin;
import org.bukkit.scheduler.BukkitRunnable;

/**
 * Listener pour les déplacements des joueurs et des entités non-joueurs.
 *
 * @author guillaume
 */
public class MoveListener implements Listener {

	private final PreparedStatement insertPlayerMove;
	private final PreparedStatement insertEntitySpawn;
	private final PreparedStatement insertEntityMove;

	/**
	 * Associe chaque entité à un objet EntityChunkInfos qui permet de détecter quand l'entité change de chunk
	 */
	private final Map<Entity, EntityChunkInfos> chunkInfos = new HashMap<>();
	private final Plugin plugin;

	public MoveListener(Connection conn, Plugin plugin) throws SQLException {
		this.plugin = plugin;
		insertPlayerMove = conn.prepareStatement("INSERT INTO PlayerMoves VALUES(?,?,?,?,?,?)");
		insertEntitySpawn = conn.prepareStatement("INSERT INTO EntitySpawns VALUES(?,?,?,?,?,?)");
		insertEntityMove = conn.prepareStatement("INSERT INTO EntityMoves VALUES(?,?,?,?,?)");
	}

	/** Méthode appellée par le serveur lorsqu'un joueur se déplace. */
	@EventHandler
	public void onPlayerMove(PlayerMoveEvent evt) {
		Player player = evt.getPlayer();
		Location newLocation = player.getLocation();
		EntityChunkInfos infos = chunkInfos.computeIfAbsent(player, EntityChunkInfos::new);
		if (infos.update(newLocation)) {
			long time = System.currentTimeMillis();
			try {
				insertPlayerMove.setObject(1, player.getUniqueId());
				insertPlayerMove.setLong(2, time);
				insertPlayerMove.setInt(3, infos.lastChunkX);
				insertPlayerMove.setInt(4, infos.lastChunkY);
				insertPlayerMove.setInt(5, infos.lastChunkZ);
				insertPlayerMove.setBoolean(6, player.isFlying());
				insertPlayerMove.executeUpdate();
			} catch (SQLException ex) {
				ex.printStackTrace();
			}
		}
	}

	/** Méthode appellée par le serveur lorsqu'une entité non-joueur apparaît. */
	@EventHandler
	public void onEntitySpawn(CreatureSpawnEvent evt) {
		// Enregistrement de l'apparition de l'entité, avec son type
		Entity entity = evt.getEntity();
		Location l = entity.getLocation();
		String type = evt.getEntityType().toString();
		try {
			insertEntitySpawn.setObject(1, entity.getUniqueId());
			insertEntitySpawn.setObject(2, System.currentTimeMillis());
			insertEntitySpawn.setString(3, type);
			insertEntitySpawn.setInt(4, l.getBlockX());
			insertEntitySpawn.setInt(5, l.getBlockY());
			insertEntitySpawn.setInt(6, l.getBlockZ());
			insertEntitySpawn.executeUpdate();
		} catch (SQLException ex) {
			ex.printStackTrace();
		}
		// Démarrage d'une tâche qui va enregistrer les changements de tronçon de l'entité à chaque mise à jour
		EntityChunkInfos infos = new EntityChunkInfos(entity);
		infos.update(entity.getLocation());
		BukkitRunnable task = new BukkitRunnable() {
			@Override
			public void run() {
				if (entity.isValid()) {
					if (infos.update(entity.getLocation())) {
						long time = System.currentTimeMillis();
						try {
							insertEntityMove.setObject(1, entity.getUniqueId());
							insertEntityMove.setLong(2, time);
							insertEntityMove.setInt(3, infos.lastChunkX);
							insertEntityMove.setInt(4, infos.lastChunkY);
							insertEntityMove.setInt(5, infos.lastChunkZ);
							insertEntityMove.executeUpdate();
						} catch (SQLException ex) {
							ex.printStackTrace();
						}
					}
				} else {
					// L'entité n'existe plus
					cancel();
				}
			}
		};
		task.runTaskTimer(plugin, 1, 1);
	}

	private class EntityChunkInfos {
		int lastChunkX, lastChunkY, lastChunkZ;

		EntityChunkInfos(Entity e) {
			Location l = e.getLocation();
			lastChunkX = l.getBlockX() / 16;
			lastChunkY = l.getBlockY() / 16;
			lastChunkZ = l.getBlockZ() / 16;
		}

		boolean update(Location newLocation) {
			int newChunkX = newLocation.getBlockX() / 16;
			int newChunkY = newLocation.getBlockY() / 16;
			int newChunkZ = newLocation.getBlockZ() / 16;
			boolean changed = (newChunkX != lastChunkX) || (newChunkY != lastChunkY) || (newChunkZ != lastChunkZ);
			if (changed) {
				lastChunkX = newChunkX;
				lastChunkY = newChunkY;
				lastChunkZ = newChunkZ;
			}
			return changed;
		}
	}
}