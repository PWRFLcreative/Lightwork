/* //<>//
 *  Lightwork-Mapper
 *  
 *  This sketch uses computer vision to automatically generate mapping for LEDs.
 *  Currently, Fadecandy and PixelPusher are supported.
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @authors Leó Stefánsson and Tim Rolls
 *  
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *  
 */

import processing.svg.*;
import processing.video.*; 
import gab.opencv.*;
import java.awt.Rectangle;

Capture cam;
Capture cam2;
OpenCV opencv;

ControlP5 cp5;
Animator animator;
Interface network; 
BlobManager blobManager; 

int captureIndex; // For capturing each binary state (decoding later). 
boolean isMapping = false; 

enum  VideoMode {
  CAMERA, FILE, IMAGE_SEQUENCE, CALIBRATION, OFF
};

VideoMode videoMode; 

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth = 640;
int camHeight = 480;
float camAspect;

PGraphics camFBO;
PGraphics cvFBO;
PGraphics blobFBO;

int cvThreshold = 25;
float cvContrast = 1.15;
int ledBrightness = 45;

ArrayList <LED>     leds; // Global, used by Animator and Interface classes

int FPS = 30; 
String savePath = "../LightWork_Scraper/data/layout.csv";

PImage videoInput; 
PImage cvOutput;

// Image sequence stuff
int numFrames = 10;  // The number of frames in the animation
int currentFrame = 0;
ArrayList <PGraphics> images;
PImage backgroundImage = new PImage();
PGraphics diff; // Background subtracted from Binary Pattern Image
int imageIndex = 0;
int captureTimer = 0; 
boolean shouldStartDecoding; // Only start decoding once we've decoded a full sequence

void setup()
{
  size(960, 700, P3D);
  frameRate(FPS);
  warranty();

  camAspect = (float)camWidth / (float)camHeight;
  println("Cam Aspect: "+camAspect);

  videoMode = VideoMode.CAMERA; 

  println("creating FBOs");
  camFBO = createGraphics(camWidth, camHeight, P3D);
  cvFBO = createGraphics(camWidth, camHeight, P3D);
  blobFBO = createGraphics(camWidth, camHeight, P3D); 

  println("making arraylists for LEDs and bloblist");
  leds = new ArrayList<LED>();

  cam = new Capture(this, camWidth, camHeight, 30);

  // Network
  println("setting up network Interface");
  network = new Interface();
  network.setNumStrips(3);
  network.setNumLedsPerStrip(50); // TODO: Fix these setters...
  //network.populateLeds();

  // Animator
  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(frameSkip);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.update();

  //Check for high resolution display
  println("setup gui multiply");
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }
  //set up window for 2d mapping
  window2d();

  println("calling buildUI on a separate thread");
  thread("buildUI"); // This takes more than 5 seconds and will break OpenGL if it's not on a separate thread

  // Make sure there's always something in videoInput
  println("allocating videoInput with empty image");
  videoInput = createImage(camWidth, camHeight, RGB);

  // OpenCV Setup
  println("Setting up openCV");
  opencv = new OpenCV(this, videoInput);

  // Blob Manager
  blobManager = new BlobManager(this, opencv); 

  // Image sequence
  captureIndex = 0; 
  images = new ArrayList<PGraphics>();
  diff = createGraphics(camWidth, camHeight, P2D); 
  background(0);
}

