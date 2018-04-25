package fr.iut2.stid.gameanalysis.observation;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.Statistic;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockPlaceEvent;
/**
 * Listener pour les placements de blocs. Enregistre tous les blocs placés chaque "tick" (0,05sec)
 * @author Alexandre
 */
public class BlockPlaceListener implements Listener {
	private PreparedStatement insertBlockPlaceEvent;

	public BlockPlaceListener(Connection conn) throws SQLException {
		insertBlockPlaceEvent = conn.prepareStatement("INSERT INTO PlacedBlocks VALUES(?,?)");
	}

	@EventHandler
	public void onPlayerBlockPlaced(BlockPlaceEvent evt) {
		Player p = evt.getPlayer();
		int b = evt.getBlockPlaced().getTypeId(); // récupère l'id du bloc lorsqu'il est placé dans la variable "b"

		long ticks = p.getStatistic(Statistic.PLAY_ONE_TICK);
		try {
			insertBlockPlaceEvent.setInt(1, b);
			insertBlockPlaceEvent.setLong(2, ticks);
			insertBlockPlaceEvent.executeUpdate();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}