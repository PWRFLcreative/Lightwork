/*    //<>//
 *  Lightwork-Mapper
 *  
 *  This sketch uses computer vision to automatically generate mapping for LEDs.
 *  Currently, Fadecandy, PixelPusher, Artnet and sACN are supported.
 *
 *  Required Libraries available from Processing library manager:
 *  PixelPusher, OpenCV, ControlP5, eDMX, oscP5
 *  
 *  Additional Libraries:
 *  ArtNet P5 - included in this repo or from https://github.com/sadmb/artnetP5
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

// IMPORT THE SPOUT LIBRARY
import spout.*;
// DECLARE A SPOUT OBJECT
Spout spout;

boolean spoutSwitch; // to handle switching between capture devices and spout

Capture cam;
//Capture cam2;
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

int camWidth = 960;
int camHeight = 480;
float camAspect;

PGraphics camFBO;
PGraphics cvFBO;
PGraphics blobFBO;

int cvThreshold = 25;
float cvContrast = 1.15;
int ledBrightness = 45;

ArrayList <LED>     leds; // Global, used by Animator and Interface classes
PVector[] leftMap;
PVector[] rightMap;

int FPS = 30; 
String savePath = "../LightWork_Scraper/data/layout.csv"; //defaults to scraper data folder

PImage videoInput; 
PImage cvOutput;

// Image sequence parameters
int numFrames = 10;  // The number of frames in the animation
int currentFrame = 0;
ArrayList <PGraphics> images;
PImage backgroundImage = new PImage();
PGraphics diff; // Background subtracted from Binary Pattern Image
int imageIndex = 0;
int captureTimer = 0; 
boolean shouldStartPatternMatching; // Only start matching once we've decoded a full sequence
boolean shouldStartDecoding; // Start decoding once we've captured all binary pattern states

void setup()
{
  size(960, 700, P3D);
  frameRate(FPS);
  warranty();

  // CREATE A NEW SPOUT OBJECT
  spout = new Spout(this);

  camAspect = (float)camWidth / (float)camHeight;
  println("Cam Aspect: "+camAspect);

  videoMode = VideoMode.CAMERA; 

  println("creating FBOs");
  camFBO = createGraphics(camWidth, camHeight, P3D);
  cvFBO = createGraphics(camWidth, camHeight, P3D);
  blobFBO = createGraphics(camWidth, camHeight, P3D); 

  println("making arraylists for LEDs and bloblist");
  leds = new ArrayList<LED>();

  //Load Camera in a thread, because polling USB can hang the software, and fail OpenGL initialization
  //println("initializing camera");
  //thread("setupCam"); 
  //Thread may be causing strange state issues with PixelPusher
  //setupCam();

  // Network
  println("setting up network Interface");
  network = new Interface();
  //These can be set via UI, but can be faster to set them here. 
  //network.setNumStrips(3);
  //network.setNumLedsPerStrip(16); 
  //network.setNumArtnetChannels(3);
  //network.setNumArtnetFixtures(16); 

  // Animator
  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setFrameSkip(frameSkip);
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(frameSkip);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.update();

  // Check for high resolution display
  println("setup gui multiply");
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }
  // Set up window for 2d mapping
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
  backgroundImage = createImage(camWidth, camHeight, RGB); 

  shouldStartPatternMatching = false; 
  shouldStartDecoding = false; 
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

  // -------------------------------------------------------
  //              VIDEO INPUT + OPENCV PROCESSING
  // -------------------------------------------------------
  if (cam!=null && cam.available()== true && spoutSwitch==false) { 
    cam.read();
    if (videoMode != VideoMode.IMAGE_SEQUENCE) { //TODO: review
      videoInput = cam;
    }
  }

  //Spout receive frame
  if (spoutSwitch== true && spout!=null && videoMode != VideoMode.IMAGE_SEQUENCE) { 
    videoInput = spout.receiveTexture(videoInput);
  }


  // Binary Image Sequence Capture
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
    }
    // If sequence exists assign it to videoInput
    else {
      shouldStartDecoding = true; 
      videoInput = images.get(currentFrame);
      currentFrame++; 
      if (currentFrame >= numFrames) {
        shouldStartPatternMatching = true; // We've decoded a full sequence, start pattern matchin
        currentFrame = 0;
      }
    }
  }

  processCV(); // Call this AFTER videoInput has been assigned


  // -------------------------------------------------------
  //                        DISPLAY
  // -------------------------------------------------------


  // Display the camera input
  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0);
  camFBO.endDraw();
  image(camFBO, 0, (70*guiMultiply), camDisplayWidth, camDisplayHeight);

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

  // Draw a sequence of the sequential captured frames
  if (images.size() > 0) {
    for (int i = 0; i < images.size(); i++) {
      image(images.get(i), i*width/10, camDisplayHeight, width/10, height/10);
    }
    stroke(#00aaff); 
    strokeWeight(3);
    noFill(); 
    rect(currentFrame*width/10, camDisplayHeight, width/10, height/10); //TODO: make this length adjustable
  }

  showLEDOutput(); 
  showBlobCount(); 

  // -------------------------------------------------------
  //                      MAPPING
  // -------------------------------------------------------

  // Calibration mode, use this to tweak your parameters before mapping
  if (videoMode == VideoMode.CALIBRATION) {
    blobManager.update(opencv.getOutput());
  }

  // Decode image sequence
  else if (videoMode == VideoMode.IMAGE_SEQUENCE && images.size() >= numFrames) {
    blobManager.update(opencv.getSnapshot());
    blobManager.display();
    if (shouldStartDecoding) {
      decode();
    }

    if (shouldStartPatternMatching) {
      matchBinaryPatterns();
    }
  } else if (isMapping && !patternMapping) {
    blobManager.update(opencv.getOutput());
    if (frameCount%frameSkip==0) {
      sequentialMapping();
    }
  }
}

// -----------------------------------------------------------
// Mapping methods
// -----------------------------------------------------------


void sequentialMapping() {
  if (blobManager.blobList.size()!=0) {
    Rectangle rect = blobManager.blobList.get(blobManager.blobList.size()-1).contour.getBoundingBox(); 
    PVector loc = new PVector(); 
    loc.set((float)rect.getCenterX(), (float)rect.getCenterY()); 

    int index = animator.getLedIndex(); 
    leds.get(index).setCoord(loc); 
    println(loc);
  }
}

void matchBinaryPatterns() {
  for (int i = 0; i < leds.size(); i++) {
    if (leds.get(i).foundMatch) {
      continue;
    }
    String targetPattern = leds.get(i).binaryPattern.binaryPatternString.toString(); 
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

  // Mapping is done, Save CSV for LEFT or RIGHT channels
  if (stereoMode ==true && mapRight==true) {
    rightMap= new PVector[leds.size()];
    arrayCopy(  getLEDVectors(leds).toArray(), rightMap);
    saveCSV(leds, dataPath("right.csv"));
  } else if (stereoMode ==true) {
    leftMap= new PVector[leds.size()];
    arrayCopy(  getLEDVectors(leds).toArray(), leftMap);
    saveCSV(leds, dataPath("left.csv"));
  }

  network.saveOSC(normCoords(leds));

  map();
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
      blobManager.blobList.get(i).decode(br); // Decode the pattern
    }
  }
}

// OpenCV Processing
void processCV() {
  diff.beginDraw(); 
  //diff.background(0); 
  diff.blendMode(NORMAL); 
  diff.image(videoInput, 0, 0); 
  diff.blendMode(SUBTRACT); 
  diff.image(backgroundImage, 0, 0); 
  diff.endDraw(); 
  opencv.loadImage(diff); 
  opencv.contrast(cvContrast); 
  opencv.threshold(cvThreshold);
}

// Count LEDs that have been matched
int listMatchedLEDs() {
  int count=0; 
  for (LED led : leds) {
    if (led.foundMatch==true) count++;
  }
  return count;
}

// Return LED locations as PVectors
ArrayList<PVector> getLEDVectors(ArrayList<LED> l) {
  ArrayList<PVector> loc= new ArrayList<PVector>();
  for (int i = 0; i<l.size(); i++) {
    PVector temp=new PVector();
    temp = l.get(i).coord;
    loc.add(temp);
  } 
  return loc;
}

// Estimate LED z location from left and right captures
void calculateZ(PVector[] l, PVector[] r) {
  for (int i = 0; i<l.length; i++) {
    if (l[i].x!=0 && l[i].y!=0 && r[i].x!=0 && r[i].y!=0) {
      float z = l[i].dist(r[i]); // change from left to right capture
      leds.get(i).coord.set(r[i].x, r[i].y, z);
    }
  }
}

// Deterimine bounding box of points for normalizing
float[] getMinMaxCoords(ArrayList<PVector> pointsCopy) {
  //ArrayList<PVector> pointsCopy = new ArrayList<PVector>(points);

  for (int i=pointsCopy.size()-1; i>=0; i--) {
    PVector temp = pointsCopy.get(i);
    if (temp.x==0 && temp.y==0) {
      pointsCopy.remove(i);
    }
  }

  float xArr[] = new float[pointsCopy.size()];
  float yArr[] = new float[pointsCopy.size()];
  float zArr[] = new float[pointsCopy.size()];

  int index =0;
  for (PVector temp : pointsCopy) {
    xArr[index] = temp.x;
    yArr[index] = temp.y;
    zArr[index] = temp.z;

    index++;
  }

  float minX = min(xArr);
  float minY = min(yArr);
  float minZ = min(zArr);
  float maxX = max(xArr);
  float maxY = max(yArr);
  float maxZ = max(zArr);

  float[] out = {minX, minY, minZ, maxX, maxY, maxZ };
  return out;
}

// Normalize point coordinates 
ArrayList<LED> normCoords(ArrayList<LED> in)
{

  //check for at least 1 matched LED and we are pattern mapping
  if (listMatchedLEDs()==0 && patternMapping) {
    println("no LEDs matched");
    return in;
  }

  float[] norm = new float[6];
  norm = getMinMaxCoords(getLEDVectors(in));

  ArrayList<LED> out = in;
  int index=0;

  for (LED temp : out) {
    // Ignore 0,0 coordinates
    if (temp.coord.x>0 && temp.coord.y>0) {
      if (temp.coord.z!=0) {
        // 3D coords
        temp.coord.set (map(temp.coord.x, norm[0], norm[3], 0.001, 1), map(temp.coord.y, norm[1], norm[4], 0.001, 1), map(temp.coord.z, norm[2], norm[5], 0.001, 1));
        out.set(index, temp);
      } else {
        //// 2D coords
        //temp.coord.set (map(temp.coord.x, norm[0], norm[3], 0.001, 1), map(temp.coord.y, norm[1], norm[4], 0.001, 1));
        //out.set(index, temp);

        // 2D coords based on cam dimensions, not outer extents of points
        temp.coord.set (map(temp.coord.x, 0, camWidth, 0.001, 1), map(temp.coord.y, 0, camHeight, 0.001, 1));
        out.set(index, temp);
      }
    }
    index++;
  }

  return out;
}

// -----------------------------------------------------------
// -----------------------------------------------------------
// Utility methods

//used to thread camera initialization. USB enumeration can be slow, and if it exceeds 5seconds the app will fail at startup. 
void setupCam() {
  cam = new Capture(this, camWidth, camHeight, 30);
}

void saveSVG(ArrayList <PVector> points) {
  if (points.size() == 0) {
    // User is trying to save without anything to output - bail
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
  }
  output.close(); // Finishes the file
  println("Exported CSV File to "+path);
}

// Console warranty  and OS info
void warranty() {
  println("Lightwork-Mapper"); 
  println("Copyright (C) 2017  Leó Stefánsson and Tim Rolls @PWRFL"); 
  println("This program comes with ABSOLUTELY NO WARRANTY"); 
  println(""); 
  String os=System.getProperty("os.name"); 
  println("Operating System: "+os);
}

// Close connections (once deployed as applet)
void stop()
{
  cam = null; 
  super.stop();
}

// Closes connections
void exit()
{
  cam  = null; 
  super.exit();
}
