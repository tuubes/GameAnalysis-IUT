package fr.iut2.stid.gameanalysis.observation;

import org.bukkit.Material;
import org.bukkit.Statistic;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.inventory.CraftItemEvent;
import org.bukkit.event.inventory.FurnaceExtractEvent;
import org.bukkit.inventory.ItemStack;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Enregistre les objets ("items") créés par les joueurs.
 *
 * @author guillaume
 */
public class ItemCreationListener implements Listener {
	private final PreparedStatement insertCreatedItem;

	public ItemCreationListener(Connection conn) throws SQLException {
		insertCreatedItem = conn.prepareStatement("INSERT INTO CreatedItems VALUES (?,?,?)");
	}

	@EventHandler
	public void onPlayerCraft(CraftItemEvent evt) {
		ItemStack result = evt.getInventory().getResult();
		Player player = (Player) evt.getWhoClicked();
		saveCreatedItem(player, result.getType(), result.getAmount());
	}

	@EventHandler
	public void onPlayerUseFurnace(FurnaceExtractEvent evt) {
		saveCreatedItem(evt.getPlayer(), evt.getItemType(), evt.getItemAmount());
	}

	private void saveCreatedItem(Player player, Material type, int amount) {
		long ticks = player.getStatistic(Statistic.PLAY_ONE_TICK);
		try {
			insertCreatedItem.setInt(1, type.getId());
			insertCreatedItem.setInt(2, amount);
			insertCreatedItem.setLong(3, ticks);
			insertCreatedItem.executeUpdate();
		} catch (SQLException ex) {
			ex.printStackTrace();
		}
	}
}
