/*       //<>//
 *  Animator
 *  
 *  This Class handles timing and generates the state and color of all connected LEDs
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @authors Leó Stefánsson and Tim Rolls
 */


enum AnimationMode {
  CHASE, TEST, BINARY, OFF
};

public class Animator {

  int                 ledIndex;               // Index of LED being mapped (lit and detected).
  int                 testIndex;              // Used for the test() animation sequence
  int                 frameCounter;           // Internal framecounter
  int                 frameSkip;              // How many frames to skip between updates

  AnimationMode       mode;

  Animator() {
    println("Animator created");
    ledIndex = 0; // Internal counter
    mode = AnimationMode.OFF;
    testIndex = 0;
    frameCounter = 0;
    this.frameSkip = 3;
  }

  //////////////////////////////////////////////////////////////
  // Setters and getters
  //////////////////////////////////////////////////////////////


  void setMode(AnimationMode m) {
    setAllLEDColours(off);
    mode = m;
    ledIndex = 0; // TODO: resetInternalVariables() method?
    testIndex = 0;
    frameCounter = 0;
    //resetPixels();
  }

  AnimationMode getMode() {
    return mode;
  }

  void setLedBrightness(int brightness) { //TODO: set overall brightness?
    ledBrightness = brightness;
  }

  void setFrameSkip(int num) {
    this.frameSkip = num;
  }

  int getFrameSkip() {
    return this.frameSkip;
  }

  int getLedIndex() {
    return ledIndex;
  }

  // Internal method to reassign pixels with a vector of the right length. Gives all pixels a value of (0,0,0) (black/off).
  void resetPixels() {
    println("Animator -> resetPixels()"); 
    network.populateLeds();
    network.update(this.getPixels());
  }

  // Return pixels (to update OPC or PixelPusher) --Changed to array, arraylist wasn't working on return
  color[] getPixels() {
    color[] l = new color[leds.size()];
    for (int i = 0; i<leds.size(); i++) {
      l[i]=leds.get(i).c;
    }
    return l;
  }


  //////////////////////////////////////////////////////////////  
  // Animation Methods 
  //////////////////////////////////////////////////////////////

  void update() { 

    switch(mode) { 
    case CHASE: 
      { 
        chase();
        break;
      }
    case TEST: 
      {
        test();
        break;
      }
    case BINARY: 
      {
        binaryAnimation();
        break;
      }

    case OFF: 
      {
      }
    };

    // Advance the internal counter
    frameCounter++;

    //send pixel data over network
    if (mode!=AnimationMode.OFF && network.isConnected) {
      network.update(this.getPixels());
    }
  }

  // Update the pixels for all the strips
  // This method does not return the pixels, it's up to the users to send animator.pixels to the driver (FadeCandy, PixelPusher).
  void chase() {
    for (int i = 0; i <  leds.size(); i++) {
      color col;
      if (i == ledIndex) {
        col = color(ledBrightness, ledBrightness, ledBrightness);
      } else {
        col = color(0, 0, 0);
      }
      leds.get(i).setColor(col);
    }

    if (frameCounter == 0) return; // Avoid the first LED going off too quickly //<>//
    if (frameCounter%this.frameSkip==0)ledIndex++; // use frameskip to delay animation updates

    // Stop at end of LEDs
    if (ledIndex >= leds.size()) { 
      this.setMode(AnimationMode.OFF);
    } //<>//
  }

  // Set all LEDs to the same colour (useful to turn them all on or off). 
  void setAllLEDColours(color col) { 
    for (int i = 0; i <  leds.size(); i++) {
      leds.get(i).setColor(col);
    }
  }

  //LED pre-flight test. Cycle: White, Red, Green, Blue.
  void test() {
    testIndex++;

    if (testIndex < 30) {
      setAllLEDColours(color(ledBrightness, ledBrightness, ledBrightness));
    } else if (testIndex > 30 && testIndex < 60) {
      setAllLEDColours(color(ledBrightness, 0, 0));
    } else if (testIndex > 60 && testIndex < 90) {
      setAllLEDColours(color(0, ledBrightness, 0));
    } else if (testIndex > 90 && testIndex < 120) {
      setAllLEDColours(color(0, 0, ledBrightness));
    }

    if (testIndex > 120) {
      testIndex = 0;
    }
  }

  void binaryAnimation() {
    if (frameCounter%this.frameSkip==0) {
      for (int i = 0; i <  leds.size(); i++) {
        leds.get(i).binaryPattern.advance();

        switch(leds.get(i).binaryPattern.state) {
        case 0:
          leds.get(i).setColor(color(0, 0, 0));
          break;
        case 1:
          leds.get(i).setColor(color(ledBrightness, ledBrightness, ledBrightness));
          break;
        }
      }
    }
  }
}