// -----------------------------------------------------------
// -----------------------------------------------------------
void draw() {
  // LOADING SCREEN
  if (!isUIReady) {
    loading();
    return;
  } else if (!cp5.isVisible()) {
    cp5.setVisible(true);
  }
  // END LOADING SCREEN

  //UI is drawn on canvas background, update to clear last frame's UI changes
  background(#222222);

  // Update the LEDs (before we do anything else). 
  animator.update();

  // Video Input Assignment (Camera or Image Sequence)
  // Read the video input (webcam or videofile)
  if (cam.available() ) { 
    cam.read();
    videoInput = cam;
  } 
  // Binary Image Sequence Capture and Decoding
  if (videoMode == VideoMode.IMAGE_SEQUENCE && isMapping) {

    // Capture sequence if it doesn't exist
    if (images.size() < numFrames) {
      PGraphics pg = createGraphics(camWidth, camHeight, P2D);
      pg.beginDraw();
      pg.image(videoInput, 0, 0);
      pg.endDraw();
      captureTimer++;
      if (captureTimer == animator.frameSkip/2) { // Capture halfway through animation frame
        println("adding image frame to sequence");
        images.add(pg);
      } else if (captureTimer >= animator.frameSkip) { // Reset counter when frame is done
        captureTimer = 0;
      }
      //processCV();
    }

    // If sequence exists, playback and decode
    else {
      videoInput = images.get(currentFrame);
      currentFrame++; 
      if (currentFrame >= numFrames) {
        shouldStartDecoding = true; // We've decoded a full sequence, start pattern matchin
        currentFrame = 0;
      }
      // Background diff
      processCV();
    }
    // Assign diff to videoInput
  }

  // Calibration mode, use this to tweak your parameters before mapping
  else if (videoMode == VideoMode.CALIBRATION && cam.available()) {
    blobManager.update(opencv.findContours()); 
    blobManager.display(); 
    processCV();
  }

  // Display the camera input
  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0);
  camFBO.endDraw();
  image(camFBO, 0, (70*guiMultiply), camDisplayWidth, camDisplayHeight);

  // Decode image sequence
  if (videoMode == VideoMode.IMAGE_SEQUENCE && images.size() >= numFrames) {
    blobManager.update(opencv.findContours()); 
    blobManager.display();
    processCV();
    decode();

    if (shouldStartDecoding) {
      matchBinaryPatterns();
    }
  } else {
    processCV();
  }

  if (isMapping && !patternMapping) {
    blobManager.update(opencv.findContours()); // Find and manage blobs
    blobManager.display(); 
    processCV();

    sequentialMapping();
  }

  // Display OpenCV output and dots for detected LEDs (dots for sequential mapping only). 
  cvFBO.beginDraw();
  PImage snap = opencv.getOutput(); 
  cvFBO.image(snap, 0, 0);

  if (leds.size()>0) {
    for (LED led : leds) {
      if (led.coord.x!=0 && led.coord.y!=0) {
        cvFBO.noFill();
        cvFBO.stroke(255, 0, 0);
        cvFBO.ellipse(led.coord.x, led.coord.y, 10, 10);
      }
    }
  }
  cvFBO.endDraw();
  image(cvFBO, camDisplayWidth, 70*guiMultiply, camDisplayWidth, camDisplayHeight);

  // Display blobs
  blobFBO.beginDraw();
  blobManager.display();
  blobFBO.endDraw();

  // Draw the background image (dor debugging) 

  // Draw a sequence of the sequential captured frames
  if (images.size() > 0) {
    for (int i = 0; i < images.size(); i++) {
      image(images.get(i), i*width/10, /*70+*/camDisplayHeight, width/10, height/10);
    }
    stroke(255, 0, 0); 
    strokeWeight(3);
    noFill(); 
    rect(currentFrame*width/10, camDisplayHeight, width/10, height/10);
  }

  showLEDOutput(); 
  showBlobCount(); //TODO: display during calibration/ after mapping
}

// -----------------------------------------------------------
// -----------------------------------------------------------
// Mapping methods

void sequentialMapping() {
  //println("sequentialMapping() -> blobList size() = "+blobList.size()); 
  if (blobManager.blobList.size()!=0) {
    Rectangle rect = blobManager.blobList.get(blobManager.blobList.size()-1).contour.getBoundingBox(); 
    PVector loc = new PVector(); 
    loc.set((float)rect.getCenterX(), (float)rect.getCenterY()); 

    int index = animator.getLedIndex(); 
    leds.get(index).setCoord(loc); 
    println(loc);
  }
}

// TODO: implement this method in main pde properly
//public void binaryMapping() {
//  if (videoMode != VideoMode.IMAGE_SEQUENCE) {
//    // Set frameskip so we have enough time to capture an image of each animation frame. 
//    videoMode = VideoMode.IMAGE_SEQUENCE;
//    animator.frameSkip = 18;
//    animator.setMode(AnimationMode.BINARY);
//    //animator.resetPixels();
//    backgroundImage = videoInput.copy();
//    backgroundImage.save("backgroundImage.png");
//    blobLifetime = 200;
//  } else {
//    videoMode = VideoMode.CAMERA;
//    animator.setMode(AnimationMode.OFF);
//    animator.resetPixels();
//    blobList.clear();
//    shouldStartDecoding = false; 
//    images.clear();
//    currentFrame = 0;
//  }
//}

