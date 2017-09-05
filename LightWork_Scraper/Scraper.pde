public class Scraper {
  String file;

  PShape s;
  ArrayList<PVector> loc = new ArrayList<PVector>();

  float[] viewBox;

  Scraper ( String in) {  
    file=in;
  }

  void init() {
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

  //normalize point coordinates
  void normCoords()
  {
    float[] norm = new float[4];
    norm = getMinMaxCoords();

    int index=0;

    for (PVector temp : loc) {
      if(temp.x>0 && temp.y>0){
      temp.set (map(temp.x, norm[0], norm[2], 0, 1), map(temp.y, norm[1], norm[3], 0, 1));
      loc.set(index, temp);
      index++;
    }
    }
  }

  //show points in output window
  void display() {

    noFill();
    stroke(255);
    strokeWeight(1); 

    //draw based on coords in arraylist. enhanced arraylist loop
    for (PVector temp : loc) { 
      ellipse(map(temp.x, 0, 1, margin, width-margin), map(temp.y, 0, 1, margin, height-margin), 10, 10);
    }

  }

  //set led coords in opc client
  void update() {
    int index =0;
    for (PVector temp : loc) {
      opc.led(index, (int)map(temp.x, 0, 1, margin, width-margin), (int)map(temp.y, 0, 1, margin, height-margin));
      index++;
    }
  }

  ArrayList getArray() {
    return loc;
  }

  //deterimines bounding box of points in SVG for normalizing
  float[] getMinMaxCoords() {
    float xArr[] = new float[loc.size()];
    float yArr[] = new float[loc.size()];

    int index =0;
    for (PVector temp : loc) { 
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