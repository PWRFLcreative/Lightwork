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
  // Subdivide Mesh to Produce more Vertices. We check the proximity of these vertices to the LED coordinates. 
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
  // Initialize Connection to LED driver
  //hardware = new Interface(device.PIXELPUSHER, "192.168.1.137", 1, 100);
  hardware = new Interface(device.FADECANDY, "fade1.local", 6, 40);
  hardware.loadCSV("future_angle_no_zeros.csv"); // Populate the LED array
  hardware.connect(this);

  // Create spheres for each LED
  spheres = new Sphere[hardware.leds.length]; 
  for (int i = 0; i < hardware.leds.length; i++) {
    spheres[i] = new Sphere(sphereRadius); 
    PVector pvec = hardware.leds[i].coord; 
    Vec3D vec = new Vec3D(pvec.x, pvec.y, pvec.z); 
    spheres[i].set(vec);
  }
  
  background(0);
  fill(255);
  noStroke();
}


void draw() {
  background(0); // Clear background

  // Lighting
  lights(); 

  // Draw Mesh
  float mX, mY; // Mesh Center coords
  mX = map(mouseX, 0, width, -width, width+100); 
  mY = map(mouseY, 0, height, -height, height+100); 

  mesh.center(new Vec3D(mX, mY, 0)); 
  mesh.rotateZ(frameRate*0.001); 
  gfx.mesh(mesh); 

  // Perform collision detection between Mesh and Spheres
  for (int i = 0; i < hardware.leds.length; i++) {
    Vec3D vec = new Vec3D(hardware.leds[i].coord.x, hardware.leds[i].coord.y, hardware.leds[i].coord.z); 
    spheres[i].set(vec);
    // Check if the plane is intersecting a sphere
    Vec3D closestPoint = mesh.getClosestVertexToPoint(vec);
    float dist = closestPoint.distanceTo(vec);
    // Color the intersecting spheres and light up the corresponding LEDs
    if (dist < sphereRadius*2) {
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