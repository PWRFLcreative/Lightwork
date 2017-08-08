import processing.video.*;
import gab.opencv.*;

OPC opc;
Capture cam;
OpenCV opencv;

int counter = 0;

void setup()
{
  size(640, 480);
  cam = new Capture(this, 640, 480);
  opencv = new OpenCV(this, 640, 480);
  
  cam.start();
  opencv.startBackgroundSubtraction(5, 3, 0.5);
  //opencv.startBackgroundSubtraction(50, 30, 1.0);
  
  // Connect to the local instance of fcserver
  //opc = new OPC(this, "127.0.0.1", 7890);
  opc = new OPC(this, "fade1.local", 7890);
  
  colorMode(RGB, 100);
  // Map an 5x10 grid of LEDs to the center of the window
  //opc.ledGrid5x10(0, width/2, height/2, height / 12.0, 0, true);
  
  stroke(244, 0, 0);
  strokeWeight(height/12.);
  print(opc.pixelLocations);
  //for (int i = 0; i < opc.pixelLocations.length; i++) {
  //  println(opc.pixelLocations[i]);
  //}
  
}

void draw()
{
  background(0);
  if (cam.available() == true) {
    cam.read();
    opencv.loadImage(cam);
    
    // Background differencing 
    //delay(1000);
    opencv.updateBackground();
   
  }
 
  image(cam, 0, 0, width, height);
  
  // Light up LEDs sequentially 
  color on = color(255, 255, 255);
  color off = color(0,0,0);
  opc.setPixel(counter, on);
  opc.writePixels();
  opc.setPixel(counter, off);
  opc.writePixels();
  
  // Get the brightest point
 // image(opencv.getOutput(), 0, 0); 
  PVector loc = opencv.max();
  
  stroke(255, 0, 0);
  strokeWeight(4);
  noFill();
  ellipse(loc.x, loc.y, 10, 10);
  
  
  delay(30);
  counter++;
  if (counter > 50) {
    counter = 0;
  }
}