package fr.iut2.stid.gameanalysis;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.bukkit.Statistic;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockPlaceEvent;

public class BlockPlaceListener implements Listener {
	private PreparedStatement insertBlockPlaceEvent;

	public BlockPlaceListener(Connection conn) throws SQLException {
		insertBlockPlaceEvent = conn.prepareStatement("INSERT INTO PlacedBlocks VALUES(?,?)");
	}

	@EventHandler
	public void onPlayerBlockPlaced(BlockPlaceEvent evt) {
		Player p = evt.getPlayer();
		int b = evt.getBlockPlaced().getTypeId();

		long minuts = p.getStatistic(Statistic.PLAY_ONE_TICK)/1200;
		try {
			insertBlockPlaceEvent.setInt(1, b);
			insertBlockPlaceEvent.setLong(1, minuts);
			insertBlockPlaceEvent.executeUpdate();
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}
