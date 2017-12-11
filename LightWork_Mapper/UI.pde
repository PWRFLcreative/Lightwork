/* //<>// //<>//
 *  UI
 *  
 *  This class builds the UI for the application
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @authors Leó Stefánsson and Tim Rolls
 */

import controlP5.*;

Textarea cp5Console;
Println console;
RadioButton r1, r2;
Range blob;
Textlabel tl1;

boolean isUIReady = false;
boolean showLEDColors = true;
boolean patternMapping = true;
boolean stereoMode = false;

int frameSkip = 12;

String savePath;

void buildUI() {
  println("setting up ControlP5");

  cp5 = new ControlP5(this);
  cp5.setVisible(false);
  //cp5.getProperties().setFormat(ControlP5.SERIALIZED);

  cp5.enableShortcuts();

  //check for defaults file  
  File defaults = new File("controlP5.json");

  float startTime = millis(); 
  println("Building UI... at time: " + startTime);
  int uiGrid = 60;
  int uiSpacing = 20;
  int buttonHeight = 30;
  int buttonWidth =150;

  println("Creating font...");
  PFont pfont = createFont("OpenSans-Regular.ttf", 12, false); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont, 12);
  cp5.setFont(font);
  cp5.setColorBackground(#333333);
  cp5.setPosition(uiSpacing, uiSpacing);

  cp5.mapKeyFor(new ControlKey() {
    public void keyEvent() {
    }
  }
  , ALT);


  Group top = cp5.addGroup("top")
    .setPosition(0, 0)
    .setBackgroundHeight(30)
    .setWidth(width-uiSpacing*2)
    //.setBackgroundColor(color(255, 50))
    //.disableCollapse()
    .hideBar()
    ;

  Group net = cp5.addGroup("network")
    .setPosition(0, (70)+camDisplayHeight)
    .setBackgroundHeight(200)
    .setWidth(uiGrid*4)
    //.setBackgroundColor(color(255, 50))
    .hideBar()
    ;

  Group settings = cp5.addGroup("settings")
    .setPosition((uiGrid+uiSpacing)*4, (70)+camDisplayHeight)
    .setBackgroundHeight(200)
    .setWidth(uiGrid*4)
    //.setBackgroundColor(color(255, 50))
    .hideBar()
    ;

  Group mapping = cp5.addGroup("mapping")
    .setPosition((uiGrid+uiSpacing)*8, (70)+camDisplayHeight)
    .setBackgroundHeight(200)
    .setWidth(uiGrid*4)
    //.setBackgroundColor(color(255, 50))
    .hideBar()
    ;

  Group buttons = cp5.addGroup("buttons")
    .setPosition(-uiSpacing, height-70)
    .setBackgroundHeight(70)
    .setWidth(width)
    .setBackgroundColor(color(70))
    .hideBar()
    ;

  //loadWidth = width/12*6;
  println("adding textfield for IP");
  cp5.addTextfield("ip")
    .setCaptionLabel("ip address")
    .setPosition(0, buttonHeight+uiSpacing)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setGroup("network")
    .setValue(network.getIP())
    .setVisible(false)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  println("adding textfield for ledsPerStrip");
  cp5.addTextfield("leds_per_strip")
    .setCaptionLabel("leds per strip")
    .setPosition(0, buttonHeight*2+uiSpacing*2)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setGroup("network")
    .setValue(str(network.getNumLedsPerStrip()))
    .setVisible(false)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  println("adding textfield for strips");
  cp5.addTextfield("strips")
    .setPosition(0, buttonHeight*3+uiSpacing*3)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setGroup("network")
    .setValue(str(network.getNumStrips()))
    .setVisible(false)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  println("listing drivers");
  //draw after text boxes so the dropdown overlaps properly
  List driver = Arrays.asList("PixelPusher", "Fadecandy"); //"ArtNet"  removed for now - throws errors
  println("adding scrollable list for drivers");
  cp5.addScrollableList("driver")
    .setPosition(0, 0)
    .setSize(int(buttonWidth*1.5), 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(driver)
    .setType(ControlP5.DROPDOWN)
    .setOpen(false)
    .bringToFront() 
    .setGroup("network");
  ;
  //TODO  fix style on dropdown 
  cp5.getController("driver").getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER).setPaddingX(uiSpacing);

  println("adding connect button");
  cp5.addButton("connect")
    .setPosition(uiSpacing, uiSpacing/2)
    .setSize(buttonWidth/2-2, buttonHeight)
    .setGroup("buttons");
  ;

  println("adding contrast slider");
  cp5.addSlider("cvContrast")
    .setCaptionLabel("contrast")
    .setBroadcast(false)
    .setPosition(0, 0)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 5)
    .setValue(cvContrast)
    .setGroup("settings")
    .setMoveable(false)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  ////set labels to bottom
  //cp5.getController("cvContrast").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("cvContrast").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for cvThreshold");
  cp5.addSlider("cvThreshold")
    .setCaptionLabel("threshold")
    .setBroadcast(false)
    .setPosition(0, buttonHeight+uiSpacing)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 255)
    .setValue(cvThreshold)
    .setGroup("settings")
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)

    ;

  ////set labels to bottom
  //cp5.getController("cvThreshold").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("cvThreshold").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for ledBrightness");
  cp5.addSlider("ledBrightness")
    .setCaptionLabel("led brightness")
    .setBroadcast(false)
    .setPosition(0, (buttonHeight+uiSpacing)*2)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 255)
    .setValue(ledBrightness)
    .setGroup("settings")
    //.plugTo(ledBrightness)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  ////set labels to bottom
  //cp5.getController("ledBrightness").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("ledBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  //Mapping type toggle
  List mapToggle = Arrays.asList("Pattern", "Sequence");
  ButtonBar b = cp5.addButtonBar("mappingToggle")
    .setPosition(0, (buttonHeight+uiSpacing)*3)
    .setSize(buttonWidth, buttonHeight)
    .addItems(mapToggle)
    //.setId(0)
    .setGroup("settings")
    ;

  tl1 = cp5.addTextlabel("mapMode")
    .setText("MAPPING MODE")
    .setPosition(buttonWidth+5, 5+(buttonHeight+uiSpacing)*3)
    .setGroup("settings")
    .setFont(font)
    ;

  println("adding test button");
  cp5.addButton("calibrate")
    .setPosition((uiGrid+uiSpacing)*4+uiSpacing, uiSpacing/2)
    .setSize(buttonWidth/2-2, buttonHeight)
    .setGroup("buttons")
    ;

  println("adding map button"); 
  cp5.addButton("map")
    .setPosition((uiGrid+uiSpacing)*4+(buttonWidth/2)+2+uiSpacing, uiSpacing/2)
    .setSize(buttonWidth/2-2, buttonHeight)
    .setGroup("buttons")
    .setCaptionLabel("map")
    ;
    
  cp5.addButton("map2")
    .setPosition((uiGrid+uiSpacing)*4+buttonWidth+2+uiSpacing, uiSpacing/2)
    .setSize(buttonWidth/2-2, buttonHeight)
    .setGroup("buttons")
    .setCaptionLabel("map right")
    .setVisible(false)
    ;

  println("adding save button");
  cp5.addButton("saveLayout")
    .setCaptionLabel("Save Layout")
    .setPosition((uiGrid+uiSpacing)*8+uiSpacing, uiSpacing/2)
    .setSize(int(buttonWidth*.75), buttonHeight)
    .setGroup("buttons")
    ;

  //println("adding settings button");
  //cp5.addButton("saveSettings")
  //  .setCaptionLabel("Save Settings")
  //  .setPosition((uiGrid+uiSpacing)*8+uiSpacing+int(buttonWidth*.75)+4, uiSpacing/2)
  //  .setSize(int(buttonWidth*.75), buttonHeight)
  //  .setGroup("buttons")
  //  ;

  println("adding frameskip slider");
  cp5.addSlider("frameskip")
    .setBroadcast(false)
    .setPosition(0, 0)
    .setSize(buttonWidth, buttonHeight)
    .setRange(6, 30)
    .plugTo(frameSkip)
    .setGroup("mapping")
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  println("adding blob range slider");
  blob = cp5.addRange("blobSize")
    // disable broadcasting since setRange and setRangeValues will trigger an event
    .setBroadcast(false) 
    .setCaptionLabel("min/max blob size")
    .setPosition(0, buttonHeight+uiSpacing)
    .setSize(buttonWidth, buttonHeight)
    .setHandleSize(10)
    .setRange(1, 100)
    .setRangeValues(minBlobSize, maxBlobSize)
    .setGroup("mapping")
    // after the initialization we turn broadcast back on again
    .setBroadcast(true)
    //.setColorForeground(color(255, 40))
    //.setColorBackground(color(255, 40))  
    ;

  println("adding blob distance slider");
  cp5.addSlider("distance")
    .setBroadcast(false)
    .setCaptionLabel("min blob distance")
    .setPosition(0, (buttonHeight+uiSpacing)*2)
    .setSize(buttonWidth, buttonHeight)
    .setRange(1, 10)
    .plugTo(distanceThreshold)
    .setGroup("mapping")
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;


  //loadWidth = width/12*9;
  //capture console events to ui

  //cp5Console = cp5.addTextarea("cp5Console")
  //  .setPosition((cp5.get("settings").getWidth())*2 +uiSpacing*2, (70)+camDisplayHeight)
  //  .setSize((uiGrid*4)-uiSpacing, 180)
  //  .setFont(createFont("", 12))
  //  .setLineHeight(16)
  //  .setColor(color(200))
  //  .setColorBackground(color(#333333))
  //  .setColorForeground(color(255, 100))
  //  ;
  //;

  //println("adding console");
  //TODO: IS this breaking things?
  //console = cp5.addConsole(cp5Console).;//
  //console.play();

  println("add framerate panel");
  cp5.addFrameRate().setPosition((camDisplayWidth*2)-uiSpacing*3, 0);

  //cp5.addToggle("videoIn")
  //  .setBroadcast(false)
  //  .setCaptionLabel("Video In")
  //  .setPosition((buttonWidth*1.5)+uiSpacing*2, 0)    
  //  .setSize(buttonWidth/4, buttonHeight)
  //  .setGroup("top")
  //  .setValue(true)
  //  .setMode(ControlP5.SWITCH)
  //  .setBroadcast(true)
  //  .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
  //  ;

  cp5.addToggle("stereoToggle")
    .setBroadcast(false)
    .setCaptionLabel("Stereo Toggle")
    .setPosition((buttonWidth*2)+uiSpacing*3, 0)    
    .setSize(buttonWidth/3, buttonHeight)
    .setGroup("top")
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5, 5)
    ;

  //Refresh connected cameras
  println("cp5: adding refresh button");
  cp5.addButton("refresh")
    .setPosition(int(buttonWidth*1.5)+uiSpacing, 0)
    .setSize(buttonWidth/2, buttonHeight)
    .setGroup("top")
    ;

  String[] cams = enumerateCams();
  // made last - enumerating cams will break the ui if done earlier in the sequence
  println("cp5: adding camera dropdown list");
  cp5.addScrollableList("camera")
    .setPosition(0, 0)
    .setSize(int(buttonWidth*1.5), 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(cams)
    .setOpen(false)
    .setGroup("top")
    ;

  // made last - enumerating cams will break the ui if done earlier in the sequence
  //println("cp5: adding camera dropdown list");
  //cp5.addScrollableList("camera2")
  //  .setPosition(buttonWidth*3+uiSpacing*4, 0)
  //  .setSize(buttonWidth, 300)
  //  .setBarHeight(buttonHeight)
  //  .setItemHeight(buttonHeight)
  //  .addItems(cams)
  //  .setOpen(false)
  //  .setVisible(false)
  //  .setGroup("top")
  //  ;

  //load defaults
  if (defaults.exists()) {
    cp5.loadProperties("controlP5.json");
    cp5.update();
  }

  // Wrap up, report done
  //loadWidth = width;
  float deltaTime = millis()-startTime; 
  println("Done building GUI, total time: " + deltaTime + " ms"); 
  cp5.setVisible(true);
  isUIReady = true;
}

