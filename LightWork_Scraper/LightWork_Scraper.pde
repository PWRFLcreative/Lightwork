/* 
 * Make LED layout, based on vertecies of an input CSV/SVG
 * Includes 2 test animations and optional Syphon/Spout input
 * Tim Rolls 2017-2018
 */

Scraper scrape;
Interface network; 

int pos;
float margin = 50; //prevents scraper from operating outside the canvas
PGraphics gradient; 

void setup() {
  size(512, 512, P3D); 
  surface.setLocation((displayWidth / 2) - width / 2, ((int)displayHeight / 2) - height / 2);

  //initialize scraper
  //replace with your filename, make sure it's in the sketch or /data folder
  scrape = new Scraper("layout.csv"); 

  //initialize connection to LED driver - replace with adress and LED config for your setup
  //Fadecandy/ PixelPusher = (Device type, address (not required for PixelPusher), number of strips, LEDs per strip)
  //Artnet/ sACN = (Device type, Universe, number of fixtures, channels per fixture)
  
  //network = new Interface(device.PIXELPUSHER, 1,100);
  //network = new Interface(device.FADECANDY, "10.10.10.101", 8, 60);
  network = new Interface(device.SACN, 1, 98, 3); 

  //connect to specified controller
  network.connect(this);

  //update scraper after network connects
  scrape.update();
  colorMode(HSB, 360, 100, 100);
  
  // Create a new Syphon or Spout object - comment out to disable
  setupSyphonSpout();
}

void draw() {
  background(0);

  verticalGradient(); // Test pattern animation

  updateSyphonSpout(); // receive sypon/spout input - comment out to disable

  //cursor to test accuracy
  noStroke();
  fill(360);
  ellipse(mouseX, mouseY, 30, 30);

  //Scraper functions - should always be at end of draw loop
  if (scrape.isActive()) {
    scrape.update(); //Update colors to be sent to LEDs
    network.update(scrape.getColors()); //Send colors to LEDs
    scrape.display(); //Show locations loaded from CSV
  }
}


//////////////////
//Gradient drawing methods - can be replaced with your own drawing code
//////////////////

void horizontalGradient() {
  int numLines = 450; 
  if (pos<=height+numLines)pos+=5;
  else pos=0;
  for (int i = 0; i < numLines; i++) {
    color c;
    if (i < numLines/2) {
      c = color (abs(sin(frameCount*0.01))*360+i, 100, i);
    } else {
      c = color (abs(sin(frameCount*0.01))*360, 100, numLines-i);
    }
    stroke(c); 
    line(0, i+pos-numLines, width, i+pos-numLines);
  }
}

void verticalGradient() {
  int numLines = 250; 
  if (pos<=width+numLines)pos+=5;
  else pos=0;

  for (int i = 0; i < numLines; i++) {
    int x = i+pos-numLines; 
    color c;
    if (i < numLines/2) {
      //c = color (abs(sin(frameCount*0.01))*(i+pos/width*360), 100, i);
      c = color (abs(sin(frameCount*0.01))*x/(numLines+pos)*360, 100, i);
    } else {
      //c = color (abs(sin(frameCount*0.01))*(i-pos/width*360), 100, numLines-i);
      c = color (abs(sin(frameCount*0.01))*x/(numLines+pos)*360, 100, numLines-i);
    }
    stroke(c); 

    line(x, 0, x, width );
  }
}
