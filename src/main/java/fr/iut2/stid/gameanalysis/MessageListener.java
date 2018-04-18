package fr.iut2.stid.gameanalysis;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;
import org.bukkit.event.player.PlayerCommandPreprocessEvent;

public class MessageListener implements Listener {
	private PreparedStatement insertMessageEvent;

	public MessageListener(Connection conn) throws SQLException {
		insertMessageEvent = conn.prepareStatement("INSERT INTO Messages VALUES(?)");
	}

	@EventHandler
	public void onPlayerMessage(AsyncPlayerChatEvent evt) {
		int size = evt.getMessage().length();
		saveMessageSize(size);
	}

	@EventHandler
	public void onPlayerCommand(PlayerCommandPreprocessEvent evt) {
		int size = evt.getMessage().length();
		saveMessageSize(size);
	}

	private void saveMessageSize(int size) {
		try {
			insertMessageEvent.setInt(1, size);
			insertMessageEvent.executeUpdate();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}