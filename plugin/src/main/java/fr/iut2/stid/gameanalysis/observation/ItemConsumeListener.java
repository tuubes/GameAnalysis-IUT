package fr.iut2.stid.gameanalysis.observation;

import org.bukkit.Statistic;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerItemConsumeEvent;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Listener pour les items consommés (mangés) par les joueurs.
 */
public class ItemConsumeListener implements Listener {

	private final PreparedStatement insertItemConsume;

	public ItemConsumeListener(Connection conn) throws SQLException {
		this.insertItemConsume = conn.prepareStatement("INSERT INTO ConsumedItems VALUES (?,?)");
	}

	/** Méthode appellée par le serveur lorsqu'un objet est consommé. */
	@EventHandler
	public void onConsume(PlayerItemConsumeEvent evt) {
		int id = evt.getItem().getTypeId();
		Player p = evt.getPlayer();
		long ticks = p.getStatistic(Statistic.PLAY_ONE_TICK);	// récupère le temps de jeu du joueur en "tick" (0,05sec)
		try {
			insertItemConsume.setInt(1, id);
			insertItemConsume.setLong(2, ticks);
			insertItemConsume.executeUpdate();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}
