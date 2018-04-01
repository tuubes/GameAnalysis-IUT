package fr.iut2.stid.gameanalysis;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;

public class MessageListener implements Listener {
	private PreparedStatement insertMessageEvent;

	public MessageListener(Connection conn) throws SQLException {
		insertMessageEvent = conn.prepareStatement("INSERT INTO Messages VALUES(?)");
	}

	@EventHandler
	public void onPlayerMessage(AsyncPlayerChatEvent evt) {
		int nbmsg = evt.getMessage().length();

		try {
			insertMessageEvent.setInt(1, nbmsg);
			insertMessageEvent.executeUpdate();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}