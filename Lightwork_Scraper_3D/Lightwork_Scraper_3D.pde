import peasy.*;

import toxi.processing.*;
import toxi.geom.*;
import toxi.geom.Vec3D;
import toxi.geom.mesh.*;
import toxi.geom.mesh.subdiv.*;
import toxi.color.*;

ToxiclibsSupport gfx;
Plane plane; 
Plane refPlane; 
WETriangleMesh mesh;
SubdivisionStrategy subdiv=new MidpointSubdivision();
Sphere[] spheres;
int sphereRadius = 15; 

PeasyCam cam;
Interface hardware; 
float margin = 50; // Prevents scraper from operating outside the canvas

Table table; 
ArrayList <PVector> coord;


// Global LED array (shared by interface(reading) and scraper(writing)
void setup() {
  size(1280, 720, P3D); 

  //noCursor(); 
  // ToxicLibs stuff
  gfx = new ToxiclibsSupport(this);
  plane = new Plane();
  // Convert plane to a mesh of finite size
  mesh = new WETriangleMesh();
  plane.toMesh(mesh, 500.0);
  int numSplits = 4; 
  for (int i = 0; i < numSplits; i++) {
    mesh.subdivide(subdiv);
  }
  
  // Setup PeasyCam
  cam = new PeasyCam(this, 100);
  cam.setMinimumDistance(50);
  cam.setMaximumDistance(3500);
  cam.setDistance(1500);

  // Network Interface
  //initialize connection to LED driver
  //hardware = new Interface(device.PIXELPUSHER, "192.168.1.137", 1, 100);
  hardware = new Interface(device.FADECANDY, "fade1.local", 6, 40);
  //hardware.loadCSV("future_depth_map_no_zeros.csv");
  hardware.connect(this);
  
  hardware.loadCSV("future_stereo_with_zeros.csv");
  //hardware.loadCSV("future_depth_map_no_zeros.csv");
  //hardware.loadCSV("christmas_layout_filtered.csv");
  
  // Color Scraper
  //scraper = new Scraper(hardware.leds); // Initialize the scraper with the hardware LEDs

  spheres = new Sphere[hardware.leds.length]; 
  for (int i = 0; i < hardware.leds.length; i++) {
    spheres[i] = new Sphere(sphereRadius); 
    PVector pvec = hardware.leds[i].coord; 
    Vec3D vec = new Vec3D(pvec.x, pvec.y, pvec.z); 
    spheres[i].set(vec);
  }
  println("num spheres: "+spheres.length); 
  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); // Clear background

  // Lighting
  lights(); 

  // Draw Plane
  /*
  plane.x = map(mouseX, 0, width, -width, width+100); 
   plane.y = map(mouseY, 0, height, -height, height+100); 
   plane.normal = new Vec3D(sin(frameCount*0.01)*plane.x, cos(frameCount*0.01)*plane.y, frameCount);
   plane.z = frameRate; 
   gfx.fill(TColor.newRGBA(0,255,255,30)); 
   gfx.plane(plane, 1800); 
   */

  // Draw Mesh
  float mX, mY; // Mesh Center coords
  mX = map(mouseX, 0, width, -width, width+100); 
  mY = map(mouseY, 0, height, -height, height+100); 

  mesh.center(new Vec3D(mX, mY, 0)); 
  //mesh.rotateAroundAxis(new Vec3D(0, 0, 0), 1);
  mesh.rotateZ(frameRate*0.001); 
  gfx.mesh(mesh); 

  // Draw spheres and light set LED states. 

  for (int i = 0; i < hardware.leds.length; i++) {
    Vec3D vec = new Vec3D(hardware.leds[i].coord.x, hardware.leds[i].coord.y, hardware.leds[i].coord.z); 
    spheres[i].set(vec);
    // Check if the plane is intersecting a sphere
    Vec3D closestPoint = mesh.getClosestVertexToPoint(vec);
    float dist = closestPoint.distanceTo(vec);
    //float dist = bounds.getDistanceToPoint(vec);
    // Color the intersecting spheres and light up the corresponding LEDs
    if (dist < sphereRadius*2) {
      //if (bounds.containsPoint(vec)) {
      gfx.fill(TColor.newRGBA(255, 0, 0, 255)); 
      hardware.updateColorAtIndex(color(255, 0, 0), i);
    }
    // Set neutral color for non-intersecting spheres and turn off LEDs
    else {
      gfx.fill(TColor.newRGBA(255, 255, 255, 255)); 
      hardware.updateColorAtIndex(color(0, 0, 0), i);
    }
    // Draw the spheres
    gfx.sphere(spheres[i], sphereRadius, true);
  }
  // Update the physical LED colours
  hardware.update();
}