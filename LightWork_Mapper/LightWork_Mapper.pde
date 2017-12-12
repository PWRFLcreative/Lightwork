/*   //<>// //<>//
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
int ledBrightness = 150;


enum  VideoMode {
  CAMERA, FILE, IMAGE_SEQUENCE, CALIBRATION, OFF
};

VideoMode videoMode; 

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth = 640;
int camHeight = 480;
float camAspect;
int camWindows = 2;
PGraphics camFBO;
PGraphics cvFBO;
PGraphics blobFBO;

int cvThreshold = 100;
float cvContrast = 1.15;

ArrayList <LED>     leds;

int FPS = 30; 

PImage videoInput; 
PImage cvOutput;

// Actual display size for camera
int camDisplayWidth, camDisplayHeight;
Rectangle camArea;

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
  //pixelDensity(displayDensity());
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
  network.setNumStrips(6);
  network.setNumLedsPerStrip(40); // TODO: Fix these setters...
  //network.populateLeds();

  // Animator
  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(10);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.setMode(AnimationMode.OFF);
  animator.update();

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
  
  // DEBUG MODE: For my convenience, remove before testing/publishing
  camera(0);
  
}

// -----------------------------------------------------------
// -----------------------------------------------------------
void draw() {
  // LOADING SCREEN
  if (!isUIReady) {
    background(0);
    if (frameCount%1000==0) {
      println("DrawLoop: Building UI....");
    }

    int size = (millis()/5%255);

    pushMatrix(); 
    translate(width/2, height/2);
    noFill();
    stroke(255, size);
    strokeWeight(4);
    ellipse(0, 0, size, size);
    translate(0, 200);
    fill(255);
    noStroke();
    textSize(18);
    textAlign(CENTER);
    text("LOADING...", 0, 0);
    popMatrix();

    return;
  } else if (!cp5.isVisible()) {
    cp5.setVisible(true);
  }
  // END LOADING SCREEN 

  // Update the LEDs (before we do anything else). 
  animator.update();

  // Video Input Assignment (Camera or Image Sequence)
  // Read the video input (webcam or videofile)
  if (videoMode == VideoMode.CAMERA && cam!=null ) { 
    cam.read();
    videoInput = cam;
  } else if (videoMode == VideoMode.IMAGE_SEQUENCE && cam.available() && isMapping) {

    // Capture sequence if it doesn't exist
    if (images.size() < numFrames) {
      cam.read();
      PGraphics pg = createGraphics(640, 480, P2D);
      pg.beginDraw();
      pg.image(cam, 0, 0);
      pg.endDraw();
      captureTimer++;
      if (captureTimer == animator.frameSkip/2) { // Capture halfway through animation frame
        println("adding image frame to sequence");
        images.add(pg);
      } else if (captureTimer >= animator.frameSkip) { // Reset counter when frame is done
        captureTimer = 0;
      }

      videoInput = cam;
      //processCV(); // TODO: This causes the last bit of the sequence to not register resulting
      //        in every other LED not being decoded (and detected) properly
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
      blobManager.processCV();
    }
    // Assign diff to videoInput
  }

  // Calibration mode, use this to tweak your parameters before mapping
  else if (videoMode == VideoMode.CALIBRATION && cam.available()) {
    cam.read(); 
    videoInput = cam; 
    // Background diff
    blobManager.processCV();
  }

  //UI is drawn on canvas background, update to clear last frame's UI changes
  background(#222222);

  // Display the camera input
  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0, camWidth, camHeight);
  camFBO.endDraw();
  image(camFBO, 0, (70), camDisplayWidth, camDisplayHeight);

  // OpenCV processing

  //if (videoMode == VideoMode.IMAGE_SEQUENCE) {
  //  opencv.loadImage(diff);
  //  opencv.diff(backgroundImage);
  //} else {
  //  opencv.loadImage(camFBO);
  //}


  // Decode image sequence

  if (videoMode == VideoMode.IMAGE_SEQUENCE && images.size() >= numFrames) {
    blobManager.updateBlobs(); 
    blobManager.displayBlobs();
    blobManager.decodeBlobs();
    if (shouldStartDecoding) {
      matchBinaryPatterns();
    }
  }


  // Display OpenCV output and dots for detected LEDs (dots for sequential mapping only). 
  cvFBO.beginDraw();
  PImage snap = opencv.getSnapshot(); 
  cvFBO.image(snap, 0, 0, 640, 480);
  if (leds.size()>0) {
    for (LED led : leds) {
      cvFBO.noFill();
      cvFBO.stroke(255, 0, 0);
      cvFBO.ellipse(led.coord.x, led.coord.y, 10, 10);
    }
  }
  cvFBO.endDraw();
  image(cvFBO, camDisplayWidth, 70, camDisplayWidth, camDisplayHeight);

  if (isMapping) {
    blobManager.processCV(); 
    blobManager.updateBlobs(); // Find and manage blobs
    blobManager.displayBlobs(); 
    if(!patternMapping){sequentialMapping();}
  }

  // Display blobs
  blobFBO.beginDraw();
  blobManager.displayBlobs();
  blobFBO.endDraw(); //<>//

  // Draw the array of colors going out to the LEDs
  if (showLEDColors) {
    // scale based on window size and leds in array
    float x = (float)width/ (float)leds.size(); //TODO: display is missing a bit on the right?
    for (int i = 0; i<leds.size(); i++) {
      fill(leds.get(i).c);
      noStroke();
      rect(i*x, (camArea.y+camArea.height)-(5), x, 5);
    }
  }
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
    //println(loc);
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

  println("CSV saved");
  for (int i = 0; i < ledArray.size(); i++) {
    output.println(ledArray.get(i).address+","+ledArray.get(i).coord.x+","+ledArray.get(i).coord.y+","+ledArray.get(i).coord.z);
    println(ledArray.get(i).address+" "+ledArray.get(i).coord.x+" "+leds.get(i).coord.y);
  }
  output.close(); // Finishes the file
  println("Exported CSV File to "+path);
}

//Filter duplicates from point array
//ArrayList <PVector> removeDuplicates(ArrayList <PVector> points) {
//  println( "Removing duplicates");

//  float thresh = 3.0; 

//  // Iterate through all the points and remove duplicates and 'extra' points (under threshold distance).
//  for (PVector p : points) {
//    float i = points.get(1).dist(p); // distance to current point, used to avoid comporating a point to itself
//    //PVector pt = p;

//    // Do not remove 0,0 points (they're 'invisible' LEDs, we need to keep them).
//    if (p.x == 0 && p.y == 0) {
//      continue; // Go to the next iteration
//    }

//    // Compare point to all other points
//    for (Iterator iter = points.iterator(); iter.hasNext();) {
//      PVector item = (PVector)iter.next();
//      float j = points.get(1).dist(item); 
//      //PVector pt2 = item;
//      float dist = p.dist(item);

//      // Comparing point to itself... do nothing and move on.
//      if (i == j) {
//        //ofLogVerbose("tracking") << "COMPARING POINT TO ITSELF " << pt << endl;
//        continue; // Move on to the next j point
//      }
//      // Duplicate point detection. (This might be covered by the distance check below and therefor redundant...)
//      //else if (pt.x == pt2.x && pt.y == pt2.y) {
//      //  //ofLogVerbose("tracking") << "FOUND DUPLICATE POINT (that is not 0,0) - removing..." << endl;
//      //  iter = points.remove(iter);
//      //  break;
//      //}
//      // Check point distance, remove points that are too close
//      else if (dist < thresh) {
//        println("removing duplicate point");
//        points.remove(iter);
//        break;
//      }
//    }
//  }

//  return points;
//}

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