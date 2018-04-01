package fr.iut2.stid.gameanalysis;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerMoveEvent;

/**
 * Listener pour les déplacements des joueurs et entités.
 * 
 * @author guillaume
 */
public class MoveListener implements Listener {
	
	private PreparedStatement insertMoveEvent;
	
	public MoveListener(Connection conn) throws SQLException {
		insertMoveEvent = conn.prepareStatement("INSERT INTO PlayerMoves VALUES(?,?,?,?)");
	}

	@EventHandler
	public void onPlayerMove(PlayerMoveEvent evt) {
		Player p = evt.getPlayer();
	}
}