//////////////////////////////////////////////////////////////
// Event Handlers
//////////////////////////////////////////////////////////////

void camera(int n) {
  Map m = cp5.get(ScrollableList.class, "camera").getItem(n);
  //println(m);
  String label=m.get("name").toString();
  //println(label);
  switchCamera(label);
}


void driver(int n) { 
  String label = cp5.get(ScrollableList.class, "driver").getItem(n).get("name").toString().toUpperCase();

  if (label.equals("PIXELPUSHER")) {
    network.setMode(device.PIXELPUSHER);
    cp5.get(Textfield.class, "ip").setVisible(false);
    cp5.get(Textfield.class, "leds_per_strip").setVisible(false);
    cp5.get(Textfield.class, "strips").setVisible(false);
    println("network: PixelPusher");
  }
  if (label.equals("FADECANDY")) {
    network.setMode(device.FADECANDY);
    cp5.get(Textfield.class, "ip").setVisible(true);
    cp5.get(Textfield.class, "leds_per_strip").setVisible(true);
    cp5.get(Textfield.class, "strips").setVisible(true);
    println("network: Fadecandy");
  }
  if (label.equals("ARTNET")) {
    network.setMode(device.ARTNET);
    println("network: ArtNet");
  }
}

public void ip(String theText) {
  println("IP set to : "+theText);
  network.setIP(theText);
}

