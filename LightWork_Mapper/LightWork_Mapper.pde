//  //<>// //<>// //<>//
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


Capture cam;
Movie movie;
OpenCV opencv;
ControlP5 cp5;
ControlP5 topPanel;
Animator animator;
Interface network; 

boolean isMapping=false;

enum  VideoMode {
  CAMERA, FILE, OFF
};

VideoMode videoMode; 
String movieFilePath = "data/binaryRecording.mp4";

color on = color(255, 255, 255);
color off = color(0, 0, 0);

int camWidth =640;
int camHeight =480;
float camAspect = (float)camWidth / (float)camHeight;
PGraphics camFBO;
PGraphics cvFBO;

int cvThreshold = 10;
float cvContrast = 1.35;

ArrayList <PVector>     coords;
String savePath = "layout.svg";

ArrayList <LED>     leds;

int FPS = 30; 
VideoExport videoExport;
boolean isRecording = false;

void setup()
{
  size(640, 480, P2D);
  frameRate(FPS);
  videoMode = VideoMode.CAMERA; 

  camFBO = createGraphics(camWidth, camHeight, P2D);
  cvFBO = createGraphics(camWidth, camHeight, P2D);

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
    //println("Available cameras:");
    //printArray(cameras);
    //cam = new Capture(this, camWidth, camHeight, 30);
    //cam = new Capture(this, cameras[0]);
    cam = new Capture(this, camWidth, camHeight, cameras[0], FPS);
    cam.start();
  }
  videoExport = new VideoExport(this, movieFilePath, cam);

  opencv = new OpenCV(this, camWidth, camHeight);
  opencv.startBackgroundSubtraction(2, 5, 0.5); //int history, int nMixtures, double backgroundRatio
  //opencv.startBackgroundSubtraction(50, 30, 1.0);

  network = new Interface();

  animator =new Animator(); //ledsPerstrip, strips, brightness
  animator.setLedBrightness(150);
  animator.setFrameSkip(5);
  animator.setAllLEDColours(off); // Clear the LED strips

  //Check for hi resolution display
  int guiMultiply = 1;
  if (displayWidth >= 2560) {
    guiMultiply = 2;
  }

  //Window size based on screen dimensions, centered
  surface.setSize((int)(displayHeight / 2 * camAspect + (200 * guiMultiply)), (int)(displayHeight*0.9));
  surface.setLocation((displayWidth / 2) - width / 2, ((int)displayHeight / 2) - height / 2);

  cp5 = new ControlP5(this);
  topPanel = new ControlP5(this);
  buildUI(guiMultiply);
}

void draw()
{

  // Display the camera input and processed binary image
  if (cam.available() && videoMode == VideoMode.CAMERA) {
    //UI is drawn on canvas background, update to clear last frame's UI changes
    background(#111111);

    cam.read();
    camFBO.beginDraw();
    camFBO.image(cam, 0, 0, camWidth, camHeight);
    camFBO.endDraw();

    image(camFBO, 0, 0, (height / 2)*camAspect, height/2);

    opencv.loadImage(cam);
    // Gray channel
    opencv.gray();
    opencv.threshold(cvThreshold);
    opencv.contrast(cvContrast);

    opencv.updateBackground();
    opencv.equalizeHistogram();

    //these help close holes in the binary image
    opencv.dilate();
    opencv.erode();
    opencv.blur(2);

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

    image(cvFBO, 0, height/2, (height / 2)*camAspect, height/2);
  } else if (videoMode == VideoMode.FILE) {
  }

  if (isMapping) {
    //sequentialMapping();
    binaryMapping();
  }
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
      loadMovieFile(movieFilePath);
      println("VideoMode: FILE");
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
    movie = new Movie(this, path);
  }
  return f.exists();
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