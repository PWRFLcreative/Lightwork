import peasy.*;

import toxi.processing.*;
import toxi.geom.*;
import toxi.geom.Vec3D;
import toxi.geom.mesh.*;
import toxi.color.*;

ToxiclibsSupport gfx;
Plane plane; 

PeasyCam cam;
Scraper scraper;
Interface hardware; 
float margin = 50; // Prevents scraper from operating outside the canvas

Table table; 
ArrayList <PVector> coord;

// Global LED array (shared by interface(reading) and scraper(writing)
void setup() {
  size(1280, 720, P3D); 
  
  // ToxicLibs stuff
  gfx = new ToxiclibsSupport(this);
  plane = new Plane();
  plane.x = width/2; 
  plane.y = height/2; 
  plane.z = -10; 
  
  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(2500);
  cam.setDistance(1500);

  // Network Interface
  //initialize connection to LED driver
  //hardware = new Interface(device.PIXELPUSHER, "192.168.1.137", 1,100);
  hardware = new Interface(device.FADECANDY, "fade1.local", 6, 40);
  
  hardware.connect(this);
  hardware.loadCSV("future_stereo_with_zeros.csv");
  //hardware.loadCSV("christmas_layout_filtered.csv");
  // Color Scraper
  scraper = new Scraper(hardware.leds);

  
  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); 

  // Lighting
  //pointLight(255, 255, 255, width, 0, scraper.depth*15); 
  lights(); 
  // Draw reference plane
  fill(255);
  pushMatrix();
  translate(0, 0, -scraper.depth);
  rect(-width, -height, width*2, height*2); 
  popMatrix();

  // Draw intersecting plane
  
  // Plane
  //plane.x = mouseX/2; 
  plane.y = map(mouseY, 0, height, -height, height); 
  println(mouseY);
  //plane.rotateX(0.1);
  //plane.rotateY(0.05);
  //plane.rotateZ(0.075);
  
  
  gfx.fill(TColor.GREEN); 
  gfx.plane(plane, 10000); 
  
  for (int i = 0; i < scraper.leds.length-1; i++) {
    //float dist = abs(scraper.leds[i].coord.z - mouseY);
    Vec3D vec = new Vec3D(scraper.leds[i].coord.x, scraper.leds[i].coord.y, scraper.leds[i].coord.z); 
    //Vec3D vec = new Vec3D(mouseX, mouseY, 0); 
    float dist = plane.getDistanceToPoint(vec);
    //if (plane.containsPoint(vec)) {
    //  scraper.updateColorAtAddress(color(0, 255, 255),i);
    //}
    if (dist < scraper.sphereRadius) {
      scraper.updateColorAtIndex(color(0, 255, 255),i);
    }
    else {
      scraper.updateColorAtIndex(color(0, 0, 0), i);  
    }
  }
  
  scraper.display();
  
  // Draw toxiclib spheres

  //scraper.update();
  //scraper.updateColorAtAddress(color((int)random(255), (int)random(255), (int)random(255)), (int)random(network.numLeds));
  hardware.update(scraper.leds);
  
}