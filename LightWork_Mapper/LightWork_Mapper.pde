//   //<>// //<>// //<>// //<>//
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
//ControlP5 topPanel;
Animator animator;
Interface network; 

boolean isMapping = false; 
int ledBrightness = 100;


enum  VideoMode {
  CAMERA, FILE, OFF
};

VideoMode videoMode; 
String movieFileName = "1010101010.mp4";
boolean shouldSyncFrames; // Should we read one movie frame per program frame (slow, but maybe more accurate). 
color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth =640;
int camHeight =480;
float camAspect;
PGraphics camFBO;
PGraphics cvFBO;
PGraphics blobFBO;

int guiMultiply = 1;

int cvThreshold = 230;
float cvContrast = 1.15;

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
float distanceThreshold = 5; 

// Window size
int windowSizeX, windowSizeY;

// Actual display size for camera
int camDisplayWidth, camDisplayHeight; 

void setup()
{
  size(640, 480, P2D);
  frameRate(FPS);
  camAspect = (float)camWidth / (float)camHeight;
  println(camAspect);

  videoMode = VideoMode.FILE; // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

  shouldSyncFrames = false; 
  println("creating FBOs");
  camFBO = createGraphics(camWidth, camHeight, P2D);
  cvFBO = createGraphics(camWidth, camHeight, P2D);
  blobFBO = createGraphics(camWidth, camHeight, P2D); 

  println("iterating cameras");
  println("making arraylists for coords, leds, and bloblist");
  coords = new ArrayList<PVector>();
  leds =new ArrayList<LED>();

  // Blobs list
  blobList = new ArrayList<Blob>();
  cam = new Capture(this, camWidth, camHeight, 30);
  // Initialize Logitech cam by on launch : TODO: remove this
  //cam = new Capture(this, camWidth, camHeight, "HD Pro Webcam C920 #2", 30);
  //cam.start();

  println("allocating video export");
  videoExport = new VideoExport(this, "data/"+movieFileName, cam);

  if (videoMode == VideoMode.FILE) {
    println("loading video file");
    movie = new Movie(this, movieFileName); // TODO: Make dynamic (use loadMovieFile method)
    // Pausing the video at the first frame. 
    //movie.speed(0);
    movie.loop();
    if (shouldSyncFrames) {
      movie.jump(0);
      movie.pause();
    }
  }

  // OpenCV Setup
  println("Setting up openCV");
  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.startBackgroundSubtraction(1, 2, 0.5); //int history, int nMixtures, double backgroundRatio

  println("setting up network Interface");
  network = new Interface();
  network.setNumStrips(1);
  network.setNumLedsPerStrip(1); // TODO: Fix these setters...

  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(10);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.setMode(animationMode.OFF);
  animator.update();

  //Check for hi resolution display
  println("setup gui multiply");
  guiMultiply = 1;
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }

  println("Setting window size");
  //Window size based on screen dimensions, centered
  windowSizeX = (int)(displayHeight / 2 * camAspect + (500 * guiMultiply));
  windowSizeY = (int)(displayHeight*0.9);

  surface.setSize(windowSizeX, windowSizeY);
  surface.setLocation((displayWidth / 2) - width / 2, ((int)displayHeight / 2) - height / 2);

  camDisplayWidth = (int)(height/2*camAspect);
  camDisplayHeight = height/2; 
  println("camDisplayWidth: "+camDisplayWidth);
  println("camDisplayHeight: "+camDisplayHeight);
  println("calling buildUI on a thread");
  thread("buildUI"); // This takes more than 5 seconds and will break OpenGL if it's not on a separate thread

  // Make sure there's always something in videoInput
  println("allocating videoInput with empty image");
  videoInput = createImage(camWidth, camHeight, RGB);
  background(0);
}

