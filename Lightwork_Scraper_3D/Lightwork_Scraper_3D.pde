import peasy.*;

PeasyCam cam;
Scraper scraper;
Interface network; 
float margin = 50; // Prevents scraper from operating outside the canvas

Table table; 
ArrayList <PVector> coord;

void setup() {
  size(1280, 720, P3D); 

  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(2500);
  cam.setDistance(1500);
  
  
  
  // Network Interface
  //initialize connection to LED driver
  //network = new Interface(device.PIXELPUSHER, "192.168.1.137", 1,50);
  network = new Interface(device.FADECANDY, "fade1.local", 6, 40);
  network.connect(this);
  // Color Scraper
  scraper = new Scraper("future_stereo_normalized.csv", network.numLeds);

  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); 

  // Lighting
  pointLight(255, 255, 255, width, 0, scraper.depth*15); 

  // Draw reference plane
  fill(255);
  pushMatrix();
  translate(0, 0, -scraper.depth);
  rect(-width, -height, width*2, height*2); 
  popMatrix();

  scraper.display();
  //scraper.update();
  scraper.updateColorAtAddress(color((int)random(255), (int)random(255), (int)random(255)), (int)random(network.numLeds));
  network.update(scraper.hm);
  
}