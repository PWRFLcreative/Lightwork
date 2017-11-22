void keyPressed() {
  if (key == 's') {
      if (coords.size() == 0) {
    //User is trying to save without anything to output - bail
    println("No point data to save, run mapping first");
    return;
  } else {
    File sketch = new File(sketchPath());
    selectOutput("Select a file to write to:", "fileSelected", sketch);
    saveSVG(coords);
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
}