public void leds_per_strip(String theText) {
  println("Leds per strip set to : "+theText);
  network.setNumLedsPerStrip(int(theText));
}

public void strips(String theText) {
  println("Strips set to : "+theText);
  network.setNumStrips(int(theText));
}

public void connect() {

  if (network.getMode()!=device.NULL) {
    network.connect(this);
  } else {
    println("Please select a driver type from the dropdown before attempting to connect");
  }

  if (network.getMode()==device.PIXELPUSHER) {
    network.fetchPPConfig();
    cp5.get(Textfield.class, "ip").setValue(network.getIP()).setVisible(true);
    cp5.get(Textfield.class, "leds_per_strip").setValue(str(network.getNumLedsPerStrip())).setVisible(true);
    cp5.get(Textfield.class, "strips").setValue(str(network.getNumStrips())).setVisible(true);
  }

  if (network.isConnected()) {
    cp5.get("connect").setColorBackground(color(0, 255, 0));
    cp5.get("connect").setCaptionLabel("Refresh");
  }
}

public void refresh() {
  String[] cameras = enumerateCams();
  cp5.get(ScrollableList.class, "camera").setItems(cameras);
}


public void cvThreshold(int value) {
  cvThreshold = value;
  //opencv.threshold(cvThreshold);
  //println("set Open CV threshold to "+cvThreshold);
}

