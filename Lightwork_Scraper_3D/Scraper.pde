// 3D Pixel Scraper

public class Scraper {
  LED[] leds; 
  int depth; // Z coordinate scaling
  Table table; // For loading CSV
  HashMap <Integer, Integer> addressMap = new HashMap<Integer, Integer>(); // LED Index:Adress  - Look up address to return the index of a given LED

  Scraper(LED[] ledArray) {  
    leds = ledArray; 
    for (int i = 0; i < leds.length; i++) {
      addressMap.put(i, leds[i].address);
    }
    depth = 800; // Z coordinate scaling
  }

  //update colors to be sent for next network packet
  void update() {
    // Populate LEDs with colours
    // TODO: Make this not random
    for (int i = 0; i<leds.length; i++) {
      color c = color((int)random(255), (int)random(255), (int)random(255));
      leds[i].c = c;
    }
  }

  void updateColorAtIndex(color c, int index) {
    int ledAddress = addressMap.get(index); 
    leds[ledAddress].c = c;
  }
}