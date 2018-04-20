package fr.iut2.stid.gameanalysis;

import org.bukkit.ChatColor;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;

/**
 * Informe les joueurs que le plugin récolte des données.
 *
 * @author guillaume
 */
public class PrivacyInformer implements Listener {
	@EventHandler
	public void onPlayerJoin(PlayerJoinEvent evt) {
		evt.getPlayer().sendMessage("En jouant sur ce serveur, vous acceptez que des informations concernant vos actions "
				+ "dans le jeu soient enregistrées et analysées pour aider le projet open-source Tuubes "
				+ ChatColor.AQUA + "(http://tuubes.org). " + ChatColor.RESET
				+ "Nous ne collecterons jamais votre adresse IP ni le contenu de vos messages.");
	}
}