/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

Scraper scrape;

void setup() {
  size(800, 800, P2D);
  background(255);

  //initialize scraper
  scrape = new Scraper("hexes.svg"); 
  scrape.init();
  
  //display array of points from SVG
  println(scrape.getArray());
}

void draw() {
  background(0);
  
  scrape.update();
  scrape.display();
}