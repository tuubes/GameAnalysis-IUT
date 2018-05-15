import com.electronwill.nightconfig.core.Config;
import com.electronwill.nightconfig.json.JsonParser;

import java.io.File;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class IdConverter {
	public static void main(String[] args) throws Exception {
		Class.forName("org.h2.Driver");
		String jsonPath = new File("/home/guillaume/Documents/items.json").getAbsolutePath();
		String databasePath = new File("/home/guillaume/Documents/database").getAbsolutePath();
		Connection conn = DriverManager.getConnection("jdbc:h2:" + databasePath);
		Statement s = conn.createStatement();
		s.executeUpdate("CREATE TABLE IF NOT EXISTS ItemRegistry (Id INT, Name VARCHAR)");

		PreparedStatement ps = conn.prepareStatement("INSERT INTO ItemRegistry VALUES(?,?)");
		Set<Integer> alreadyRegistered = new HashSet<>();
		try (FileReader reader = new FileReader(jsonPath)) {
			List<Config> jsonData = (List<Config>) new JsonParser().parseDocument(reader);
			for (Config itemData : jsonData) {
				int id = (int) (long) itemData.get("type");
				if (!alreadyRegistered.contains(id)) {
					String name = itemData.get("name");
					ps.setInt(1, id);
					ps.setString(2, name);
					ps.executeUpdate();
					alreadyRegistered.add(id);
				}
			}
		}
		conn.commit();
		conn.close();
	}
}
