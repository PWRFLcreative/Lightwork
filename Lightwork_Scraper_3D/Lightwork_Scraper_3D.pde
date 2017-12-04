import peasy.*;

PeasyCam cam;

Table table; 
ArrayList <PVector> coord;

void setup() {
  size(720, 320, P3D); 

  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(500);

  // Load 3D coordinates from CSV
  // Put our coordinates into the coord ArrayList
  table = new Table(); 
  table = loadTable("stereo_layout.csv", "header");
  printArray(table.getColumnTitles());
  coord = new ArrayList <PVector>(); 
  for (int i = 0; i < table.getRowCount(); i++) {
    TableRow row = table.getRow(i);
    float x = row.getFloat(2);
    float y = row.getFloat(3);
    float z = row.getFloat(4); 
    PVector pvec = new PVector(); 
    pvec.set(x, y, z); 
    coord.add(pvec);
  }
  println(coord);
  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); 
  lights(); 

  // Draw the reference plane

  // Draw the LED coordinates
  fill(100); 
  rect(-width, -height, width*2, height*2); 
  fill(255); 
  for (int i = 0; i < coord.size(); i++) {
    pushMatrix(); 
    translate(coord.get(i).x-width/2, coord.get(i).y-height/2, coord.get(i).z*4); 
    if (coord.get(i).z != 0) {
      sphere(5);  
    }
    popMatrix();
  }
}