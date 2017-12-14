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

  device               mode;
  private LED[]                leds; 

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
  //Constructors
  /////////////////////////////////////////////////////////////

  Interface() {
    mode = device.NULL;
    println("Interface created");
  }

  //setup for fadecandy
  Interface(device m, String ip, int strips, int ledCount) {
    mode = m;
    IP = ip;
    numStrips =strips;
    ledsPerStrip = ledCount;
    numLeds = ledsPerStrip*numStrips;
    
    //populateLeds();

    println("Interface created");
  }

  //setup for pixel pusher (no address required)
  Interface(device m, int strips, int ledCount) {
    mode = m;
    numStrips =strips;
    ledsPerStrip = ledCount;
    numLeds = ledsPerStrip*numStrips;
    //populateLeds();
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
  }

  int getNumLedsPerStrip() {
    return ledsPerStrip;
  }

  void setNumStrips(int num) {
    numStrips = num;
    numLeds = ledsPerStrip*numStrips;
    //resetPixels();
  }

  int getNumStrips() {
    return numStrips;
  }

  //load position data from csv
  void loadCSV(String file_) {
    // Populate table
    println("LOAD CSV"); 
    table = loadTable(file_, "header");
    printArray(table.getColumnTitles()); 
    
    // Allocate LEDS
    leds = new LED[table.getRowCount()];
    
    for (int i = 0; i < leds.length; i++) {
      leds[i] = new LED(); 
    }
    
    int zDepth = 300; 
    for ( int i = 0; i < table.getRowCount(); i++) {
      TableRow row = table.getRow(i);
      int address = row.getInt("address");
      float x = row.getFloat("x")*width;
      float y = row.getFloat("y")*height;
      float z = row.getFloat("z")*zDepth;
      //println(z); 
      PVector v = new PVector();
      v.set (x, y, z ); 
      leds[i].address = address; 
      leds[i].coord.set(v); 
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

  //////////////////////////////////////////////////////////////
  // Network Methods
  //////////////////////////////////////////////////////////////

  void updateColorAtIndex(color c, int index) {
    leds[index].c = c;
  }
  
  void update() {
    // Actualn colors[] array
    color[] colors = new color[numLeds];

    for (int i = 0; i < leds.length; i++) {
      colors[i] = leds[i].c;
    }

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

  //open connection to controller
  void connect(PApplet parent) {
    //if (isConnected) {
    //  shutdown();
    //}

    if (mode == device.FADECANDY) {
      if (opc== null) {
        opc = new OPC(parent, IP, port);

        int startTime = millis();

        print("waiting");
        while (!opc.isConnected) {
          int currentTime = millis(); 
          int deltaTime = currentTime - startTime;
          if ((deltaTime%1000)==0) {
            print(".");
          }
          if (deltaTime > 5000) {
            println(" ");
            println("connection failed, check your connections..."); 
            isConnected = false;
            //network.shutdown();
            break;
          }
        }
        println(" ");
      }

      if (opc.isConnected()) {
        println("Connected to Fadecandy OPC server at: "+IP+":"+port); 
        isConnected =true;
        opc.setPixelCount(numLeds);
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
      }
      registry.setLogging(false);
    }

  }

  //Close existing connections
  void shutdown() {
    if (mode == device.FADECANDY && opc!=null) {
      //opc.dispose();
      opc = null;
    }
    if (mode==device.PIXELPUSHER && registry !=null) {
      registry.stopPushing() ;  //TODO: Need to disconnect devices as well
      registry.deleteObserver(testObserver);
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