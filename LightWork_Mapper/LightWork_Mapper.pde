//  //<>// //<>//
//  LED_Mapper.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls 
//
//  This sketch uses computer vision to automatically generate mapping for LEDs.
//  Currently, Fadecandy is supported.

import processing.svg.*;
import processing.video.*; 
import gab.opencv.*;

Capture cam;
OpenCV opencv;
Animator animator;
Interface network; 
BinaryPattern pattern; 

boolean isMapping=false;

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth =640;
int camHeight =480;
float camAspect = (float)camWidth / (float)camHeight;

int ledBrightness = 50;

ArrayList <PVector>     coords;
String savePath = "layout.svg";

ArrayList <LED>     leds;

void setup() {
  size(640, 960);


  String[] cameras = Capture.list();
  coords = new ArrayList<PVector>();
  leds = new ArrayList<LED>();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, camWidth, camHeight, 30);
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    cam = new Capture(this, camWidth, camHeight, 30);
    cam.start();
  }
  
  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.threshold(10);
  // Gray channel
  opencv.gray();
  opencv.contrast(1.35);
  opencv.startBackgroundSubtraction(2, 5, 0.5); //int history, int nMixtures, double backgroundRatio
  //opencv.startBackgroundSubtraction(50, 30, 1.0);

  network = new Interface();

  animator = new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(20);
  animator.setFrameSkip(10);
  animator.setAllLEDColours(off); // Clear the LED strips

  pattern = new BinaryPattern();
  pattern.generatePattern(150);
  
  background(0);
}

void draw() {
  // Display the camera input and processed binary image
  if (cam.available()) {
    cam.read();
    image(cam, 0, 0, camWidth, camHeight);

    opencv.loadImage(cam);
    opencv.updateBackground();

    opencv.equalizeHistogram();

    //these help close holes in the binary image
    opencv.dilate();
    opencv.erode();
    opencv.blur(2);
    image(opencv.getSnapshot(), 0, camHeight);
  }

  if (isMapping) {
    sequentialMapping();
  }
  animator.update();

  if (coords.size()>0) {
    for (PVector p : coords) {
      noFill();
      stroke(255, 0, 0);
      ellipse(p.x, p.y, 10, 10);
    }
  }
}

void keyPressed() {
  if (key == 's') {
    saveSVG(coords);
  }

  if (key == 'm') {
    isMapping=!isMapping;
    if (animator.getMode()!=animationMode.CHASE) {
      animator.setMode(animationMode.CHASE);
      println("Chase mode");
    } else {
      animator.setMode(animationMode.OFF);
      println("Animator off");
    }
  }

  if (key == 't') {
    if (animator.getMode()!=animationMode.TEST) {
      animator.setMode(animationMode.TEST);
      println("Test mode");
    } else {
      animator.setMode(animationMode.OFF);
      println("Animator off");
    }
  }

  // Test connecting to OPC server
  if (key == 'o') {
    network.shutdown();
    network.setMode(device.FADECANDY);
    network.connect(this);
  }

  // Test connecting to PP 
  if (key == 'p') {
    network.shutdown();
    network.setMode(device.PIXELPUSHER);
    network.connect(this);
  }

  // All LEDs Black (clear)
  if (key == 'c') {
    coords.clear();
  }

  // All LEDs White (clear)
  if (key == 'w') {
    if (network.isConnected()) {
      animator.setAllLEDColours(on);
      animator.update();
    }
  }
}

void sequentialMapping() {
  for (Contour contour : opencv.findContours()) {
    noFill();
    stroke(255, 0, 0);
    contour.draw();
    coords.add(new PVector((float)contour.getBoundingBox().getCenterX(), (float)contour.getBoundingBox().getCenterY()));
  }
}

void saveSVG(ArrayList <PVector> points) {
  if (points.size() == 0) {
    //User is trying to save without anything to output - bail
    println("No point data to save, run mapping first");
    return;
  } else {
    beginRecord(SVG, savePath); 
    for (PVector p : points) {
      point(p.x, p.y);
    }
    endRecord();
    println("SVG saved");
  }

  //selectOutput(prompt, callback, file) - try for file dialog
}

//Closes connections
void stop() {
  super.stop();
}