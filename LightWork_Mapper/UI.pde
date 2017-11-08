// //<>// //<>//
//  UI.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//  
//  This class builds the UI for the application
//
//////////////////////////////////////////////////////////////

import controlP5.*;

//Textarea cp5Console;
//Println console;
boolean isUIReady = false;

void buildUI() {
  println("setting up ControlP5");

  cp5 = new ControlP5(this);
  //topPanel = new ControlP5(this);

  float startTime = millis(); 
  println("Building UI... at time: " + startTime);
  //int uiWidth =500 *guiMultiply;
  int uiGrid = height/12;
  int uiSpacing = 20 *guiMultiply;
  int buttonHeight = 25 *guiMultiply;
  int buttonWidth =200 *guiMultiply;

  println("Creating font...");
  PFont pfont = createFont("OpenSans-Regular.ttf", 12*guiMultiply, false); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont, 12*guiMultiply);
  cp5.setFont(font);
  cp5.setColorBackground(#333333);
  cp5.setPosition((int)((height / 2)*camAspect+uiSpacing), uiSpacing);

  //println("listing drivers");
  List driver = Arrays.asList("PixelPusher", "Fadecandy"); //"ArtNet"  removed for now - throws errors
  /* add a ScrollableList, by default it behaves like a DropdownList */
  println("adding scroallable list for drivers");
  cp5.addScrollableList("driver")
    .setPosition(0, uiGrid)
    .setSize(buttonWidth, 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(driver)
    .setType(ControlP5.DROPDOWN)
    .setOpen(false)
    .bringToFront() 
    //.close();
    ;

  //Refresh connected cameras
  println("cp5: adding refresh button");
  cp5.addButton("refresh")
    .setPosition(buttonWidth+uiSpacing, 0)
    .setSize(buttonWidth/2, buttonHeight)
    ;

  println("adding textfield for IP");
  cp5.addTextfield("ip")
    .setPosition(buttonWidth+uiSpacing, uiGrid)
    .setSize(buttonWidth/2, buttonHeight)
    .setAutoClear(false)
    .setValue(network.getIP())
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)
    //.linebreak()
    //.setGroup("network")
    ;

  println("adding textfield for ledsPerStrip");
  cp5.addTextfield("leds_per_strip")
    .setPosition(buttonWidth+uiSpacing, uiGrid+buttonHeight+uiSpacing)
    .setSize(buttonWidth/2, buttonHeight)
    .setAutoClear(false)
    .setValue(str(network.getNumLedsPerStrip()))
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)
    //.setGroup("network")
    ;

  println("adding textfield for strips");
  cp5.addTextfield("strips")
    .setPosition(buttonWidth+uiSpacing, uiGrid+buttonHeight*2+uiSpacing*2)
    .setSize(buttonWidth/2, buttonHeight)
    .setAutoClear(false)
    .setValue(str(network.getNumStrips()))
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)
    //.setGroup("network")
    ;

  println("adding connect button");
  cp5.addButton("connect")
    .setPosition(buttonWidth*2+uiSpacing*2, uiGrid)
    .setSize(buttonWidth/2-2, int(buttonHeight*1.5))
    ;

  println("adding contrast slider");
  cp5.addSlider("cvContrast")
    .setBroadcast(false)
    .setPosition(0, uiGrid*3)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 5)
    .setValue(cvContrast)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)
    ;

  ////set labels to bottom
  //cp5.getController("cvContrast").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("cvContrast").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for cvThreshold");
  cp5.addSlider("cvThreshold")
    .setBroadcast(false)
    .setPosition(0, uiGrid*3+buttonHeight+uiSpacing)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 100)
    .setValue(cvThreshold)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)

    ;

  ////set labels to bottom
  //cp5.getController("cvThreshold").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("cvThreshold").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for ledBrightness");
  cp5.addSlider("ledBrightness")
    .setBroadcast(false)
    .setPosition(0, uiGrid*3+buttonHeight*2+uiSpacing*2)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 255)
    .setValue(ledBrightness)
    .setBroadcast(true)
    .getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, CENTER).setPadding(5*guiMultiply, 5*guiMultiply)

    ;

  ////set labels to bottom
  //cp5.getController("ledBrightness").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  //cp5.getController("ledBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding test button");
  cp5.addButton("test")
    .setPosition(0, uiGrid*5)
    .setSize(buttonWidth/2-2, int(buttonHeight*1.5))
    ;

  println("adding map button"); 
  cp5.addButton("map")
    .setPosition(buttonWidth/2, uiGrid*5)
    .setSize(buttonWidth/2-2, int(buttonHeight*1.5))
    ;

  println("adding save button");
  cp5.addButton("save")
    .setPosition(buttonWidth+uiSpacing, uiGrid*5)
    .setSize(buttonWidth/2, int(buttonHeight*1.5))
    ;


  //capture console events to ui
  //println("enabling shortcuts");
  //cp5.enableShortcuts();
  //cp5Console = cp5.addTextarea("cp5Console")
  //  .setPosition(0, height-(buttonHeight*5)-uiSpacing*2)
  //  .setSize(buttonWidth, buttonHeight*5)
  //  .setFont(createFont("", 12*guiMultiply))
  //  .setLineHeight(16*guiMultiply)
  //  .setColor(color(200))
  //  .setColorBackground(color(#333333))
  //  .setColorForeground(color(255, 100))
  //  ;
  //;

  //println("adding console");
  // TODO: IS this breaking things?
  //console = cp5.addConsole(cp5Console);//


  ////TOP PANEL
  //println("creating top panel");
  //topPanel.setFont(font);
  //topPanel.setColorBackground(#333333);
  //topPanel.setPosition(uiSpacing, uiSpacing);


  //println("add framerate panel");
  //cp5.addFrameRate().setPosition(0, height-(buttonHeight+uiSpacing));


  // made last - enumerating cams will break the ui if done earlier in the sequence
  println("cp5: adding camera dropdown list");
  cp5.addScrollableList("camera")
    .setPosition(0, 0)
    .setSize(buttonWidth, 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(enumerateCams())
    .setOpen(false)
    //.getCaptionLabel().align(CENTER, CENTER) 
    //.close();
    ;

  // Wrap up, report done
  float deltaTime = millis()-startTime; 
  println("Done building GUI, total time: " + deltaTime + " ms"); 
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
    network.shutdown();
    network.setMode(device.PIXELPUSHER);
    println("network: PixelPusher");
  }
  if (label.equals("FADECANDY")) {
    network.shutdown();
    network.setMode(device.FADECANDY);
    println("network: Fadecandy");
  }
  if (label.equals("ARTNET")) {
    network.shutdown();
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
    cp5.get(Textfield.class, "ip").setValue(network.getIP());
    cp5.get(Textfield.class, "leds_per_strip").setValue(str(network.getNumLedsPerStrip()));
    cp5.get(Textfield.class, "strips").setValue(str(network.getNumStrips()));
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
  animator.setLedBrightness(ledBrightness);
}

public void test() {
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

public void map() {
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

public void save() {
  if (key == 's') {
    saveSVG(coords);
  }
}



//////////////////////////////////////////////////////////////
// Camera Switching
//////////////////////////////////////////////////////////////

//get the list of currently connected cameras
String[] enumerateCams() {

  //} else {
  //  println("Available cameras:");
  //  printArray(cameras);
  //  //cam = new Capture(this, camWidth, camHeight, 30);
  //  //cam = new Capture(this, cameras[0]);
  //  cam = new Capture(this, camWidth, camHeight, cameras[0], FPS);
  //  cam.start();
  //}

  //int startTime = millis();
  //parse out camera names
  String[] list = Capture.list();
  //int endTime =millis();
  //println("listing cams took: "+(startTime-endTime));

  //catch null cases
  //if (cameras == null) {
  //  println("Failed to retrieve the list of available cameras, will try the default...");
  //  cam = new Capture(this, camWidth, camHeight, FPS);
  //} else if (cameras.length == 0) {
  //  println("There are no cameras available for capture.");
  //  exit();

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

//UI camera switching
void switchCamera(String name) {
  cam.stop();
  cam=null;
  cam =new Capture(this, camWidth, camHeight, name, 30);
  cam.start();
}