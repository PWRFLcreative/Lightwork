/* Make LED layout, based on vertecies of an input CSV/SVG
 Tim Rolls 2017*/

Scraper scrape;
Interface network; 

PImage clouds;
int pos;
float margin =50; //prevents scraper from operating outside the canvas

void setup() {
  size(640, 480, P3D); // wtf
  background(0);

  //initialize scraper
  //replace with your filename, make sure it's in the sketch or /data folder
  scrape = new Scraper("binary_layout.csv"); 
  
  //initialize connection to LED driver
  network = new Interface(device.PIXELPUSHER, "192.168.1.137", 1,50);
  network.connect(this);
  
  //update scraper after network connects
  scrape.update();

  //output scraper locations to console
  //println(scrape.getArray());
}

void draw() {
  background(0);

  //Show locations loaded from layout in processing sketch 
  scrape.display();

  //simple chase animation - replace with your drawing code
  //noStroke();
  //fill(255*sin(frameCount*0.1), 255*sin(frameCount*0.3), 255*cos(frameCount*0.6));
  //ellipse(mouseX, mouseY, 30, 30);
  
  //fill(frameCount%255, 23, 145, 232);
  //if (pos<=height)pos+=5;
  //else pos=0;
  //rect(0, pos, width, 100);
  
  //cursor to test accuracy
  noStroke();
  fill(255 , 255, 255);
  ellipse(mouseX, mouseY, 30, 30);
  
  scrape.update();
  network.update(scrape.getColors());
}