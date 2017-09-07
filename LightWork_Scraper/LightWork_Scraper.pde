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
  scrape = new Scraper("mapper-lightwork_filteringTesting.svg"); 
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
  
  // Test animation
  //noFill();
  //strokeWeight(25);
  //for (int i = 0; i < 100; i+=10) {
  //  stroke(255-i*2.5, i*2.5, 255*sin(frameCount*0.02));
  //  ellipse(width/2, height/2, i*100*sin(frameCount*0.02), i*100*sin(frameCount*0.02));
  //}
  // End test animation
  
  
  //rect(0,0,50,50); //test margin bounds
  scrape.display();

  //simple chase animation
  noStroke();
  fill(0, 0, 255);
  if (pos<=width)pos+=5;
  else pos=0;
  //rect(pos, 0, 100, height);
  ellipse(mouseX, mouseY, 30, 30);
  

}