void draw()
{
  // Loading screen
  if (!isUIReady) {
    cp5.setVisible(false);
    background(0);
    if (frameCount%1000==0) {
      println("DrawLoop: Building UI....");
    }
    fill(255);
    //textAlign(CENTER);
    pushMatrix(); 
    translate(width/2, height/2);
    rotate(frameCount*0.1);
    text("LOADING...", 0, 0);
    popMatrix();
    return;
  } else if (!cp5.isVisible()) {
    cp5.setVisible(true);
  }

  if (videoMode == VideoMode.CAMERA && cam!=null ) { //&& cam.available()
    cam.read();
    videoInput = cam;
  } else if (videoMode == VideoMode.FILE) {
    movie.read();
    videoInput = movie;
    
    if (shouldSyncFrames) {
      println(frameCount);
      nextMovieFrame();
    }
  } else {
    // println("Oops, no video input!");
  }

  // Display the camera input and processed binary image

  //UI is drawn on canvas background, update to clear last frame's UI changes
  background(#222222);

  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0, camWidth, camHeight);
  camFBO.endDraw();

  image(camFBO, 0, 0, camDisplayWidth, camDisplayHeight);
  opencv.loadImage(camFBO);
  opencv.gray();
  opencv.threshold(cvThreshold);


  //opencv.contrast(cvContrast);
  opencv.dilate();
  opencv.erode();
  //opencv.startBackgroundSubtraction(0, 5, 0.5); //int history, int nMixtures, double backgroundRatio
  //opencv.equalizeHistogram();
  //opencv.blur(2);
  opencv.updateBackground();

  cvFBO.beginDraw();
  cvFBO.image(opencv.getSnapshot(), 0, 0);

  if (coords.size()>0) {
    for (PVector p : coords) {
      cvFBO.noFill();
      cvFBO.stroke(255, 0, 0);
      cvFBO.ellipse(p.x, p.y, 10, 10);
    }
  }
  cvFBO.endDraw();
  image(cvFBO, 0, height/2, camDisplayWidth, camDisplayHeight);

  if (isMapping) {
    //sequentialMapping();
    updateBlobs(); // Find and manage blobs
    decodeBlobs(); 
    // Decode the signal in the blobs

    //print(br);
    //print(", ");
  }


  blobFBO.beginDraw();
  //detectBlobs();
  displayBlobs();
  fill(255, 0, 0);
  text("numBlobs: "+blobList.size(), 0, height-20); 
  text("FPS: "+frameRate, 0, height-40); 
  text("FrameCount: "+frameCount, 0, height-60); 
  //displayContoursBoundingBoxes();
  blobFBO.endDraw();

  animator.update();
  text("FPS: "+frameRate, 0, 0); 
  if (isRecording) {
    videoExport.saveFrame();
  }
}


// Mapping methods
void sequentialMapping() {
  for (Contour contour : opencv.findContours()) {
    noFill();
    stroke(255, 0, 0);
    contour.draw();
    coords.add(new PVector((float)contour.getBoundingBox().getCenterX(), (float)contour.getBoundingBox().getCenterY()));
  }
}



void updateBlobs() {
  // Find all contours
  contours = opencv.findContours();

  // Filter contours, remove contours that are too big or too small
  // The filtered results are our 'Blobs' (Should be detected LEDs)
  newBlobs = filterContours(contours); // Stores all blobs found in this frame

  // Note: newBlobs is actually of the Contours datatype
  // Register all the new blobs if the blobList is empty
  if (blobList.isEmpty()) {
    //println("Blob List is Empty, adding " + newBlobs.size() + " new blobs.");
    for (int i = 0; i < newBlobs.size(); i++) {
      //println("+++ New blob detected with ID: " + blobCount);
      int id = blobCount; 
      blobList.add(new Blob(this, id, newBlobs.get(i)));
      blobCount++;
    }
  }

  // Check if newBlobs are actually new...
  // First, check if the location is unique, so we don't register new blobs with the same (or similar) coordinates
  else {
    // New blobs must be further away to qualify as new blobs
    // Store new, qualified blobs found in this frame

    // Go through all the new blobs and check if they match an existing blob
    for (int i = 0; i < newBlobs.size(); i++) {
      PVector p = new PVector(); // New blob center coord
      Contour c = newBlobs.get(i);
      // Get the center coordinate for the new blob
      float x = (float)c.getBoundingBox().getCenterX();
      float y = (float)c.getBoundingBox().getCenterY();
      p.set(x, y);

      // Check if an existing blob is under the distance threshold
      // If it is under the threshold it is the 'same' blob
      boolean didMatch = false;
      for (int j = 0; j < blobList.size(); j++) {
        Blob blob = blobList.get(j);
        // Get existing blob coord
        PVector p2 = new PVector();
        p2.x = (float)blob.contour.getBoundingBox().getCenterX();
        p2.y = (float)blob.contour.getBoundingBox().getCenterY();

        float distance = p.dist(p2);
        if (distance <= distanceThreshold) {
          didMatch = true;
          // New blob (c) is the same as old blob (blobList.get(j))
          // Update old blob with new contour
          blobList.get(j).update(c);
          break;
        }
      }

      // If none of the existing blobs are too close, add this one to the blob list
      if (!didMatch) {
        Blob b = new Blob(this, blobCount, c);
        blobCount++;
        blobList.add(b);
      }
      // If new blob isTooClose to a a previous blob, reset the age.
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
}

void decodeBlobs() {
  // Decode blobs (a few at a time for now...) +

  // Update brightness levels for all the blobs
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
      //print(br+", ");
      if (i == 0) { // Only look at one blob, for now
        blobList.get(i).registerBrightness(br); // Set blob brightness
      }
    }
  }

  if (blobList.size() > 0) {
    blobList.get(0).decode(); // Decode the pattern
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
//void movieEvent(Movie m) {
//  m.read();
//}

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