import peasy.*;

PeasyCam cam;
Scraper scraper;
Interface network; 
float margin = 50; // Prevents scraper from operating outside the canvas

Table table; 
ArrayList <PVector> coord;
int depth = 150; 

void setup() {
  size(1280, 720, P3D); 

  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(2500);
  
  // Color Scraper
  scraper = new Scraper("future_stereo_normalized.csv");
  
  // Network Interface
  //initialize connection to LED driver
  //network = new Interface(device.PIXELPUSHER, "192.168.1.137", 1,50);
  network = new Interface(device.FADECANDY, "fade1.local", 1, 50);
  network.connect(this);
  

  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); 

  // Lighting
  pointLight(255, 255, 255, width*2, 0, depth*15); 

  // Draw the reference plane

  // Draw reference plane
  fill(255); 
  pushMatrix();
  translate(0, 0, -depth);
  rect(-width, -height, width*2, height*2); 
  popMatrix();

  // Draw the LED coordinates
  /*
  for (int i = 0; i < coord.size(); i++) {
    pushMatrix(); 
    translate(coord.get(i).x-width/2, coord.get(i).y-height/2, coord.get(i).z*4); 

    fill(255); 
    sphere(5);  
    translate(0, 0, 10); 
    fill(255, 0, 0); 
    text(i, 0, 0); 

    popMatrix();
  }
  */ 
  
  scraper.display();
  //scraper.update();
  //network.update(scraper.getColors());
}