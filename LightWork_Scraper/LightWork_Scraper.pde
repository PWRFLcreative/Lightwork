/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

Scraper scrape;
OPC opc;

PImage clouds;
int pos;
float margin =50;

void setup() {
  size(800, 800, JAVA2D); //wtf
  background(0);
  
  //initialize scraper
  scrape = new Scraper("lightwork_map_complete.svg"); 
  scrape.init();
  scrape.normCoords();

  opc = new OPC(this, "fade1.local", 7890);
  scrape.update();
  opc.showLocations(false);
  
  //display array of points from SVG
  //println(scrape.getArray());
}

void draw() {
  background(0);
  
  rect(0,0,50,50);
  //scrape.update();
  scrape.display();
  
  //simple chase animation
  noStroke();
  fill(0,0,255);
  if(pos<=width)pos+=5;
  else pos=0;
  //rect(pos,0,100,height);
  ellipse(mouseX, mouseY, 30, 30);
  
}