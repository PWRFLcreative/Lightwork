void keyPressed() {
  if (key == 's') {
    if (leds.size() == 0) { // TODO: Review this
      //User is trying to save without anything to output - bail
      println("No point data to save, run mapping first");
      return;
    } else {
      File sketch = new File(sketchPath());
      selectOutput("Select a file to write to:", "fileSelected", sketch);
      saveCSV(leds, savePath);
    }
  }

  if (key == 'm') {
     if (network.isConnected()==false) {
     println("please connect to a device before mapping");
     } else if (animator.getMode()!=AnimationMode.CHASE) {
     animator.setMode(AnimationMode.CHASE);
     
     println("Chase mode");
     } else {
     animator.setMode(AnimationMode.OFF);
     println("Animator off");
     }
    isMapping = !isMapping;
  }
  // Capture Image sequence
  // When we are done capturing an image sequence, switch to videoMode = VideoMode.IMAGE_SEQUENCE
  if (key == 'i') {
    // Set frameskip so we have enough time to capture an image of each animation frame. 
    videoMode = VideoMode.IMAGE_SEQUENCE;
    animator.frameSkip = 30;
    animator.setMode(AnimationMode.BINARY);
    network.update(animator.getPixels());
    videoInput.save("Capture/captureBackground.png");
    backgroundImage = videoInput.copy();
    //backgroundImage.save("yup_it_worked.png");
  }
  // (K)Calibration Mode
  if (key == 'k') {
    videoMode = VideoMode.CALIBRATION; 
    backgroundImage = videoInput.copy();
    animator.setMode(AnimationMode.BINARY);
  }
  // print led info
  if (key == 'l') {

    // Save to the Scraper project
    String savePath = "../LightWork_Scraper/data/binary_layout.csv";
    saveCSV(leds, savePath); 
  }
  if (key == 't') {
    if (network.isConnected()==false) {
      println("please connect to a device before testing");
    } else if (animator.getMode()!=AnimationMode.TEST) {
      animator.setMode(AnimationMode.TEST);
      println("Test mode");
    } else {
      animator.setMode(AnimationMode.OFF);
      println("Animator off");
    }
  }

  if (key == 'b') {
    if (animator.getMode()!=AnimationMode.BINARY) {
      animator.setMode(AnimationMode.BINARY);
      println("Binary mode (monochrome)");
    } else {
      animator.setMode(AnimationMode.OFF);
      println("Animator off");
    }
  }

  // Test connecting to OPC server
  if (key == 'o') {
    network.setMode(device.FADECANDY);
    network.connect(this);
  }

  // Test connecting to PP 
  if (key == 'p') {
    network.setMode(device.PIXELPUSHER);
    network.connect(this);
  }

  // All LEDs Black (clear)
  if (key == 'c') {
    for (int i = 0; i < leds.size(); i++) {
      leds.get(i).coord.set(0, 0); 
    }
    
  }

  // All LEDs White (clear)
  if (key == 'w') {
    if (network.isConnected()) {
      animator.setAllLEDColours(on);
      animator.update();
    }
  }

  //check led coords
  if (key == 'l') {
    for (LED led : leds) {
      println(led.coord);
    }
  }
}