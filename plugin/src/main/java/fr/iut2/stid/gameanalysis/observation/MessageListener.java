package fr.iut2.stid.gameanalysis.observation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;
import org.bukkit.event.player.PlayerCommandPreprocessEvent;

/**
 * Listener pour l'enregistrement de la taille des messages.
 */
public class MessageListener implements Listener {
	private PreparedStatement insertMessageEvent;

	public MessageListener(Connection conn) throws SQLException {
		insertMessageEvent = conn.prepareStatement("INSERT INTO Messages VALUES(?)");
	}

	/** Méthode appellée par le serveur lorsqu'un joueur envoie un message. */
	@EventHandler
	public void onPlayerMessage(AsyncPlayerChatEvent evt) {
		int size = evt.getMessage().length(); //récupère la taille du message dans la variable size avec le nombre de caractères
		saveMessageSize(size);
	}

	/** Méthode appellée par le serveur lorsqu'un joueur utilise une commande. */
	@EventHandler
	public void onPlayerCommand(PlayerCommandPreprocessEvent evt) {
		int size = evt.getMessage().length(); //récupère la taille de la commande depuis le jeu en nombre de caractères
		saveMessageSize(size);
	}

	private void saveMessageSize(int size) {
		try {
			insertMessageEvent.setInt(1, size);
			insertMessageEvent.executeUpdate();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}