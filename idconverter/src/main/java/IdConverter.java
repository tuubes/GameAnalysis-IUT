import com.electronwill.nightconfig.core.Config;
import com.electronwill.nightconfig.json.JsonParser;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.sql.*;
import java.util.*;

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
    s.executeUpdate("CREATE TABLE ItemRegistry (Id INT, Name VARCHAR, Color VARCHAR)");
    System.out.println("Table (re)created: ItemRegistry");
    System.out.println("Begin data insertion...");

    PreparedStatement ps = conn.prepareStatement("INSERT INTO ItemRegistry VALUES(?,?,?)");
    Set<Integer> alreadyRegistered = new HashSet<>();
    try (FileReader reader = new FileReader(jsonPath)) {
      List<Config> jsonData = (List<Config>) new JsonParser().parseDocument(reader);
      for (Config itemData : jsonData) {
        int id = (int) (long) itemData.get("type");
        if (!alreadyRegistered.contains(id)) {
          String name = itemData.<String>get("name").replace("Oak ", "");
          ps.setInt(1, id);
          ps.setString(2, name);
          ps.setString(3, getColor(name));
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

  private static String getColor(String type) {
	  String lower = type.toLowerCase();
	  if (lower.contains("wood")) {
	    return "#bd9a64";
    } else if(lower.contains("coal") || lower.contains("ink")) {
	    return "#333333";
    } else if(lower.contains("nether")) {
	    return "#800E0E";
    } else if(lower.contains("stone")) {
	    return "#757575";
    } else if(lower.contains("iron")) {
	    return "#A8A8A8";
    } else if(lower.contains("cooked")) {
	    return "#B21818";
    } else if(lower.contains("seed")) {
	    return "#3E9C15";
    } else if(lower.contains("gold")) {
	    return "#FFFF0B";
    } else if(lower.contains("glass")) {
	    return "#A8C9CE";
    }
	  return colorsMap.getOrDefault(type, "#009FF0"); // #595959 = gris, #009FF0 = bleu ciel
  }

  private static final Map<String, String> colorsMap = new HashMap<>();
  static {
    colorsMap.put("Grass", "#36B030");
    colorsMap.put("Dirt", "#996A41");
    colorsMap.put("Dead Shrub", "#946428");
    colorsMap.put("Wheat Crops", "#D5DA45");
    colorsMap.put("Bread", "#D5DA45");
    colorsMap.put("Leaves", "#3E9C15");
    colorsMap.put("Gravel", "#8D8D8D");
    colorsMap.put("Redstone", "#FD0000");
    colorsMap.put("Bricks", "#ed2f00");
    colorsMap.put("Torch", "#FF8F00");
    colorsMap.put("Stick", "#473821");
    colorsMap.put("Steak", "#D42A2A");
    colorsMap.put("Fence", "#bd9a64");
    colorsMap.put("Sign", "#bd9a64");
  }
}
