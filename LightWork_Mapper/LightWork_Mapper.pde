//  LED_Mapper.pde //<>// //<>// //<>// //<>//
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
Capture cam2;
OpenCV opencv;
OpenCV blobCV; // Separate CV instance for blob tracking because. Using only one results in different image processing when calling opencv.findContours()
ControlP5 cp5;
Animator animator;
Interface network; 

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

int guiMultiply = 1;

int cvThreshold = 100;
float cvContrast = 1.15;

String savePath;

ArrayList <LED>     leds;

int FPS = 30; 

PImage videoInput; 
PImage cvOutput;

ArrayList<Contour> contours;
// List of detected contours parsed as blobs (every frame)
ArrayList<Contour> newBlobs;
// List of my blob objects (persistent)
ArrayList<Blob> blobList;
// Number of blobs detected over all time. Used to set IDs.
int blobCount = 0; // Use this to assign new (unique) ID's to blobs
int minBlobSize = 1;
int maxBlobSize = 10;
float distanceThreshold = 1; 

// Window size
int windowSizeX, windowSizeY;

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
  size(640, 480, P3D);
  frameRate(FPS);
  camAspect = (float)camWidth / (float)camHeight;
  println(camAspect);

  videoMode = VideoMode.CAMERA; 

  println("creating FBOs");
  camFBO = createGraphics(camWidth, camHeight, P3D);
  cvFBO = createGraphics(camWidth, camHeight, P3D);
  blobFBO = createGraphics(camWidth, camHeight, P3D); 

  println("making arraylists for LEDs and bloblist");
  leds = new ArrayList<LED>();

  // Blobs list
  blobList = new ArrayList<Blob>();
  cam = new Capture(this, camWidth, camHeight, 30);

  // Network
  println("setting up network Interface");
  network = new Interface();
  network.setNumStrips(3);
  network.setNumLedsPerStrip(50); // TODO: Fix these setters...

  // Animator
  println("creating animator");
  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(ledBrightness);
  animator.setFrameSkip(18);
  animator.setAllLEDColours(off); // Clear the LED strips
  animator.setMode(AnimationMode.OFF);
  animator.update();

  //Check for high resolution display
  println("setup gui multiply");
  guiMultiply = 1;
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }

  //set up window for 2d mapping
  window2d();

  println("calling buildUI on a thread");
  thread("buildUI"); // This takes more than 5 seconds and will break OpenGL if it's not on a separate thread

  // Make sure there's always something in videoInput
  println("allocating videoInput with empty image");
  videoInput = createImage(camWidth, camHeight, RGB);

  // OpenCV Setup
  println("Setting up openCV");
  opencv = new OpenCV(this, videoInput);
  blobCV =  new OpenCV(this, opencv.getSnapshot());

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
    translate(0, 100*guiMultiply);
    fill(255);
    noStroke();
    textSize(18*guiMultiply);
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
  } else if (videoMode == VideoMode.IMAGE_SEQUENCE && cam.available()) {

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
      processCV();
    }
    // Assign diff to videoInput
  }

  // Calibration mode, use this to tweak your parameters before mapping
  else if (videoMode == VideoMode.CALIBRATION && cam.available()) {
    cam.read(); 
    videoInput = cam; 
    // Background diff
    processCV();
  }

  //UI is drawn on canvas background, update to clear last frame's UI changes
  background(#222222);

  // Display the camera input
  camFBO.beginDraw();
  camFBO.image(videoInput, 0, 0, camWidth, camHeight);
  camFBO.endDraw();
  image(camFBO, 0, (70*guiMultiply), camDisplayWidth, camDisplayHeight);

  // OpenCV processing
  /*
  if (videoMode == VideoMode.IMAGE_SEQUENCE) {
   opencv.loadImage(diff);
   opencv.diff(backgroundImage);
   } else {
   opencv.loadImage(camFBO);
   }
   */

  // Decode image sequence


  if (videoMode == VideoMode.IMAGE_SEQUENCE && images.size() >= numFrames) {
    updateBlobs(); 
    displayBlobs();
    decodeBlobs();
    if (shouldStartDecoding) {
      matchBinaryPatterns();
    }
  }


  // Display OpenCV output and dots for detected LEDs (dots for sequential mapping only). 
  cvFBO.beginDraw();
  cvFBO.image(opencv.getSnapshot(), 0, 0);
  if (leds.size()>0) {
    for (LED led : leds) {
      cvFBO.noFill();
      cvFBO.stroke(255, 0, 0);
      cvFBO.ellipse(led.coord.x, led.coord.y, 10, 10);
    }
  }
  cvFBO.endDraw();
  image(cvFBO, camDisplayWidth, (70*guiMultiply), camDisplayWidth, camDisplayHeight);

  // Secondary Camera for Stereo Capture
  if (camWindows==3 && cam2!=null) {
    cam2.read();
    image(cam2, camDisplayWidth*2, (70*guiMultiply), camDisplayWidth, camDisplayHeight);
  }

  if (isMapping) {
    updateBlobs(); // Find and manage blobs
    sequentialMapping();
  }

  // Display blobs
  blobFBO.beginDraw();
  displayBlobs();
  blobFBO.endDraw();

  // Draw the array of colors going out to the LEDs
  if (showLEDColors) {
    // scale based on window size and leds in array
    float x = (float)width/ (float)leds.size(); //TODO: display is missing a bit on the right?
    for (int i = 0; i<leds.size(); i++) {
      fill(leds.get(i).c);
      noStroke();
      rect(i*x, (camArea.y+camArea.height)-(5*guiMultiply), x, 5*guiMultiply);
    }
  }
}

