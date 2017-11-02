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

import java.awt.Rectangle;


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

ArrayList<Contour> contours;
// List of detected contours parsed as blobs (every frame)
ArrayList<Contour> newBlobs;
// List of my blob objects (persistent)
ArrayList<Blob> blobList;
// Number of blobs detected over all time. Used to set IDs.
int blobCount = 0; // Use this to assign new (unique) ID's to blobs
int blobSizeThreshold = 3;

void setup()
{
  size(640, 960);
  frameRate(FPS);

  videoMode = VideoMode.FILE; 

  String[] cameras = Capture.list();
  coords = new ArrayList<PVector>();
  leds =new ArrayList<LED>();

  // Blobs list
  blobList = new ArrayList<Blob>();
  
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
  
  // OpenCV Setup
  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.threshold(100);
  // Gray channel
  opencv.gray();
  opencv.contrast(1.35);
  opencv.dilate();
  opencv.erode();
  opencv.startBackgroundSubtraction(0, 5, 0.5); //int history, int nMixtures, double backgroundRatio
  

  network = new Interface();
  network.setNumStrips(1);
  network.setNumLedsPerStrip(8); // TODO: Fix these setters...
  
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(50);
  animator.setFrameSkip(5);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.setMode(animationMode.OFF);
  animator.update();
  

  // Make sure there's always something in videoInput
  videoInput = createImage(camWidth, camHeight, RGB);;
  background(0);
}

void draw()
{
  // Display the camera input and processed binary image

  if (cam.available() && videoMode == VideoMode.CAMERA) {
    cam.read();
    videoInput = cam;
  } else if (videoMode == VideoMode.FILE) {
    videoInput = movie;
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
    
  }
  binaryMapping();
  
  //detectBlobs();
  displayBlobs(); //<>//
  //displayContoursBoundingBoxes();
  
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
    // Commented out because it breaks BinaryMapping
    //if (animator.getMode()!=animationMode.CHASE) {
    //  animator.setMode(animationMode.CHASE);
    //  println("Chase mode");
    //} else {
    //  animator.setMode(animationMode.OFF);
    //  println("Animator off");
    //}
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
  contours = opencv.findContours();
  newBlobs = getBlobsFromContours(contours); // Stores all blobs found in this frame
  
  // Register all the new blobs if the blobList is empty
  if (blobList.isEmpty()) {
    for (int i = 0; i < newBlobs.size(); i++) {
      println("+++ New blob detected with ID: " + blobCount);
      int id = blobCount; 
      blobList.add(new Blob(this, id, newBlobs.get(i)));
      blobCount++;
    }
  }
  
  // Check if newBlobs are actually new...
  else {
      for (Blob blob : blobList) {
        println(blob.id);
      }
      for (Contour c : newBlobs) {
        Rectangle box = c.getBoundingBox();
        box.getLocation();
        
      }
  }
  
  
}

void detectBlobs() {
  
  // Contours detected in this frame
  // Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true, true); //<>//
  
  newBlobs = getBlobsFromContours(contours);
  
  //println(contours.length);
  
  // Check if the detected blobs already exist are new or some has disappeared. 
  
  // SCENARIO 1 
  // blobList is empty
  if (blobList.isEmpty()) {
    // Just make a Blob object for every face Rectangle //<>//
    for (int i = 0; i < newBlobs.size(); i++) {
      println("+++ New blob detected with ID: " + blobCount);
      blobList.add(new Blob(this, blobCount, newBlobs.get(i)));
      blobCount++;
    }
  
  // SCENARIO 2 
  // We have fewer Blob objects than face Rectangles found from OpenCV in this frame
  } else if (blobList.size() <= newBlobs.size()) {
    boolean[] used = new boolean[newBlobs.size()]; //<>//
    // Match existing Blob objects with a Rectangle
    for (Blob b : blobList) {
       // Find the new blob newBlobContours.get(index) that is closest to blob b
       // set used[index] to true so that it can't be used twice
       //float record = 50000;
       float record = 2000;
       int index = -1;
       for (int i = 0; i < newBlobs.size(); i++) {
         float d = dist(newBlobs.get(i).getBoundingBox().x, newBlobs.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
         //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
         println(d);
         if (d < record && !used[i]) {
           record = d;
           index = i;
         } 
       }
       // Update Blob object location
       used[index] = true;
       b.update(newBlobs.get(index));
    }
    // Add any unused blobs
    for (int i = 0; i < newBlobs.size(); i++) {
      if (!used[i]) {
        println("+++ New blob detected with ID: " + blobCount);
        blobList.add(new Blob(this, blobCount, newBlobs.get(i)));
        //blobList.add(new Blob(blobCount, blobs[i].x, blobs[i].y, blobs[i].width, blobs[i].height));
        blobCount++;
      }
    }
  
  // SCENARIO 3 
  // We have more Blob objects than blob Rectangles found from OpenCV in this frame
  } else {
    // All Blob objects start out as available //<>//
    for (Blob b : blobList) {
      b.available = true;
    } 
    // Match Rectangle with a Blob object
    for (int i = 0; i < newBlobs.size(); i++) {
      // Find blob object closest to the newBlobContours.get(i) Contour
      // set available to false
       float record = 50000;
       int index = -1;
       for (int j = 0; j < blobList.size(); j++) {
         Blob b = blobList.get(j);
         float d = dist(newBlobs.get(i).getBoundingBox().x, newBlobs.get(i).getBoundingBox().y, b.getBoundingBox().x, b.getBoundingBox().y);
         //float d = dist(blobs[i].x, blobs[i].y, b.r.x, b.r.y);
         float minimumDistance = 3;
         if (d < record && b.available) {
           record = d;
           index = j;
         } 
       }
       // Update Blob object location
       Blob b = blobList.get(index);
       b.available = false;
       b.update(newBlobs.get(i));
    }
    
    // Start to kill any left over Blob objects
    for (Blob b : blobList) {
      if (b.available) {
        b.countDown();
        if (b.dead()) {
          b.delete = true;
        } 
      }
    } 
  }
  
  // Delete any blob that should be deleted
  for (int i = blobList.size()-1; i >= 0; i--) {
    Blob b = blobList.get(i);
    if (b.delete) {
      blobList.remove(i);
    } 
  }
}

ArrayList<Contour> getBlobsFromContours(ArrayList<Contour> newContours) {
  
  ArrayList<Contour> blobs = new ArrayList<Contour>();
  
  // Which of these contours are blobs?
  for (int i=0; i<newContours.size(); i++) {
    
    Contour contour = newContours.get(i);
    Rectangle r = contour.getBoundingBox();
    
    if (//(contour.area() > 0.9 * src.width * src.height) ||
        (r.width < blobSizeThreshold || r.height < blobSizeThreshold))
      continue;
    
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
        (r.width < blobSizeThreshold || r.height < blobSizeThreshold))
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

//Closes connections
void stop()
{
  super.stop();
}