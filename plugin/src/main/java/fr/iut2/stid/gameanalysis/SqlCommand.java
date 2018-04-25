package fr.iut2.stid.gameanalysis;

import org.bukkit.ChatColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;

import java.sql.*;
/**
 * Permet de faire des requêtes SQL directement depuis le jeu.
 * @author Alexandre
 *
 */
public class SqlCommand implements CommandExecutor {
	private static final int RESULT_LIMIT = 15;
	private Connection conn;

	public SqlCommand(Connection conn) {
		this.conn = conn;
	}

	@Override
	public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
		if (sender.hasPermission("iut.sql")) {
			String sql = String.join(" ", args);
			if (mightModify(sql) && !sender.hasPermission("iut.sql.modify")) {
				sender.sendMessage(ChatColor.RED + "Cette requête vous est interdite.");
			} else {
				executeSql(sender, sql);
			}
		} else {
			sender.sendMessage(ChatColor.RED + "Vous n'avez pas la permission d'utiliser cette commande.");
		}
		return true;
	}

	private boolean mightModify(String sql) {
		String l = sql.toLowerCase();
		return !(l.startsWith("select") || l.equals("show tables"));
	}

	private void executeSql(CommandSender s, String sql) {
		try (Statement statement = conn.createStatement()) {
			boolean hasResultSet = statement.execute(sql);
			if (hasResultSet) {
				ResultSet result = statement.getResultSet();
				// Affiche le nom des colonnes:
				ResultSetMetaData meta = result.getMetaData();
				int nColumns = meta.getColumnCount();
				String[] colNames = new String[nColumns];
				for (int i = 1; i <= nColumns; i++) {
					colNames[i - 1] = meta.getColumnLabel(i);
				}
				String header = String.join(", ", colNames);
				s.sendMessage(ChatColor.BLUE + header + ChatColor.RESET);

				// Affiche le résultat:
				int nlines = 0;
				while (nlines < RESULT_LIMIT && result.next()) {
					String[] colValues = new String[nColumns];
					for (int i = 1; i <= nColumns; i++) {
						colValues[i - 1] = result.getString(i);
					}
					String line = String.join(", ", colValues);
					s.sendMessage(line);
					nlines++;
				}
				if (nlines == RESULT_LIMIT && result.next()) {
					s.sendMessage(ChatColor.GOLD + "Résultat tronqué à " + RESULT_LIMIT + " lignes");
				} else {
					s.sendMessage(ChatColor.DARK_GREEN + "Résultat complet");
				}
			} else {
				int affectedCount = statement.getUpdateCount();
				if (affectedCount >= 0) {
					s.sendMessage(ChatColor.DARK_GREEN + "" + affectedCount + " lignes affectées");
				} else {
					s.sendMessage(ChatColor.DARK_GREEN + "Aucun résultat");
				}
			}
		} catch (SQLException ex) {
			s.sendMessage(ChatColor.RED + "Erreur : " + ex.getLocalizedMessage());
			ex.printStackTrace();
		}
	}
}
