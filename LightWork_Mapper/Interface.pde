// //<>// //<>// //<>//
//  Interface.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//  
//  This class handles connecting to and switching between PixelPusher, FadeCandy and ArtNet devices.
//
//////////////////////////////////////////////////////////////


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
  String               IP = "fade1.local";
  int                  port = 7890;
  int                  ledsPerStrip =50;
  int                  numStrips = 3;
  int                  numLeds = ledsPerStrip*numStrips;

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
    //ofLogNotice("animator") << "setNumLedsPerStrip(): " << num;
    ledsPerStrip = num;

    // Update OPC client
    //opcClient->setLedsPerStrip(numLedsPerStrip);

    // Reset LEDs vector
    //resetPixels();
  }

  int getNumLedsPerStrip() {
    return ledsPerStrip;
  }

  void setNumStrips(int num) {
    //ofLogNotice("animator") << "setNumStrips(): " << num;
    numStrips = num;
    //resetPixels();
  }

  int getNumStrips() {
    return numStrips;
  }

  void setIP(String ip) {
    IP=ip;
  }

  String getIP() {
    return IP;
  }

  boolean isConnected() {
    return isConnected;
  }

  // Reset the LED vector
  void populateLeds() {

    //int bPatOffset = 150; // Offset to get more meaningful patterns (and avoid 000000000);

    if (leds.size()>0) {
      leds.clear();
    }

    for (int i = 0; i < numLeds; i++) {
      LED temp= new LED();
      leds.add(temp);
      leds.get(i).setAddress(i);
      //leds[i].binaryPattern.generatePattern(i+bPatOffset); // Generate a unique binary pattern for each LED
    }
  }

  //////////////////////////////////////////////////////////////
  // Network Methods
  //////////////////////////////////////////////////////////////

  void update(color[] colors) {
    switch(mode) {
    case FADECANDY: 
      {
        if (opc.isConnected()) {
          opc.autoWriteData(colors);
        }
        break;
      }
    case PIXELPUSHER: 
      {

        if (testObserver.hasStrips) {
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


  //open connection to controller
  void connect(PApplet parent) {
    //if (isConnected) {
    //  shutdown();
    //}

    if (mode == device.FADECANDY) {
      if (opc== null) {
        opc = new OPC(parent, IP, port);
        //delayThread(3000);
        int startTime = millis();
        while (!opc.isConnected) {
          println("waiting...");
          int currentTime = millis(); 
          int deltaTime = currentTime - startTime;
          if (deltaTime > 5000) {
            println("connection failed, check your connections..."); 
            isConnected = false; 
            break;
          }
        }
      }

      if (opc.isConnected()) {
        println("Connected to Fadecandy OPC server at: "+IP+":"+port); 
        isConnected =true;
        opc.setPixelCount(numLeds);
      }
      populateLeds();
    }

    if (mode == device.PIXELPUSHER ) {
      // does not like being instantiated a second time
      if (registry == null) {
        registry = new DeviceRegistry();
        testObserver = new TestObserver();
      }

      registry.addObserver(testObserver);
      registry.setAntiLog(true);


      delayThread(3000);

      if (testObserver.hasStrips) {
        isConnected =true;
      }

      //Set number of strips and pixels based on pusher config - only pulling for one right now.
      List<PixelPusher> pps = registry.getPushers();
      for (PixelPusher pp : pps) {
        numStrips = pp.getNumberOfStrips();
        ledsPerStrip = pp.getPixelsPerStrip();
      }

      registry.setLogging(false);
      populateLeds();
    }
  }

  //Close existing connections
  void shutdown() {
    if (mode == device.FADECANDY) {
      //opc.dispose();
      opc = null;
    }
    if (mode==device.PIXELPUSHER) {
      //registry.stopPushing() ;  //TODO: Need to disconnect devices as well
      registry.deleteObserver(testObserver);
      //registry = null;
      //testObserver = null;
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