// -----------------------------------------------------------
// -----------------------------------------------------------

void processCV() {
  diff.beginDraw();
  diff.background(0);
  diff.blendMode(NORMAL);
  diff.image(videoInput, 0, 0);
  diff.blendMode(SUBTRACT);
  diff.image(backgroundImage, 0, 0);
  diff.endDraw();
  //image(diff, 0, 0); 
  opencv.loadImage(diff);
  opencv.contrast(cvContrast);
  opencv.threshold(cvThreshold);
}

// Mapping methods
void sequentialMapping() {
  //for (Contour contour : opencv.findContours()) {
  //  noFill();
  //  stroke(255, 0, 0);
  //  //contour.draw();
  //  coords.add(new PVector((float)contour.getBoundingBox().getCenterX(), (float)contour.getBoundingBox().getCenterY()));
  //}

  if (blobList.size()!=0) {
    Rectangle rect = blobList.get(blobList.size()-1).contour.getBoundingBox();
    PVector loc = new PVector(); 
    loc.set((float)rect.getCenterX(), (float)rect.getCenterY());

    int index = animator.getLedIndex();
    leds.get(index).setCoord(loc);
    println(loc);
  }
}

void updateBlobs() {
  // Find all contours
  blobCV.loadImage(opencv.getSnapshot());
  ArrayList<Contour> contours = blobCV.findContours();

  // Filter contours, remove contours that are too big or too small
  // The filtered results are our 'Blobs' (Should be detected LEDs)
  ArrayList<Contour> newBlobs = filterContours(contours); // Stores all blobs found in this frame

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
  // Update brightness levels for all the blobs
  if (blobList.size() > 0) {
    for (int i = 0; i < blobList.size(); i++) {
      // Get the blob brightness to determine it's state (HIGH/LOW)
      //println("decoding this blob: "+blobList.get(i).id);
      Rectangle r = blobList.get(i).contour.getBoundingBox();
      // TODO: Which texture do we decode?
      PImage snap = opencv.getSnapshot();
      PImage cropped = snap.get(r.x, r.y, r.width, r.height); // TODO: replace with videoInput
      int br = 0; 
      for (color c : cropped.pixels) {
        br += brightness(c);
      }

      br = br/ cropped.pixels.length;

      blobList.get(i).registerBrightness(br); // Set blob brightness
      blobList.get(i).decode(); // Decode the pattern
    }
  }
}

void matchBinaryPatterns() {
  for (int i = 0; i < leds.size(); i++) {
    if (leds.get(i).foundMatch) {
      return;
    }
    String targetPattern = leds.get(i).binaryPattern.binaryPatternString.toString(); 
    //println("finding target pattern: "+targetPattern);
    for (int j = 0; j < blobList.size(); j++) {
      String decodedPattern = blobList.get(j).detectedPattern.decodedString.toString(); 
      //println("checking match with decodedPattern: "+decodedPattern);
      if (targetPattern.equals(decodedPattern)) {
        leds.get(i).foundMatch = true; 
        Rectangle rect = blobList.get(j).contour.getBoundingBox();
        PVector pvec = new PVector(); 
        pvec.set((float)rect.getCenterX(), (float)rect.getCenterY());
        leds.get(i).setCoord(pvec);
        println("LED: "+i+" Blob: "+j+" --- "+targetPattern + " --- " + decodedPattern);
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

//void displayContoursBoundingBoxes() {

//  for (int i=0; i<contours.size(); i++) {

//    Contour contour = contours.get(i);
//    Rectangle r = contour.getBoundingBox();

//    if (//(contour.area() > 0.9 * src.width * src.height) ||
//      (r.width < minBlobSize || r.height < minBlobSize))
//      continue;

//    stroke(255, 0, 0);
//    fill(255, 0, 0, 150);
//    strokeWeight(2);
//    rect(r.x, r.y, r.width, r.height);
//  }
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