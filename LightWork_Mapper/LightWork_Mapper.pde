//   //<>// //<>//
//  LED_Mapper.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls 
//
//  This sketch uses computer vision to automatically generate mapping for LEDs.
//  Currently, Fadecandy and PixelPusher are supported.

import processing.svg.*;
import processing.video.*; 
import gab.opencv.*;
import com.hamoid.*; // Video recording
import java.awt.Rectangle;

Capture cam;
Movie movie;
OpenCV opencv;
ControlP5 cp5;
ControlP5 topPanel;
Animator animator;
Interface network; 

boolean isMapping = false; 
int ledBrightness = 100;


enum  VideoMode {
  CAMERA, FILE, OFF
};

VideoMode videoMode; 
String movieFileName = "singleBinary.mp4";

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth =640;
int camHeight =480;
float camAspect;
PGraphics camFBO;
PGraphics cvFBO;

int cvThreshold = 100;
float cvContrast = 1.35;

ArrayList <PVector>     coords;
String savePath = "layout.svg";

ArrayList <LED>     leds;

int FPS = 30; 
VideoExport videoExport;
boolean isRecording = false;

PImage videoInput; 
PImage cvOutput;

ArrayList<Contour> contours;
// List of detected contours parsed as blobs (every frame)
ArrayList<Contour> newBlobs;
// List of my blob objects (persistent)
ArrayList<Blob> blobList;
// Number of blobs detected over all time. Used to set IDs.
int blobCount = 0; // Use this to assign new (unique) ID's to blobs
int minBlobSize = 5;
int maxBlobSize = 10;

void setup()
{
  println("setting size and FSP");
  size(640, 480, P2D);
  frameRate(FPS);
  camAspect = (float)camWidth / (float)camHeight;
  
  videoMode = VideoMode.FILE; 

  println("creating FBOs");
  camFBO = createGraphics(camWidth, camHeight, P2D);
  cvFBO = createGraphics(camWidth, camHeight, P2D);

  println("iterating cameras");
  //String[] cameras = Capture.list();
  println("making arraylists for coords, leds, and bloblist");
  coords = new ArrayList<PVector>();
  leds =new ArrayList<LED>();

  // Blobs list
  blobList = new ArrayList<Blob>();

  //if (cameras == null) {
  //  println("Failed to retrieve the list of available cameras, will try the default...");
  //  cam = new Capture(this, camWidth, camHeight, FPS);
  //} else if (cameras.length == 0) {
  //  println("There are no cameras available for capture.");
  //  exit();
  //} else {
  //  println("Available cameras:");
  //  printArray(cameras);
  //  //cam = new Capture(this, camWidth, camHeight, 30);
  //  //cam = new Capture(this, cameras[0]);
  //  cam = new Capture(this, camWidth, camHeight, cameras[0], FPS);
  //  cam.start();
  //}
  cam = new Capture(this, camWidth, camHeight, 30);
  
  println("allocating video export");
  videoExport = new VideoExport(this, "data/"+movieFileName, cam);

  if (videoMode == VideoMode.FILE) {
    println("loading video file");
    movie = new Movie(this, movieFileName); // TODO: Make dynamic (use loadMovieFile method)
    //movie.loop();
    movie.play();
  }

  // OpenCV Setup
  println("Setting up openCV");
  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.threshold(cvThreshold);
  opencv.gray();
  opencv.contrast(cvContrast);
  opencv.dilate();
  opencv.erode();
  opencv.startBackgroundSubtraction(0, 5, 0.5); //int history, int nMixtures, double backgroundRatio

  println("setting up network Interface");
  network = new Interface();
  network.setNumStrips(1);
  network.setNumLedsPerStrip(50); // TODO: Fix these setters...

  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(5);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.setMode(animationMode.OFF);
  animator.update();

  //Check for hi resolution display
  println("setup gui multiply");
  int guiMultiply = 1;
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }

  println("Setting window size");
  //Window size based on screen dimensions, centered
  surface.setSize((int)(displayHeight / 2 * camAspect + (200 * guiMultiply)), (int)(displayHeight*0.9));
  surface.setLocation((displayWidth / 2) - width / 2, ((int)displayHeight / 2) - height / 2);

  println("setting up ControlP5");
  cp5 = new ControlP5(this);
  topPanel = new ControlP5(this);
  println("calling buildUI");
  buildUI(guiMultiply);

  // Make sure there's always something in videoInput
  println("allocating videoInput with empty image");
  videoInput = createImage(camWidth, camHeight, RGB);
  background(0);
}

