/* //<>//
 *  Interface
 *  
 *  This class handles connecting to and switching between PixelPusher, FadeCandy, ArtNet and sACN devices.
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

// ArtNet
import artnetP5.*;

//sACN
import eDMX.*;

//OSC 
import oscP5.*;
import netP5.*;

enum device {
  FADECANDY, PIXELPUSHER, ARTNET, SACN, NULL
};

public class Interface {

  device               mode;

  //LED defaults
  String               IP = "fade2.local";
  int                  port = 7890;
  int                  ledsPerStrip = 64; 
  int                  numStrips = 8;
  int                  numLeds = ledsPerStrip*numStrips;
  int                  ledBrightness;

  byte                 artnetPacket[];
  int                  numArtnetChannels = 3; // Channels per ArtNet fixture
  int                  numArtnetFixtures = 16; // Number of ArtNet DMX fixtures (each one can have multiple channels and LEDs)
  int                  numArtnetUniverses = 1; // Currently only one universe is supported

  boolean              isConnected =false;
  boolean              scraperActive = true;

  // Pixelpusher objects
  DeviceRegistry registry;
  TestObserver testObserver;

  // Fadecandy Objects
  OPC opc;

  // ArtNet objects
  ArtnetP5 artnet;

  //sACN objects
  sACNSource source;
  sACNUniverse universe1;

  //OSC objects
  OscP5 oscP5;
  NetAddress myRemoteLocation;

  //////////////////////////////////////////////////////////////
  // Constructors
  /////////////////////////////////////////////////////////////

  //blank constructor to allow GUI setup
  Interface() {
    mode = device.NULL;
    populateLeds();
    setupOSC();
    println("Interface created");
  }

  //TODO: additional constructors to set variables more clearly

  // setup for Fadecandy
  Interface(device m, String ip, int strips, int leds) {
    mode = m;
    IP = ip;
    numStrips = strips;
    ledsPerStrip = leds;
    numLeds = ledsPerStrip*numStrips;
    populateLeds();
    println("Fadecandy Interface created");
  }

  // Setup for PixelPusher(no address required)
  Interface(device m, int strips, int leds) {
    mode = m;
    if (mode == device.PIXELPUSHER) {
      numStrips = strips;
      ledsPerStrip = leds;
      numLeds = ledsPerStrip*numStrips;
    }

    populateLeds();
    println("PixelPusher Interface created");
  }

  // Setup ArtNet / sACN (uses network discovery/multicast so no ip required)
  Interface(device m, int universes, int numFixtures, int numChans) {
    mode = m;
    if (mode == device.ARTNET || mode == device.SACN) {
      numArtnetFixtures = numFixtures; 
      numArtnetChannels = numChans; // Number of channels per fixture
      numArtnetUniverses = universes; // TODO: support more than one universe
    }

    populateLeds();
    println("ArtNet/sACN Interface created");
  }


  //////////////////////////////////////////////////////////////
  // Setters / getters and utility methods
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

  int getNumArtnetFixtures() {
    return numArtnetFixtures;
  }

  void setNumArtnetFixtures(int numFixtures) {
    numArtnetFixtures = numFixtures; 
    populateLeds();
  }

  int getNumArtnetChannels() {
    return numArtnetChannels;
  }

  void setNumArtnetChannels(int numChannels) {
    numArtnetChannels = numChannels;
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

  // Set number of strips and pixels based on pusher config - only pulling for one right now.
  void fetchPPConfig() {
    if (mode == device.PIXELPUSHER && isConnected()) {
      List<PixelPusher> pps = registry.getPushers();
      for (PixelPusher pp : pps) {
        IP = pp.getIp().toString();
        numStrips = pp.getNumberOfStrips();
        ledsPerStrip = pp.getPixelsPerStrip();
        numLeds = numStrips*ledsPerStrip;
      }
    }
  }

  // Reset the LED vector
  void populateLeds() {
    int val  = 0; 

    // Deal with ArtNet vs. LED structure
    if (mode == device.ARTNET || mode == device.SACN) {
      val = getNumArtnetFixtures();
    } else {
      val = numLeds;
    }

    // Clear existing LEDs
    if (leds.size()>0) {
      println("Clearing LED Array"); 
      leds.clear();
      println("Turning off physical LEDs"); 
      network.clearLeds();
    }

    // Create new LEDS
    println("Creating LED Array"); 
    for (int i = 0; i < val; i++) {
      LED temp = new LED();
      leds.add(temp);
      leds.get(i).setAddress(i);
    }

    numLeds = leds.size();
  }

  //set up OSC here to make constructors cleaner
  void setupOSC() {
    oscP5 = new OscP5(this, 12000);
    myRemoteLocation = new NetAddress("127.0.0.1", 12000);
    //oscP5.plug(this, "toggleScraper", "/toggleScraper");
    //oscP5.plug(this, "newFile", "/newFile");
  }

  //////////////////////////////////////////////////////////////
  // Network Methods
  //////////////////////////////////////////////////////////////

  void update(color[] colors) {

    switch(mode) {
    case FADECANDY: 
      {
        // Check if OPC object exists and is connected before writing data
        if (opc!=null&&opc.isConnected()) {
          opc.autoWriteData(colors);
        }
        break;
      }
    case PIXELPUSHER: 
      {
        // Check if network observer exists and has discovered strips before writing data
        if (testObserver!=null&&testObserver.hasStrips) {
          registry.startPushing();

          // Iterate through PixelPusher strip objects to set LED colors
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
        // Grab all the colors
        for (int i = 0; i < colors.length; i++) {
          // Extract RGB values
          // We assume the first three channels are RGB, and the rest is WHITE.
          int r = (colors[i] >> 16) & 0xFF;  // Faster way of getting red(argb)
          int g = (colors[i] >> 8) & 0xFF;   // Faster way of getting green(argb)
          int b = colors[i] & 0xFF;          // Faster way of getting blue(argb)

          // Write RGB values to the packet
          int index = i*numArtnetChannels; 
          artnetPacket[index]   = byte(r); // Red
          artnetPacket[index+1] = byte(g); // Green
          artnetPacket[index+2] = byte(b); // Blue

          // Populate remaining channels (presumably W) with color brightness
          for (int j = 3; j < numArtnetChannels; j++) {
            int br = int(brightness(colors[i]));
            artnetPacket[index+j] = byte(br); // White
          }
        }

        artnet.broadcast(artnetPacket);
      }

    case SACN:
      {
        // Grab all the colors
        for (int i = 0; i < colors.length; i++) {
          // Extract RGB values
          // We assume the first three channels are RGB, and the rest is WHITE.
          int r = (colors[i] >> 16) & 0xFF;  // Faster way of getting red(argb)
          int g = (colors[i] >> 8) & 0xFF;   // Faster way of getting green(argb)
          int b = colors[i] & 0xFF;          // Faster way of getting blue(argb)

          // Write RGB values to the packet
          int index = i*numArtnetChannels; 
          artnetPacket[index]   = byte(r); // Red
          artnetPacket[index+1] = byte(g); // Green
          artnetPacket[index+2] = byte(b); // Blue

          // Populate remaining channels (presumably W) with color brightness
          for (int j = 3; j < numArtnetChannels; j++) {
            int br = int(brightness(colors[i]));
            artnetPacket[index+j] = byte(br); // White
          }
        }

        //slots can add channel offset to the beginning of the packet
        universe1.setSlots(0, artnetPacket);

        try {
          universe1.sendData();
        } 
        catch (Exception e) {
          e.printStackTrace();
          exit();
        }
      }

    case NULL: 
      {
      }
    };
  }

  void clearLeds() {
    int valCount = 0; 

    // Deal with ArtNet vs. LED addresses
    if (mode == device.ARTNET || mode == device.SACN) {
      valCount = numArtnetFixtures;
    } else {
      valCount = numLeds;
    }
    color[] col = new color[valCount]; 
    for (color c : col) {
      c = color(0);
    }

    if (isConnected) {
      update(col); // Update Physical LEDs with black (off)
    }
  }


  // Open Connection to Controller
  void connect(PApplet parent) {
    populateLeds(); //rebuild LED vector - helps avoid out of bounds errors

    if (isConnected) {
      shutdown();
    } else if (mode == device.FADECANDY) {
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
        // TODO: Deal with this (doesn't work for FUTURE wall, works fine on LIGHT WORK wall).

        // Clear LEDs
        animator.setAllLEDColours(off);
        // Update pixels twice (elegant, I know... but it works)
        update(animator.getPixels());
        println("Connected to Fadecandy OPC server at: "+IP+":"+port); 
        isConnected =true;
        opc.setPixelCount(numLeds);
        populateLeds();
      }
    } else if (mode == device.PIXELPUSHER ) {
      // Does not like being instantiated a second time
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
    } else if (mode == device.ARTNET) {
      artnet = new ArtnetP5();
      isConnected = true; 
      artnetPacket = new byte[numArtnetChannels*numArtnetFixtures]; // Reusing numLeds to indicate the number of fixtures (even though
    } else if (mode == device.SACN) {
      source = new sACNSource(parent, "LightWork");
      universe1 = new sACNUniverse(source, (short)1); // Just one universe for now
      isConnected = true; 
      artnetPacket = new byte[numArtnetChannels*numArtnetFixtures]; // Reusing numLeds to indicate the number of fixtures (even though
    }
  }

  // Close existing connections
  void shutdown() {
    if (mode == device.FADECANDY && opc!=null) {
      opc.dispose();
      isConnected = false;
    }
    if (mode==device.PIXELPUSHER && registry!=null) {
      registry.stopPushing() ;  //TODO: Need to disconnect devices as well
      registry.deleteObserver(testObserver);
      isConnected = false;
    }
    if (mode==device.ARTNET) {
      // TODO: deinitialize artnet connection
      //artnet = null;
    }
    if (mode==device.SACN) {
      source = null;
      universe1 = null;
    }
    if (mode==device.NULL) {
    }
  }


  // Toggle verbose logging for PixelPusher
  void pusherLogging(boolean b) {
    registry.setLogging(b);
  }

  void oscToggleScraper() {
    scraperActive=!scraperActive;
    OscMessage myMessage = new OscMessage("/toggleScraper");
    myMessage.add(int(scraperActive));
    oscP5.send(myMessage, myRemoteLocation);
  }

  void oscNewFile() {
    OscMessage myMessage = new OscMessage("/newFile");
    myMessage.add(1);
    oscP5.send(myMessage, myRemoteLocation);
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
