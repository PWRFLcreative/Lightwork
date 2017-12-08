// 3D Pixel Scraper

public class Scraper {
  LED[] scraperLeds; 
  int depth; // Z coordinate scaling
  Table table; // For loading CSV
  int sphereRadius = 5; 
  HashMap <Integer, Integer> addressMap = new HashMap<Integer,Integer>(); // LED Index:Adress  - Look up address to return the index of a given LED

   Scraper(LED[] ledArray) {  
    scraperLeds = ledArray; 
    for (int i = 0; i < scraperLeds.length; i++) {
      addressMap.put(i, scraperLeds[i].address);
    }
    depth = 400; // Z coordinate scaling
  }

  //show points in output window
  void display() {

    for (int i = 0; i < scraperLeds.length; i++) {
      pushMatrix(); 
      translate(scraperLeds[i].coord.x-width/2, scraperLeds[i].coord.y-height/2, scraperLeds[i].coord.z); 
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
    // TODO: Make this not random
    for (int i = 0; i<scraperLeds.length; i++) {
      color c = color((int)random(255), (int)random(255), (int)random(255));
      scraperLeds[i].c = c; 
    }
  }

  void updateColorAtAddress(color c, int address) {
    int ledIndex = addressMap.get(address); 
    //hm.put(address, c);
    if (ledIndex < scraperLeds.length) {
      scraperLeds[ledIndex].c = c; 
    }
    
  }
  
}