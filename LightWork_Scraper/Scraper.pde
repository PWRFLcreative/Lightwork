public class Scraper {
  String file;

  PShape s;
  ArrayList<PVector> loc = new ArrayList<PVector>();

  PShape points;
  
  float[] viewBox;

  Scraper ( String in) {  
    file=in;
  }

  void init() {
    //shapeMode(CENTER);
    viewBox = getViewBox();
    s = loadShape(file);
    points = createShape();
    
    // Iterate over the children
    int children = s.getChildCount(); //duplicate
    for (int i = 0; i < children; i++) {
      PShape child = s.getChild(i);
      int total = child.getVertexCount();

      // Now we can actually get the vertices from each child
      for (int j = 0; j < total; j++) {
        PVector v = child.getVertex(j);
        v.set (map(v.x,0,viewBox[2],0,1), map(v.y,0,viewBox[3],0,1));
        loc.add(v);
        //print(v);
      }
    }
  }

  void display() {
    //translate to center
    //translate(width/2 - s.width/2, height/2- s.height/2);
    //translate(-viewBox[0], -viewBox[1]);
    //translate(width/2,height/2);
    
    //line style
    //line.beginShape();
    //line.stroke(100); 
    //line.strokeWeight(1); 
    //line.noFill();
    
    noFill();
    stroke(255);
    strokeWeight(1); 

    //draw based on coords in arraylist. advanced arraylist loop
    for (PVector temp : loc) { 
      ellipse(temp.x*width, temp.y*height,10,10);
    }
    //line.endShape();
    //shape(points);
  }

  void update() {
    int index =0;
    for (PVector temp : loc) { 
      opc.led(index, (int)(temp.x*width), (int)(temp.y*height));
      index++;
    }
  }

  ArrayList getArray() {
    return loc;
  }

  Float[] getMinMaxCoords() {
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
    
    Float[] out = {minX, minY, maxX, maxY };
    return out;
  }
  
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