void keyPressed() {
  if (key == 's') {
    saveSVG(coords);
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
      //videoExport.startMovie();
      //isRecording = true;
      animator.setMode(animationMode.BINARY);
      println("Binary mode (monochrome)");
    } else {
      //isRecording = false;
      //videoExport.endMovie();
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
      boolean success = loadMovieFile(movieFileName);
      println("VideoMode: FILE " + success);
    }
  }
  // Toggle Movie Recording
  if (key == 'r') {
    if (!isRecording) {
      isRecording = true;
      videoExport.startMovie();
    } else {
      isRecording = false;
      videoExport.endMovie();
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