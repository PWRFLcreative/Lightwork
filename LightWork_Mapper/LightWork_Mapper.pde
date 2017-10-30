//  //<>// //<>// //<>// //<>//
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
import com.hamoid.*; // Video recording

Capture cam;
Movie movie;
OpenCV opencv;
Animator animator;
Interface network; 

boolean isMapping=false;

enum  VideoMode {
  CAMERA, FILE, OFF
};

VideoMode videoMode; 
String movieFileName = "binaryRecording.mp4";

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth =640;
int camHeight =480;
float camAspect = (float)camWidth / (float)camHeight;

ArrayList <PVector>     coords;
String savePath = "layout.svg";

ArrayList <LED>     leds;

int FPS = 30; 
VideoExport videoExport;
boolean isRecording = false;

PImage videoInput; 
PImage cvOutput;

void setup()
{
  size(640, 960);
  frameRate(FPS);

  videoMode = VideoMode.CAMERA; 

  String[] cameras = Capture.list();
  coords = new ArrayList<PVector>();
  leds =new ArrayList<LED>();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, camWidth, camHeight, FPS);
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    //cam = new Capture(this, camWidth, camHeight, 30);
    //cam = new Capture(this, cameras[0]);
    cam = new Capture(this, camWidth, camHeight, cameras[0], FPS);
    cam.start();
  }
  videoExport = new VideoExport(this, "data/"+movieFileName, cam);

  movie = new Movie(this, "binaryRecording.mp4"); // TODO: Make dynamic (use loadMovieFile method)
  movie.loop();
  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.threshold(30);
  // Gray channel
  opencv.gray();
  opencv.contrast(1.35);
  opencv.startBackgroundSubtraction(2, 5, 0.5); //int history, int nMixtures, double backgroundRatio
  //opencv.startBackgroundSubtraction(50, 30, 1.0);

  network = new Interface();

  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(100);
  animator.setFrameSkip(5);
  animator.setAllLEDColours(off); // Clear the LED strips

  // Make sure there's always something in videoInput
  videoInput = createImage(camWidth, camHeight, RGB);;
  background(0);
}

void draw()
{
  // Display the camera input and processed binary image

  if (cam.available() && videoMode == VideoMode.CAMERA) {
    cam.read();
    //image(cam, 0, 0, camWidth, camHeight);
    videoInput = cam;
  } else if (videoMode == VideoMode.FILE) {
    videoInput = movie;
    //image(videoInput, 0, 0, camWidth, camHeight);
  }

  image(videoInput, 0, 0, camWidth, camHeight);


  opencv.loadImage(videoInput);
  opencv.updateBackground();
  opencv.equalizeHistogram();

  //these help close holes in the binary image
  opencv.dilate();
  opencv.erode();
  opencv.blur(2);
  image(opencv.getSnapshot(), 0, camHeight);

  if (isMapping) {
    //sequentialMapping();
    binaryMapping();
  }
  animator.update();

  if (coords.size()>0) {
    for (PVector p : coords) {
      noFill();
      stroke(255, 0, 0);
      ellipse(p.x, p.y, 10, 10);
    }
  }

  if (isRecording) {
    videoExport.saveFrame();
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

  if (key == 'b') {
    if (animator.getMode()!=animationMode.BINARY) {
      videoExport.startMovie();
      isRecording = true;
      animator.setMode(animationMode.BINARY);
      println("Binary mode (monochrome)");
    } else {
      isRecording = false;
      videoExport.endMovie();
      animator.setMode(animationMode.OFF);
      println("Animator off");
    }
  }

  if (key == 'v') {
    // Toggle Video Input Mode
    if (videoMode == VideoMode.FILE) {
      videoMode = VideoMode.CAMERA;
      println("VideoMode: CAMERA");
    } else if (videoMode == VideoMode.CAMERA) {
      videoMode = VideoMode.FILE;
      boolean success = loadMovieFile(movieFileName);
      println("VideoMode: FILE " + success);
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

void binaryMapping() {
  for (Contour contour : opencv.findContours()) {
    contour.draw();
  }
}

// Load file, return success value
boolean loadMovieFile(String path) {
  File f = new File(path);
  if (f.exists()) {
    movie = new Movie(this, "binaryRecording.mp4");
    movie.loop();
  }
  return f.exists();
}

// Movie reading callback
void movieEvent(Movie m) {
  m.read();
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
void stop()
{
  super.stop();
}