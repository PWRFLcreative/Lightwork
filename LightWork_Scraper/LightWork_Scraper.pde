/* Make LED layout, based on vertecies of an input CSV/SVG
 Tim Rolls 2017*/
import processing.video.*; 

Scraper scrape;
Interface network; 
Capture cam; 

PImage clouds;
int pos;
float margin = 50; //prevents scraper from operating outside the canvas
PGraphics gradient; 

void setup() {
  size(640, 480, P3D); 
  //background(0);
  // Init webcam
  //cam = new Capture(this, 640, 480); 
  //cam.start();

  gradient = createGraphics(width, height); 
  //initialize scraper
  //replace with your filename, make sure it's in the sketch or /data folder
  scrape = new Scraper("layout.csv"); 

  //initialize connection to LED driver
  //network = new Interface(device.PIXELPUSHER, "192.168.1.137", 1,50);
  network = new Interface(device.FADECANDY, "fade1.local", 1, 50);
  network.connect(this);

  //update scraper after network connects
  scrape.update();

  colorMode(HSB, 360, 100, 100); 
  //output scraper locations to console
  //println(scrape.getArray());
}

void draw() {
  //background(0);
  fill(0); 
  //rect(0, 0, width, height); 


  // Display camera
  //if (cam.available()) {
  //  cam.read();
  //  image(cam, 0, 0, width, height); 
  //}

  //simple chase animation - replace with your drawing code
  noStroke();
  //fill(255*sin(frameCount*0.1), 255*sin(frameCount*0.3), 255*cos(frameCount*0.6));
  ellipse(mouseX, mouseY, 30, 30);

  //fill(frameCount%255, 23, 145, 232);
  fill(abs(sin(frameCount*0.01))*360, 100, 100); 

  //rect(0, pos, width, 100);

  // Gradient line
  //horizontalGradient(); 
  verticalGradient(); 

  //cursor to test accuracy
  noStroke();
  fill(255, 255, 255);
  ellipse(mouseX, mouseY, 30, 30);

  //filter(BLUR, 3); 
  //Show locations loaded from layout in processing sketch 
  scrape.display();
  scrape.update();
  network.update(scrape.getColors());
}

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