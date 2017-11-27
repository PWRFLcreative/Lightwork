/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

Scraper scrape;
OPC opc;

PImage clouds;
int pos;
float margin =50;

void setup() {
  size(640, 480, JAVA2D); // wtf
  background(0);

  //initialize scraper
  scrape = new Scraper("FUTURE_Layout.svg"); 
  scrape.init();
  scrape.normCoords();

  opc = new OPC(this, "192.168.1.137", 7890);
  scrape.update();
  opc.showLocations(false);

  //display array of points from SVG
  //println(scrape.getArray());
}

void draw() {

  // Test animation
  //noFill();
  //strokeWeight(25);
  //for (int i = 0; i < 100; i+=10) {
  //  stroke(255-i*2.5*sin(frameCount*0.7), i*2.5*sin(frameCount*0.5), 255*sin(frameCount*0.2));
  //  ellipse(width/2, height/2, i*100*sin(frameCount*0.02), i*100*sin(frameCount*0.02));
  //}
  // End test animation
  
  
  //rect(0,0,50,50); //test margin bounds
  scrape.display();

  //simple chase animation
  //noStroke();
  fill(255*sin(frameCount*0.1), 255*sin(frameCount*0.3), 255*cos(frameCount*0.6));
  //if (pos<=width)pos+=5;
  //else pos=0;
  //rect(pos, 0, 100, height);
  ellipse(mouseX, mouseY, 30, 30);
  

}