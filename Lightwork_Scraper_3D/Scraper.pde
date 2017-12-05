// 3D Pixel Scraper

public class Scraper {
  String file;

  ArrayList<PVector> loc;
  color[] colors;
  int depth;
  Table table;
  HashMap<Integer, Integer> hm = new HashMap<Integer, Integer>(); // Key:Value (Int:color (Color is actually Integer))

  Scraper ( String in) {  
    file=in;
    depth = 100;
    loc = new ArrayList<PVector>();
    //thread("loadCSV(file)");
    loadCSV(file);
    //normCoords();
    colors = new color[loc.size()];
  }


  //load position data from csv
  void loadCSV(String file_) {
    // Populate table
    table = loadTable(file_, "header");

    for ( int i = 0; i < table.getRowCount(); i++) {
      TableRow row = table.getRow(i);
      int index = row.getInt("address");
      float x = row.getFloat("x")*width;
      float y = row.getFloat("y")*height;
      float z = row.getFloat("z")*depth;

      PVector v = new PVector();
      v.set (x, y, z );
      loc.add(v);
    }
  }

  

  //show points in output window
  void display() {

    for (int i = 0; i < loc.size(); i++) {
      pushMatrix(); 
      translate(loc.get(i).x-width/2, loc.get(i).y-height/2, loc.get(i).z*4); 
      fill(255); 
      sphere(5);  
      translate(0, 0, 10); 
      //fill(255, 0, 0); 
      //text(i, 0, 0); 

      popMatrix();
    }
  }

  //update colors to be sent for next network packet
  void update() {
    // Populate hashmap with random colors, for now.
    // This should sample colors from the 3D space
    for (int i = 0; i<loc.size(); i++) {
      color c = color((int)random(255), (int)random(255), (int)random(255));
      hm.put(i, c); 
    }
  }
}