public void cvContrast(float value) {
  cvContrast =value;
  //opencv.contrast(cvContrast);
  //println("set Open CV contrast to "+cvContrast);
}

public void ledBrightness(int value) {
  ledBrightness =value;
  animator.setLedBrightness(value);
}

public void frameskip(int value) {
  frameSkip =value;
  animator.setFrameSkip(value);
}

void controlEvent(ControlEvent theControlEvent) {
  if (theControlEvent.isFrom("blobSize")) {
    minBlobSize = int(theControlEvent.getController().getArrayValue(0));
    maxBlobSize = int(theControlEvent.getController().getArrayValue(1));
  }
}

public void calibrate() {
  // Activate Calibration Mode
  if (videoMode != VideoMode.CALIBRATION) {
    videoMode = VideoMode.CALIBRATION; 
    backgroundImage = videoInput.copy();
    backgroundImage.save("data/calibrationBackgroundImage.png");
    if ( patternMapping == true) {
      animator.setMode(AnimationMode.BINARY);
    } else {
      animator.setMode(AnimationMode.CHASE);
    }
  } 
  // Decativate Calibration Mode
  else if (videoMode == VideoMode.CALIBRATION) {
    videoMode = VideoMode.CAMERA;
    backgroundImage = createImage(camWidth, camHeight, RGB);
    opencv.loadImage(backgroundImage); // Clears OpenCV frame
    animator.setMode(AnimationMode.OFF); 
    animator.resetPixels();
  }
}

public void saveLayout() {
  if (leds.size() == 0) { // TODO: review, does this work?
    //User is trying to save without anything to output - bail
    println("No point data to save, run mapping first");
    return;
  } else {
    //savePath = "../LightWork_Scraper/data/layout.csv"; //sketchPath()+
    File sketch = new File("../LightWork_Scraper/data/layout.csv");
    selectOutput("Select a file to write to:", "fileSelected", sketch);
    saveCSV(leds, savePath);
  }
}

// event handler for AWT file selection window
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    savePath = selection.getAbsolutePath();
    println("User selected " + selection.getAbsolutePath());
  }
}

//TODO: investigate "ignoring" error and why this doesn't work, but keypress do
void saveSettings(float v) {
  cp5.saveProperties("default");
}

void stereoToggle(boolean theFlag) {
  if (theFlag==true) {
    stereoMode=false;
    cp5.get(Button.class, "map").setCaptionLabel("map");
    cp5.get(Button.class, "map2").setVisible(false);    
    println("Stereo mode off");
  } else {
    stereoMode=true;
    cp5.get(Button.class, "map").setCaptionLabel("map left");
    cp5.get(Button.class, "map2").setVisible(true);

    println("Stereo mode on");
  }
}