void draw()
{

  if (videoMode == VideoMode.CAMERA) {
    if (cam.available()) {
      cam.read();
      videoInput = cam;
    }
  } else if (videoMode == VideoMode.FILE) {
    videoInput = movie;
  }

  // Display the camera input and processed binary image

  //UI is drawn on canvas background, update to clear last frame's UI changes
  background(#111111);


  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0, camWidth, camHeight);
  camFBO.endDraw();

  image(camFBO, 0, 0, (height / 2)*camAspect, height/2);

  opencv.loadImage(videoInput);
  opencv.updateBackground();

  // Gray channel
  opencv.gray();
  opencv.threshold(cvThreshold);
  opencv.contrast(cvContrast);
  opencv.equalizeHistogram();
  opencv.invert();

  //these help close holes in the binary image
  opencv.dilate();
  opencv.erode();
  opencv.blur(2);

  //cvFBO.beginDraw();
  //cvFBO.image(opencv.getSnapshot(), 0, 0);

  //if (coords.size()>0) {
  //  for (PVector p : coords) {
  //    cvFBO.noFill();
  //    cvFBO.stroke(255, 0, 0);
  //    cvFBO.ellipse(p.x, p.y, 10, 10);
  //  }
  //}
  //cvFBO.endDraw();
  //image(cvFBO, 0, height/2, (height / 2)*camAspect, height/2);

  if (isMapping) {
    //sequentialMapping();
    binaryMapping(); // Find and manage blobs

    // Decode the signal in the blobs

    //print(br);
    //print(", ");
    if (blobList.size() > 0) {
      blobList.get(0).decode(); // Decode the pattern
    }
  }

  camFBO.beginDraw();
  //detectBlobs();
  displayBlobs();
  //displayContoursBoundingBoxes();
  camFBO.endDraw();

  animator.update();

  if (isRecording) {
    videoExport.saveFrame();
  }
}

