/*  //<>//
 *  LED
 *  
 *  This class handles connecting to and switching between PixelPusher, FadeCandy and ArtNet devices.
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @authors Leó Stefánsson and Tim Rolls
 */


//Pixel Pusher library imports
import com.heroicrobot.controlsynthesis.*;
import com.heroicrobot.dropbit.common.*;
import com.heroicrobot.dropbit.devices.*;
import com.heroicrobot.dropbit.devices.pixelpusher.*;
import com.heroicrobot.dropbit.discovery.*;
import com.heroicrobot.dropbit.registry.*;
import java.util.*;
import java.io.*;

enum device {
  FADECANDY, PIXELPUSHER, ARTNET, NULL
};

public class Interface {

  device              mode;

  //LED defaults
  String               IP = "fade2.local";
  int                  port = 7890;
  int                  ledsPerStrip = 64; // TODO: DOn't hardcode this
  int                  numStrips = 8;
  int                  numLeds = ledsPerStrip*numStrips;
  int                  ledBrightness;

  //Pixelpusher objects
  DeviceRegistry registry;
  TestObserver testObserver;

  //Fadecandy Objects
  OPC opc;

  boolean isConnected =false;

  //////////////////////////////////////////////////////////////
  //Constructor
  /////////////////////////////////////////////////////////////

  Interface() {
    mode = device.NULL;
    populateLeds();
    println("Interface created");
  }

  //////////////////////////////////////////////////////////////
  // Setters and getters
  //////////////////////////////////////////////////////////////

  void setMode(device m) {
    shutdown();
    mode = m;
  }

  device getMode() {
    return mode;
  }

  void setNumLedsPerStrip(int num) {
    ledsPerStrip = num;
    numLeds = ledsPerStrip*numStrips;
    populateLeds();
  }

  int getNumLedsPerStrip() {
    return ledsPerStrip;
  }

  void setNumStrips(int num) {
    numStrips = num;
    numLeds = ledsPerStrip*numStrips;
    populateLeds();
  }

  int getNumStrips() {
    return numStrips;
  }

  void setLedBrightness(int brightness) { //TODO: set overall brightness?
    ledBrightness = brightness;

    if (mode == device.PIXELPUSHER && isConnected()) {
      registry.setOverallBrightnessScale(ledBrightness);
    }

    if (opc!=null&&opc.isConnected()) {
    }
  }

  void setIP(String ip) {
    IP=ip;
  }

  String getIP() {
    println(IP);
    return IP;
  }

  void setInterpolation(boolean state) {
    if (mode == device.FADECANDY) {
      opc.setInterpolation(state);
    } else {
      println("Interpolation only supported for FADECANDY.");
    }
  }

  void setDithering(boolean state) {
    if (mode == device.FADECANDY) {
      opc.setDithering(state); 
      opc.setInterpolation(state);
    } else {
      println("Dithering only supported for FADECANDY.");
    }
  }

  boolean isConnected() {
    return isConnected;
  }

  //Set number of strips and pixels based on pusher config - only pulling for one right now.
  void fetchPPConfig() {
    if (mode == device.PIXELPUSHER && isConnected()) {
      List<PixelPusher> pps = registry.getPushers();
      for (PixelPusher pp : pps) {
        IP = pp.getIp().toString();
        numStrips = pp.getNumberOfStrips();
        ledsPerStrip = pp.getPixelsPerStrip();
      }
    }
  }

  // Reset the LED vector
  void populateLeds() {
    // Clear existing LEDs
    if (leds.size()>0) {
      println("Clearing LED Array"); 
      leds.clear();
      println("Turning off physical LEDs"); 
      network.clearLeds();
    }

    // Create new LEDS
    println("Creating LED Array"); 
    for (int i = 0; i < numLeds; i++) {
      LED temp= new LED();
      leds.add(temp);
      leds.get(i).setAddress(i);
    }
  }

  //////////////////////////////////////////////////////////////
  // Network Methods
  //////////////////////////////////////////////////////////////

