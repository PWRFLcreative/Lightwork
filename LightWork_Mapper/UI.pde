// //<>// //<>// //<>//
//  UI.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//  
//  This class builds the UI for the application
//
//////////////////////////////////////////////////////////////

import controlP5.*;

Textarea cp5Console;
Println console;
boolean isUIReady = false;

void buildUI() {
  println("setting up ControlP5");
  cp5 = new ControlP5(this);
  topPanel = new ControlP5(this);
  
  float startTime = millis(); 
  println("Building UI... at time: " + startTime);
  int uiWidth =500 *guiMultiply;
  int uiSpacing = 20 *guiMultiply;
  int buttonHeight = 25 *guiMultiply;
  int buttonWidth =230 *guiMultiply;

  println("Creating font...");
  PFont pfont = createFont("OpenSans-Regular.ttf", 12*guiMultiply, true); // use true/false for smooth/no-smooth
  ControlFont font = new ControlFont(pfont, 12*guiMultiply);
  cp5.setFont(font);
  cp5.setColorBackground(#333333);
  cp5.setPosition((int)((height / 2)*camAspect+uiSpacing), uiSpacing);



  //println("listing drivers");
  List driver = Arrays.asList("PixelPusher", "Fadecandy"); //"ArtNet"  removed for now - throws errors
  /* add a ScrollableList, by default it behaves like a DropdownList */
  println("adding scroallable list for drivers");
  cp5.addScrollableList("driver")
    .setPosition(0, 0)
    .setSize(buttonWidth, 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(driver)
    .setType(ControlP5.DROPDOWN)
    .setOpen(false)
    .bringToFront() 
    //.close();
    ;


  println("adding textfield for IP");
  cp5.addTextfield("ip")
    .setPosition(0, 350)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setValue(network.getIP())
    //.setGroup("network")
    ;
   println("done adding textfield for IP");

  println("adding textfield for ledsPerStrip");
  cp5.addTextfield("leds_per_strip")
    .setPosition(0, 450)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setValue(str(network.getNumLedsPerStrip()))
    //.setGroup("network")
    ;

  println("adding textfield for strips");
  cp5.addTextfield("strips")
    .setPosition(0, 550)
    .setSize(buttonWidth, buttonHeight)
    .setAutoClear(false)
    .setValue(str(network.getNumStrips()))
    //.setGroup("network")
    ;

  println("adding connect button");
  cp5.addButton("connect")
    .setPosition(0, 650)
    .setSize(buttonWidth/2-2, int(buttonHeight*1.5))
    ;

  println("adding contrast slider");
  cp5.addSlider("cvContrast")
    .setBroadcast(false)
    .setPosition(0, height/6)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 5)
    .setValue(cvContrast)
    .setBroadcast(true)

    ;

  //set labels to bottom
  println("setting labels to bottom");
  cp5.getController("cvContrast").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  cp5.getController("cvContrast").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for cvThreshold");
  cp5.addSlider("cvThreshold")
    .setBroadcast(false)
    .setPosition(0, height/6 + buttonHeight*2)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 100)
    .setValue(cvThreshold)
    .setBroadcast(true)
    ;

  //set labels to bottom
  println("set labels to bottom (threshold)");
  cp5.getController("cvThreshold").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  cp5.getController("cvThreshold").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding slider for ledBrightness");
  cp5.addSlider("ledBrightness")
    .setBroadcast(false)
    .setPosition(0, height/6 + buttonHeight*4)
    .setSize(buttonWidth, buttonHeight)
    .setRange(0, 255)
    .setValue(ledBrightness)
    .setBroadcast(true)
    ;

  //set labels to bottom
  println("setting label to bottom (ledBrightness)");
  cp5.getController("ledBrightness").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);
  cp5.getController("ledBrightness").getCaptionLabel().align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0);

  println("adding test button");
  cp5.addButton("test")
    .setPosition(0, height/6 + buttonHeight*6)
    .setSize(buttonWidth/2-2, int(buttonHeight*1.5))
    ;

  println("adding map button"); 
  cp5.addButton("map")
    .setPosition(buttonWidth/2+10, height/6 + buttonHeight*6)
    .setSize(buttonWidth/2, int(buttonHeight*1.5))
    ;

  println("adding save button");
  cp5.addButton("save")
    .setPosition(0, height/6 + buttonHeight*10)
    .setSize(buttonWidth/2, int(buttonHeight*1.5))
    ;


  //capture console events to ui
  println("enabling shortcuts");
  cp5.enableShortcuts();
  cp5Console = cp5.addTextarea("cp5Console")
    .setPosition(0, height-(buttonHeight*5)-uiSpacing*2)
    .setSize(buttonWidth, buttonHeight*5)
    .setFont(createFont("", 12*guiMultiply))
    .setLineHeight(16*guiMultiply)
    .setColor(color(200))
    .setColorBackground(color(#333333))
    .setColorForeground(color(255, 100))
    ;
  ;
  
  println("adding console");
  // TODO: IS this breaking things?
  console = cp5.addConsole(cp5Console);//


// TOP PANEL
  println("creating top panel");
  topPanel.setFont(font);
  topPanel.setColorBackground(#333333);
  topPanel.setPosition(uiSpacing, uiSpacing);


  /* add a ScrollableList, by default it behaves like a DropdownList */
  println("topPanel: adding scrollable list");
  topPanel.addScrollableList("camera")
    .setPosition(0, 0)
    .setSize(buttonWidth, 300)
    .setBarHeight(buttonHeight)
    .setItemHeight(buttonHeight)
    .addItems(enumerateCams())
    .setOpen(false)    
    //.close();
    ;
  println("topPanel: adding refresh button");
  topPanel.addButton("refresh")
    .setPosition(buttonWidth+50, 0)
    .setSize(buttonWidth/2, buttonHeight)
    ;

  println("add framerate panel");
  topPanel.addFrameRate().setPosition(0, height-(buttonHeight+uiSpacing));
  
  // Wrap up, report done
  float deltaTime = millis()-startTime; 
  println("Done building GUI, total time: " + deltaTime); 
  isUIReady = true;
}

//////////////////////////////////////////////////////////////
// Event Handlers
//////////////////////////////////////////////////////////////

void camera(int n) {
  Map m = topPanel.get(ScrollableList.class, "camera").getItem(n);
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
  topPanel.get(ScrollableList.class, "camera").setItems(cameras);
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
  //parse out camera names
  String[] list = Capture.list();
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