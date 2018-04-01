package fr.iut2.stid.gameanalysis;

import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerMoveEvent;

/**
 * Listener pour les déplacements des joueurs et entités.
 * @author guillaume
 */
public class MoveListener implements Listener {
	
	@EventHandler
	public void onPlayerMove(PlayerMoveEvent evt) {
		Player p = evt.getPlayer();
	}
}