  void update(color[] colors) {

    switch(mode) {
    case FADECANDY: 
      {
        //check if opc object exists and is connected before writing data
        if (opc!=null&&opc.isConnected()) {
          opc.autoWriteData(colors);
        }
        break;
      }
    case PIXELPUSHER: 
      {
        //check if network observer exists and has discovered strips before writing data
        if (testObserver!=null&&testObserver.hasStrips) {
          registry.startPushing();

          //iterate through PP strip objects to set LED colors
          List<Strip> strips = registry.getStrips();
          if (strips.size() > 0) {
            int stripNum =0;
            for (Strip strip : strips) {
              for (int stripPos = 0; stripPos < strip.getLength(); stripPos++) {
                color c = colors[(ledsPerStrip*stripNum)+stripPos];

                strip.setPixel(c, stripPos);
              }
              stripNum++;
            }
          }
        }

        break;
      }

    case ARTNET:
      {
      }

    case NULL: 
      {
      }
    };
  }

  void clearLeds() {
    color[] col = new color[numLeds]; 
    for (color c : col) {
      c = color(0);
    }
    update(col); // Update Physical LEDs with black (off)
  }

  //open connection to controller
  void connect(PApplet parent) {
    if (isConnected) {
      shutdown();
    }

    if (mode == device.FADECANDY) {
      if (opc== null || !opc.isConnected) {
        opc = new OPC(parent, IP, port);
        int startTime = millis();

        print("waiting");
        while (!opc.isConnected()) {
          int currentTime = millis(); 
          int deltaTime = currentTime - startTime;
          if ((deltaTime%1000)==0) {
            print(".");
          }
          if (deltaTime > 5000) {
            println(" ");
            println("connection failed, check your connections..."); 
            isConnected = false;
            network.shutdown();
            break;
          }
        }
        println(" ");
      }

      if (opc.isConnected()) {
        // TODO: Find a more elegant way to initialize dithering
        // Currently this is the only safe place where this is guaranteed to work
        //opc.setDithering(false);
        //opc.setInterpolation(false);
        // TODO: Deal with this (doesn't work for FUTURE wall, works fine one LIGHT WORK wall).

        // Clear LEDs
        animator.setAllLEDColours(off);
        // Update pixels twice (elegant, I know... but it works)
        update(animator.getPixels());
        //update(animator.getPixels());
        println("Connected to Fadecandy OPC server at: "+IP+":"+port); 
        isConnected =true;
        opc.setPixelCount(numLeds);
        populateLeds();
      }
    }

    if (mode == device.PIXELPUSHER ) {
      // does not like being instantiated a second time
      if (registry == null) {
        registry = new DeviceRegistry();
        testObserver = new TestObserver();
      }

      registry.addObserver(testObserver);
      registry.setAntiLog(true);
      registry.setLogging(false);

      int startTime = millis();

      print("waiting");
      while (!testObserver.hasStrips) {
        int currentTime = millis(); 
        int deltaTime = currentTime - startTime;
        if ((deltaTime%1000)==0) {
          print(".");
        }
        if (deltaTime > 5000) {
          println(" ");
          println("connection failed, check your connections..."); 
          isConnected = false; 
          break;
        }
      }
      println(" ");

      fetchPPConfig();

      if (testObserver.hasStrips) {
        isConnected =true;

        // Clear LEDs
        animator.setAllLEDColours(off);
        update(animator.getPixels());
      }

      registry.setLogging(false);
      populateLeds();
    }
  }

  //Close existing connections
  void shutdown() {
    if (mode == device.FADECANDY && opc!=null) {
      opc.dispose();
      isConnected = false;
      //opc = null;
    }
    if (mode==device.PIXELPUSHER && registry!=null) {
      registry.stopPushing() ;  //TODO: Need to disconnect devices as well
      registry.deleteObserver(testObserver);
      isConnected = false;
    }
    if (mode==device.ARTNET) {
    }
    if (mode==device.NULL) {
    }
  }


  //toggle verbose logging for PixelPusher
  void pusherLogging(boolean b) {
    registry.setLogging(b);
  }
}

// PixelPusher Observer
// Monitors network for changes in PixelPusher configuration

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    println("Registry changed!");
    if (updatedDevice != null) {
      println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
}

void delayThread(int ms)
{
  try
  {    
    Thread.sleep(ms);
  }
  catch(Exception e) {
  }
}