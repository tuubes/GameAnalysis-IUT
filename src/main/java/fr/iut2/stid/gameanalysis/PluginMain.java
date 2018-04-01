package fr.iut2.stid.gameanalysis;

import org.bukkit.plugin.PluginManager;
import org.bukkit.plugin.java.JavaPlugin;

public class PluginMain extends JavaPlugin {

	@Override
	public void onEnable() {
		PluginManager pm = getServer().getPluginManager();
		// Enregistrer les EventListeners ci-dessous:
		pm.registerEvents(new MoveListener(), this);
		
		getLogger().info("Plugin chargé !");
	}
	
	@Override
	public void onDisable() {
		getLogger().info("Plugin déchargé !");
	}
}