void matchBinaryPatterns() {
  for (int i = 0; i < leds.size(); i++) {
    if (leds.get(i).foundMatch) {
      return;
    }
    String targetPattern = leds.get(i).binaryPattern.binaryPatternString.toString(); 
    //println("finding target pattern: "+targetPattern);
    for (int j = 0; j < blobManager.blobList.size(); j++) {
      String decodedPattern = blobManager.blobList.get(j).detectedPattern.decodedString.toString(); 
      //println("checking match with decodedPattern: "+decodedPattern);
      if (targetPattern.equals(decodedPattern)) {
        leds.get(i).foundMatch = true; 
        Rectangle rect = blobManager.blobList.get(j).contour.getBoundingBox(); 
        PVector pvec = new PVector(); 
        pvec.set((float)rect.getCenterX(), (float)rect.getCenterY()); 
        leds.get(i).setCoord(pvec); 
        println("LED: "+i+" Blob: "+j+" --- "+targetPattern + " --- " + decodedPattern);
      }
    }
  }
}

void decode() {
  // Update brightness levels for all the blobs
  if (blobManager.blobList.size() > 0) {
    for (int i = 0; i < blobManager.blobList.size(); i++) {
      // Get the blob brightness to determine it's state (HIGH/LOW)
      //println("decoding this blob: "+blobList.get(i).id);
      Rectangle r = blobManager.blobList.get(i).contour.getBoundingBox(); 
      // TODO: Which texture do we decode?
      PImage snap = opencv.getSnapshot(); 
      PImage cropped = snap.get(r.x, r.y, r.width, r.height); // TODO: replace with videoInput
      int br = 0; 
      for (color c : cropped.pixels) {
        br += brightness(c);
      }

      br = br/ cropped.pixels.length; 

      blobManager.blobList.get(i).registerBrightness(br); // Set blob brightness
      blobManager.blobList.get(i).decode(); // Decode the pattern
    }
  }
}

//Open CV processing functions
void processCV() {
  diff.beginDraw(); 
  diff.background(0); 
  diff.blendMode(NORMAL); 
  diff.image(videoInput, 0, 0); 
  diff.blendMode(SUBTRACT); 
  diff.image(backgroundImage, 0, 0); 
  diff.endDraw(); 
  opencv.loadImage(diff); 
  opencv.contrast(cvContrast); 
  opencv.threshold(cvThreshold);
}

//Count LEDs that have been matched
int listMatchedLEDs() {
  int count=0; 
  for (LED led : leds) {
    if (led.foundMatch==true) count++;
  }
  return count;
}

// -----------------------------------------------------------
// -----------------------------------------------------------
// Utility methods

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
}

void saveCSV(ArrayList <LED> ledArray, String path) {
  PrintWriter output; 
  output = createWriter(path); 

  //write vals out to file, start with csv header
  output.println("address"+","+"x"+","+"y"+","+"z"); 

  for (int i = 0; i < ledArray.size(); i++) {
    output.println(ledArray.get(i).address+","+ledArray.get(i).coord.x+","+ledArray.get(i).coord.y+","+ledArray.get(i).coord.z); 
    println(ledArray.get(i).address+" "+ledArray.get(i).coord.x+" "+ledArray.get(i).coord.y);
  }
  output.close(); // Finishes the file

  //wait until finished writing
  //File f = new File(path);
  //while (!f.exists())
  //{
  //}
  println("Exported CSV File to "+path);
}

//Console warranty  and OS info
void warranty() {
  println("Lightwork-Mapper"); 
  println("Copyright (C) 2017  Leó Stefánsson and Tim Rolls @PWRFL"); 
  println("This program comes with ABSOLUTELY NO WARRANTY"); 
  println(""); 
  String os=System.getProperty("os.name"); 
  println("Operating System: "+os);
}

//Closes connections (once deployed as applet)
void stop()
{
  cam =null; 
  super.stop();
}

//Closes connections
void exit()
{
  cam =null; 
  super.exit();
}