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
import org.bukkit.event.player.PlayerMoveEvent;

/**
 * Listener pour les déplacements des joueurs et des entités non-joueurs.
 * 
 * @author guillaume
 */
public class MoveListener implements Listener {

	private final PreparedStatement insertPlayerMove;
	
	/** Associe chaque entité à un objet EntityChunkInfos qui permet de détecter quand l'entité change de chunk */
	private final Map<Entity, EntityChunkInfos> chunkInfos = new HashMap<>();

	public MoveListener(Connection conn) throws SQLException {
		insertPlayerMove = conn.prepareStatement("INSERT INTO PlayerMoves VALUES(?,?,?,?,?,?)");
	}

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