//void videoIn(boolean theFlag) {
//  if (theFlag==true) {
//    videoMode = VideoMode.CAMERA; 
//    println("Video mode: Camera");
//  } else {
//    videoMode = VideoMode.FILE; 
//    println("Video mode: File");
//  }
//}

void mappingToggle(int n) {
  if (n==0) {
    videoMode = VideoMode.IMAGE_SEQUENCE; 
    patternMapping = true;
    println("Mapping Mode: Pattern");
  } else if (n==1) {
    videoMode = VideoMode.CAMERA; 
    patternMapping = false;
    println("Mapping Mode: Sequence");
  }
}

// 
public void map() {
  if (videoMode != VideoMode.IMAGE_SEQUENCE) {
    // Set frameskip so we have enough time to capture an image of each animation frame. 
    videoMode = VideoMode.IMAGE_SEQUENCE;
    animator.setMode(AnimationMode.BINARY);
    //animator.resetPixels();
    backgroundImage = videoInput.copy();
    backgroundImage.save(dataPath("backgroundImage.png"));
    blobLifetime = 200;
    isMapping=true;
  } else {
    videoMode = VideoMode.CAMERA;
    animator.setMode(AnimationMode.OFF);
    animator.resetPixels();
    blobList.clear();
    shouldStartDecoding = false; 
    images.clear();
    currentFrame = 0;
    isMapping = false;
  }
}

public void map2() {
  if (videoMode != VideoMode.IMAGE_SEQUENCE) {
    // Set frameskip so we have enough time to capture an image of each animation frame. 
    videoMode = VideoMode.IMAGE_SEQUENCE;
    animator.setMode(AnimationMode.BINARY);
    //animator.resetPixels();
    backgroundImage = videoInput.copy();
    backgroundImage.save(dataPath("backgroundImage.png"));
    blobLifetime = 200;
    isMapping=true;
  
  } else {
    videoMode = VideoMode.CAMERA;
    animator.setMode(AnimationMode.OFF);
    animator.resetPixels();
    blobList.clear();
    shouldStartDecoding = false; 
    images.clear();
    currentFrame = 0;
    isMapping = false;
  }
}


//////////////////////////////////////////////////////////////
// UI Methods
//////////////////////////////////////////////////////////////

//get the list of currently connected cameras
String[] enumerateCams() {

  String[] list = Capture.list();

  //catch null cases
  if (list == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    //cam = new Capture(this, camWidth, camHeight, FPS);
  } else if (list.length == 0) {
    println("There are no cameras available for capture.");
  }

  //parse out camera names from device listing
  for (int i=0; i<list.length; i++) {
    String item = list[i]; 
    String[] temp = splitTokens(item, ",=");
    list[i] = temp[1];
  }

  //This operation removes duplicates from the camera names, leaving only individual device names
  //the set format automatically removes duplicates without having to iterate through them
  Set<String> set = new HashSet<String>();
  Collections.addAll(set, list);
  String[] cameras = set.toArray(new String[0]);

  return cameras;
}

//UI camera switching - Cam 1
void switchCamera(String name) {
  cam.stop();
  cam=null;
  cam =new Capture(this, camWidth, camHeight, name, 30);
  cam.start();
}


void window2d() {
  //camWindows = 2;
  //println("Setting window size");
  //Window size based on screen dimensions, centered
  //windowSizeX = (int)(displayWidth/3 * 0.8 *camWindows); // max width is 80% of monitor width, with room for 3 cam windows
  //windowSizeY = (int)(displayHeight / 2 + (140)); // adds to height for ui elements

  //surface.setSize(windowSizeX, windowSizeY);
  //surface.setSize(960, 740);
  if(displayDensity()==2){
    surface.setLocation((int)(displayWidth / 2)-width, (int)(displayHeight / 2) - height);
  }
  else{
      surface.setLocation((displayWidth / 2) - width / 2, ((int)displayHeight / 2) - height / 2);
  }

  //camDisplayWidth = (int)(displayWidth/3 * 0.8);
  //camDisplayHeight = (int)(camDisplayWidth/camAspect);
  camDisplayWidth = (int)(width/2);
  camDisplayHeight = (int)(camDisplayWidth/camAspect);

  camArea = new Rectangle(0, 70, camDisplayWidth, camDisplayHeight);

  println("camDisplayWidth: "+camDisplayWidth);
  println("camDisplayHeight: "+camDisplayHeight);
  println("camArea.x: "+ camArea.x +" camArea.y: "+ camArea.y +" camArea.width: "+ camArea.width +" camArea.height: "+ camArea.height);
}