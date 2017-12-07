// 3D Pixel Scraper

public class Scraper {
  LED[] leds; 
  int depth; // Z coordinate scaling
  Table table; // For loading CSV
  int sphereRadius = 5; 

  Scraper (LED[] ledArray) {  
    leds = ledArray; 
    depth = 400; // Z coordinate scaling
  }

  //show points in output window
  void display() {

    for (int i = 0; i < leds.length; i++) {
      pushMatrix(); 
      translate(leds[i].coord.x-width/2, leds[i].coord.y-height/2, leds[i].coord.z); 
      fill(255); 
      sphere(sphereRadius);  
      translate(0, 0, 10); 
      //fill(255, 0, 0); 
      //text(i, 0, 0); 

      popMatrix();
    }
  }

  //update colors to be sent for next network packet
  void update() {
    // Populate LEDs with colours
    for (int i = 0; i<leds.length; i++) {
      color c = color((int)random(255), (int)random(255), (int)random(255));
      leds[i].c = c; 
    }
  }

  void updateColorAtAddress(color c, int address) {
    //hm.put(address, c);
  }
  
}