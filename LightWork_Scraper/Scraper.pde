public class Scraper { //<>//
  String file;

  //SVG variables
  PShape s;
  float[] viewBox;

  ArrayList<PVector> loc;
  color[] colors;

  Scraper ( String in) {  
    file=in;
    loc = new ArrayList<PVector>();
    //thread("loadCSV(file)");
    loadCSV(file);
    normCoords();
    colors = new color[loc.size()];
  }

  void loadSVG() {
    s = loadShape(file);

    // Iterate over the children
    int children = s.getChildCount(); //duplicate
    for (int i = 0; i < children; i++) {
      PShape child = s.getChild(i);
      int total = child.getVertexCount();

      // Now we can actually get the vertices from each child
      for (int j = 0; j < total; j++) { //using 1 to fix duplicate first point issue temporarily
        PVector v = child.getVertex(j);

        v.set (v.x, v.y);
        loc.add(v);
        //print(v);
      }
    }
  }

  //load position data from csv
  void loadCSV(String file_) {
    Table table = loadTable(file_, "header");

    for (TableRow row : table.rows ()) {
      int index = row.getInt("address");
      float x = row.getFloat("x");
      float y = row.getFloat("y");
      float z = row.getFloat("z");

      PVector v = new PVector();

      v.set (x, y, z );
      loc.add(v);
    }
  }

  //normalize point coordinates to scale with window size
  void normCoords()
  {
    float[] norm = new float[4];
    norm = getMinMaxCoords(loc);

    int index=0;

    //println(loc);

    for (PVector temp : loc) {
      if (temp.x>0 && temp.y>0) {
        temp.set (map(temp.x, norm[0], norm[2], 0.001, 1), map(temp.y, norm[1], norm[3], 0.001, 1));
        loc.set(index, temp);
      }
      index++;
    }
  }

  //show points in output window
  void display() {

    noFill();
    stroke(255);
    strokeWeight(1); 

    //draw based on coords in arraylist. enhanced arraylist loop
    for (PVector temp : loc) { 
      if (!(temp.x == 0.0) && !(temp.y == 0.0)) {
        ellipse(map(temp.x, 0, 1, margin, width-margin), map(temp.y, 0, 1, margin, height-margin), 10, 10);
      }
    }
  }

  //update colors to be sent for next network packet
  void update() {

    for (int i = 0; i<loc.size() ; i++) {
      PVector temp = loc.get(i);
      colors[i] = get((int)map(temp.x, 0, 1, margin, width-margin), (int)map(temp.y, 0, 1, margin, height-margin));
    }
    
    

    //println(loc.size());
  }

  ArrayList getArray() {
    return loc;
  }

  color[] getColors() {
    return colors;
  }

  //deterimines bounding box of points in SVG for normalizing
  float[] getMinMaxCoords(ArrayList<PVector> points) {
    ArrayList<PVector> pointsCopy = new ArrayList<PVector>(points);

    for (int i=pointsCopy.size()-1; i>=0; i--) {
      PVector temp = pointsCopy.get(i);
      if (temp.x==0 && temp.y==0) {
        pointsCopy.remove(i);
      }
    }

    float xArr[] = new float[pointsCopy.size()];
    float yArr[] = new float[pointsCopy.size()];

    int index =0;
    for (PVector temp : pointsCopy) { 

      xArr[index] = temp.x;
      yArr[index] = temp.y;

      index++;
    }

    float minX = min(xArr);
    float minY = min(yArr);
    float maxX = max(xArr);
    float maxY = max(yArr);

    float[] out = {minX, minY, maxX, maxY };
    return out;
  }

  //returns viewBox parameter from SVG for normalizing / drawing points
  float[] getViewBox()
  {
    float[] viewBox = { 0, 0, 0, 0 };

    XML xml = loadXML(file);
    String viewBoxStr = xml.getString("viewBox");
    println("viewBox: "+viewBoxStr);
    if (viewBoxStr != null) 
    {
      viewBox = float(split(viewBoxStr, ' '));
    }
    return viewBox;
  }
}