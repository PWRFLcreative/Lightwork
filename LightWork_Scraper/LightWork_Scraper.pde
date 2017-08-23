/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

Scraper scrape;
OPC opc;

PImage clouds;

void setup() {
  size(800, 800, P2D);
  background(0);
  
  colorMode(HSB, 100);
  noiseDetail(5, 0.4);
  loadPixels();

  // Render the noise to a smaller image, it's faster than updating the entire window.
  clouds = createImage(128, 128, RGB);

  //initialize scraper
  scrape = new Scraper("mapper-test.svg"); 
  scrape.init();

  opc = new OPC(this, "fade1.local", 7890);
  scrape.update();
  
   //display array of points from SVG
  //println(scrape.getArray());
}

void draw() {

  //scrape.update();
  scrape.display();
  
  //generate noise based clouds
  float hue = (noise(millis() * 0.0001) * 200) % 100;
  float z = millis() * 0.0001;
  float dx = millis() * 0.0001;

  for (int x=0; x < clouds.width; x++) {
    for (int y=0; y < clouds.height; y++) {
      float n = 500 * (noise(dx + x * 0.01, y * 0.01, z) - 0.4);
      color c = color(hue, 80 - n, n);
      clouds.pixels[x + clouds.width*y] = c;
    }
  }
  clouds.updatePixels();

  image(clouds, 0, 0, width, height);
}