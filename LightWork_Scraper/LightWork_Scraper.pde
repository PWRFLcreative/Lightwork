 /* 
  * Make LED layout, based on vertecies of an input CSV/SVG
  * Tim Rolls 2017
  */
  
Scraper scrape;
Interface network; 

int pos;
float margin = 50; //prevents scraper from operating outside the canvas
PGraphics gradient; 

void setup() {
  size(640, 480, P3D); 

  gradient = createGraphics(width, height); 
  //initialize scraper
  //replace with your filename, make sure it's in the sketch or /data folder
  scrape = new Scraper("layout.csv"); 

  //initialize connection to LED driver - replace with adress and LED config for your setup
  //(Device type, address (not required for PixelPusher), number of strips, LEDs per strip)
  //network = new Interface(device.PIXELPUSHER, 1,100);
  network = new Interface(device.FADECANDY, "fade2.local", 3, 50);
  network.connect(this);

  //update scraper after network connects
  scrape.update();
  colorMode(HSB, 360, 100, 100); 
}

void draw() {
  //////////////////
  //rainbow chase animation - replace with your drawing code
  background(0);
  fill(0); 
  noStroke();
  fill(abs(sin(frameCount*0.01))*360, 100, 100); 

  // Gradient line
  //horizontalGradient(); 
  verticalGradient(); 

  //cursor to test accuracy
  noStroke();
  fill(255, 255, 255);
  ellipse(mouseX, mouseY, 30, 30);
  //end animation code
  //////////////////
  
  //Scraper functions  
  scrape.display(); //Show locations loaded from CSV 
  scrape.update(); //Update colors to be sent to LEDs
  network.update(scrape.getColors()); //Send colors to LEDs
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