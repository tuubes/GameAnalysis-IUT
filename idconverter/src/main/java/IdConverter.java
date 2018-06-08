import com.electronwill.nightconfig.core.Config;
import com.electronwill.nightconfig.json.JsonParser;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.sql.*;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class IdConverter {
	public static void main(String[] args) throws Exception {
		Class.forName("org.h2.Driver");
		String jsonPath = new File("/home/guillaume/Documents/items.json").getAbsolutePath();
		String databasePath = new File("/home/guillaume/Documents/database_julien").getAbsolutePath();
		insertItemsNames(jsonPath, databasePath);
		databasePath = "/home/guillaume/Documents/database_bofas";
		insertItemsNames(jsonPath, databasePath);
	}

	private static void insertItemsNames(String jsonPath, String databasePath) throws SQLException, IOException {
    System.out.println("Connecting to " + databasePath);
    Connection conn = DriverManager.getConnection("jdbc:h2:" + databasePath);
    System.out.println("Connection OK");

    Statement s = conn.createStatement();
    s.executeUpdate("DROP TABLE ItemRegistry");
    s.executeUpdate("CREATE TABLE IF NOT EXISTS ItemRegistry (Id INT, Name VARCHAR)");
    System.out.println("Table (re)created: ItemRegistry");
    System.out.println("Begin data insertion...");

    PreparedStatement ps = conn.prepareStatement("INSERT INTO ItemRegistry VALUES(?,?)");
    Set<Integer> alreadyRegistered = new HashSet<>();
    try (FileReader reader = new FileReader(jsonPath)) {
      List<Config> jsonData = (List<Config>) new JsonParser().parseDocument(reader);
      for (Config itemData : jsonData) {
        int id = (int) (long) itemData.get("type");
        if (!alreadyRegistered.contains(id)) {
          String name = itemData.<String>get("name").replace("Oak ", "");
          ps.setInt(1, id);
          ps.setString(2, name);
          ps.executeUpdate();
          alreadyRegistered.add(id);
        }
      }
    }
    System.out.println("Data inserted. Commiting...");
    conn.commit();
    conn.close();
    System.out.println("Done!");
  }
}
