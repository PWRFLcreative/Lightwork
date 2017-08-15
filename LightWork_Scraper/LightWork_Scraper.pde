/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

PShape s;
ArrayList<PVector> loc = new ArrayList<PVector>();

PShape line;
PrintWriter output;

void setup() {
  size(800, 800, P2D);
  background(255);

  //initialize shapes
  s = loadShape("hexes.svg");
  line = createShape();

  output = createWriter("layout.csv"); 

  // Iterate over the children
  int children = s.getChildCount(); //duplicate
  for (int i = 0; i < children; i++) {
    PShape child = s.getChild(i);
    int total = child.getVertexCount();

    // Now we can actually get the vertices from each child
    for (int j = 0; j < total; j++) {
      PVector v = child.getVertex(j);
      loc.add(v);
    }
  }

  //console feedback
  println("svg contains "+loc.size()+" vertecies");
  println(loc);

  //write vals out to file
  int id=0;
  output.println("id"+","+"x"+","+"y");
  for (PVector temp : loc) { 
    output.println(id+","+temp.x+","+temp.y);
    id++;
  }
  output.close(); // Finishes the file
}

void draw() {
  noFill();
  //translate to center
  translate(width/2 - s.width/2, height/2- s.height/2);

  //line style
  line.beginShape();
  line.stroke(100); 
  line.strokeWeight(1); 
  line.noFill();

  //draw based on coords in arraylist. advanced arraylist loop
  for (PVector temp : loc) { 
    ellipse(temp.x, temp.y, 5, 5);
    line.vertex(temp.x, temp.y);
  }
  line.endShape();
  shape(line);
}