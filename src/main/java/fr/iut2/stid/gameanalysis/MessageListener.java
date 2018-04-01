package fr.iut2.stid.gameanalysis; 
 
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.AsyncPlayerChatEvent;
import org.bukkit.plugin.java.JavaPlugin; 
 
public class MessageListener implements Listener { 
 
  @EventHandler
  public void onPlayerMessage(AsyncPlayerChatEvent evt) { 
    int nbmsg = evt.getMessage().length();
    
    
  } 