void keyPressed() {
  if (key == 's') {
    saveSVG(coords);
  }

  if (key == 'm') {

    if (network.isConnected()==false) {
      println("please connect to a device before mapping");
    } else if (animator.getMode()!=animationMode.CHASE) {
      isMapping=!isMapping;
      animator.setMode(animationMode.CHASE);
      println("Chase mode");
    } else {
      isMapping=!isMapping;
      animator.setMode(animationMode.OFF);
      println("Animator off");
    }
  }

  if (key == 't') {
    if (network.isConnected()==false) {
      println("please connect to a device before testing");
    } else if (animator.getMode()!=animationMode.TEST) {
      animator.setMode(animationMode.TEST);
      println("Test mode");
    } else {
      animator.setMode(animationMode.OFF);
      println("Animator off");
    }
  }

  if (key == 'b') {
    if (animator.getMode()!=animationMode.BINARY) {
      //videoExport.startMovie();
      isRecording = true;
      animator.setMode(animationMode.BINARY);
      println("Binary mode (monochrome)");
    } else {
      isRecording = false;
      //videoExport.endMovie();
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
  // Toggle Movie Recording
  if (key == 'r') {
    if (!isRecording) {
      isRecording = true;
      videoExport.startMovie();
    } else {
      isRecording = false;
      videoExport.endMovie();
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
  // Find all contours
  contours = opencv.findContours();

  // Filter contours, remove contours that are too big or too small
  // The filtered results are our 'Blobs' (Should be detected LEDs)
  newBlobs = filterContours(contours); // Stores all blobs found in this frame
  if (newBlobs.size() <= 0) {
    // No new blobs, skip the rest of this method
    return;
  }
  // Note: newBlobs is actually of the Contours datatype
  // Register all the new blobs if the blobList is empty
  if (blobList.isEmpty()) {
    println("Blob List is Empty, adding " + newBlobs.size() + " new blobs.");
    for (int i = 0; i < newBlobs.size(); i++) {
      println("+++ New blob detected with ID: " + blobCount);
      int id = blobCount; 
      blobList.add(new Blob(this, id, newBlobs.get(i)));
      blobCount++;
    }
  }

  // Check if newBlobs are actually new...
  // First, check if the location is unique, so we don't register new blobs with the same (or similar) coordinates
  else {
    // New blobs must be further away to qualify as new blobs
    float distanceThreshold = 5; 
    // Store new, qualified blobs found in this frame

    PVector p = new PVector();
    for (Contour c : newBlobs) {
      // Get the center coordinate for the new blob
      float x = (float)c.getBoundingBox().getCenterX();
      float y = (float)c.getBoundingBox().getCenterY();
      p.set(x, y);

      // Get existing blob coordinates 
      ArrayList<PVector> coords = new ArrayList<PVector>();
      for (Blob blob : blobList) {
        // Get existing blob coord
        PVector p2 = new PVector();
        p2.x = (float)blob.contour.getBoundingBox().getCenterX();
        p2.y = (float)blob.contour.getBoundingBox().getCenterY();
        coords.add(p2);
      }

      // Check coordinate distance
      boolean isTooClose = false; // Turns true if p.dist
      for (PVector coord : coords) {
        float distance = p.dist(coord);
        if (distance <= distanceThreshold) {
          isTooClose = true;
          break;
        }
      }

      // If none of the existing blobs are too close, add this one to the blob list
      if (!isTooClose) {
        Blob b = new Blob(this, blobCount, c);
        blobCount++;
        blobList.add(b);
      }
    }
  }

  // Update the blob age
  for (int i = 0; i < blobList.size(); i++) {
    Blob b = blobList.get(i);
    b.countDown();
    if (b.dead()) {
      blobList.remove(i); // TODO: Is this safe? Removing from array I'm iterating over...
    }
  }

  // Decode blobs (a few at a time for now...) 
  int numToDecode = 1;
  if (blobList.size() >= numToDecode) {
    for (int i = 0; i < numToDecode; i++) {
      // Get the blob brightness to determine it's state (HIGH/LOW)
      //println("decoding this blob: "+blobList.get(i).id);
      Rectangle r = blobList.get(i).contour.getBoundingBox();
      PImage cropped = videoInput.get(r.x, r.y, r.width, r.height);
      int br = 0; 
      for (color c : cropped.pixels) {
        br += brightness(c);
      }
      br = br/ cropped.pixels.length;


      if (i == 0) { // Only look at one blob, for now
        //print(br);
        //print(", ");
        //println(frameCount);
        //print(leds.get(i).binaryPattern.binaryPatternString);
        blobList.get(i).registerBrightness(br); // Set blob brightness
        //blobList.get(i).decode(); // Decode the pattern
        // Check for pattern match
        //if (blobList.get(i).matchFound) {
        //  println("Match found"); 
        //}
      }
    }
  }
}

// Filter out contours that are too small or too big
ArrayList<Contour> filterContours(ArrayList<Contour> newContours) {

  ArrayList<Contour> blobs = new ArrayList<Contour>();

  // Which of these contours are blobs?
  for (int i=0; i<newContours.size(); i++) {

    Contour contour = newContours.get(i);
    Rectangle r = contour.getBoundingBox();

    // If contour is too small, don't add blob
    if (r.width < minBlobSize || r.height < minBlobSize || r.width > maxBlobSize || r.height > maxBlobSize) {
      continue;
    }
    blobs.add(contour);
  }

  return blobs;
}

void displayBlobs() {

  for (Blob b : blobList) {
    strokeWeight(1);
    b.display();
  }
}

void displayContoursBoundingBoxes() {

  for (int i=0; i<contours.size(); i++) {

    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();

    if (//(contour.area() > 0.9 * src.width * src.height) ||
      (r.width < minBlobSize || r.height < minBlobSize))
      continue;

    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
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

//Closes connections (once deployed as applet)
void stop()
{
  cam =null;
  videoExport=null;
  super.stop();
}

//Closes connections
void exit()
{
  cam =null;
  videoExport=null;
  super.exit();
}