import peasy.*;

import toxi.processing.*;
import toxi.geom.*;
import toxi.geom.Vec3D;
import toxi.geom.mesh.*;
import toxi.color.*;

ToxiclibsSupport gfx;
Plane plane; 
Plane refPlane; 
TriangleMesh mesh;
Sphere[] spheres;

PeasyCam cam;
Scraper scraper;
Interface hardware; 
float margin = 50; // Prevents scraper from operating outside the canvas

Table table; 
ArrayList <PVector> coord;
float lfo; 

// Global LED array (shared by interface(reading) and scraper(writing)
void setup() {
  size(1280, 720, P3D); 
  lfo = 0.0; 
  // ToxicLibs stuff
  gfx = new ToxiclibsSupport(this);
  plane = new Plane();
  //plane = new Plane(new Vec3D(100, 200, 100), Vec3D.randomVector());
  //plane.x = width/2; 
  //plane.y = height+100; 
  //plane.z = -10; 
  //plane.normal = new Vec3D(mouseX, mouseY, 0);
  //plane.rotateY(90);
  
  refPlane = new Plane(); 
  //mesh = refPlane.toMesh(300.0);
  
  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(3500);
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

  spheres = new Sphere[scraper.leds.length]; 
  for (int i = 0; i < scraper.leds.length; i++) {
    spheres[i] = new Sphere(scraper.sphereRadius); 
    PVector pvec = scraper.leds[i].coord; 
    Vec3D vec = new Vec3D(pvec.x, pvec.y, pvec.z); 
    spheres[i].set(vec); 
  }
  println("num spheres: "+spheres.length); 
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

  // Draw intersecting plane
  
  // Plane
  //plane.y = sin(frameCount*0.01)*width; 
  //plane.rotateZ(0.1);
  plane.x = map(mouseX, 0, width, -width, width+100); 
  plane.y = map(mouseY, 0, height, -height, height+100); 
  //plane.rotateX(0.1);
  //plane.rotateY(0.05);
  //plane.rotateZ(0.075);
  plane.normal = new Vec3D(0, 0, frameCount);
  
  //gfx.translate(new Vec3D(-width/2, -height/2, 0.));
  
  //gfx.plane(refPlane, 1000); 
  //mesh.rotateX(30.0); 
  //gfx.mesh(mesh, true); 
  
  plane.normal = new Vec3D(mouseX, mouseY, 0);
  
  gfx.fill(TColor.newRGBA(0,255,255,30)); 
  gfx.plane(plane, 800); 
  
  for (int i = 0; i < scraper.leds.length; i++) {
    Vec3D vec = new Vec3D(scraper.leds[i].coord.x, scraper.leds[i].coord.y, scraper.leds[i].coord.z); 
    spheres[i].set(vec);
    float dist = plane.getDistanceToPoint(vec);
    if (dist < scraper.sphereRadius) {
      
      gfx.fill(TColor.newRGBA(255,0,0,255)); 
      scraper.updateColorAtIndex(color(255, 0, 0),i);
    }
    else {
      gfx.fill(TColor.newRGBA(255,255,255,255)); 
      scraper.updateColorAtIndex(color(0, 0, 0), i);  
    }
    
    gfx.sphere(spheres[i], scraper.sphereRadius); 
  }
  
  
  // Display spheres
  //gfx.fill(TColor.newRGBA(0,255,255,100)); 
  //gfx.translate(new Vec3D(-width/2, -height/2, 0.));
  //for (int i = 0; i < spheres.length; i++) {
  //  gfx.sphere(spheres[i], 10);  
  //}
  //scraper.display();
  
  // Draw toxiclib spheres

  //scraper.update();
  //scraper.updateColorAtAddress(color((int)random(255), (int)random(255), (int)random(255)), (int)random(network.numLeds));
  hardware.update(scraper.leds);
  
}