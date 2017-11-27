void keyPressed() {
  if (key == 's') {
    if (coords.size() == 0) {
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
    /* Sorry Tim, this keeps breaking Binary Mapping
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
     */
    isMapping = !isMapping;
  }
  // Capture Image sequence
  // When we are done capturing an image sequence, switch to videoMode = VideoMode.IMAGE_SEQUENCE
  if (key == 'i') {
    // Set frameskip so we have enough time to capture an image of each animation frame. 
    videoMode = VideoMode.IMAGE_SEQUENCE;
    animator.frameSkip = 30;
    animator.setMode(animationMode.BINARY);
    network.update(animator.getPixels());
    videoInput.save("Capture/captureBackground.png");
    backgroundImage = videoInput.copy();
    //backgroundImage.save("yup_it_worked.png");
  }
  // print led info
  if (key == 'l') {
    PrintWriter output;
    output = createWriter("binary_layout.csv"); 
    
    //write vals out to file, start with csv header
    output.println("address"+","+"x"+","+"y"+","+"z");
    
    println("CSV saved");
    for (int i = 0; i < leds.size(); i++) {
      output.println(leds.get(i).address+","+leds.get(i).coord.x+","+leds.get(i).coord.y+","+leds.get(i).coord.z);
      println(leds.get(i).address+" "+leds.get(i).coord.x+" "+leds.get(i).coord.y);
    }
    output.close(); // Finishes the file
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
      animator.setMode(animationMode.BINARY);
      println("Binary mode (monochrome)");
    } else {
      animator.setMode(animationMode.OFF);
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
    coords.clear();
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
    for (LED temp : leds) {
      println(temp.coord);
    }
  }
}