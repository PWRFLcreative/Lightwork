/* Make OPC LED layout, based on vertecies of an input SVG
 Tim Rolls 2017*/

Scraper scrape;
OPC opc;

PImage clouds;
int pos;
float margin =50;

void setup() {
  size(640, 480, JAVA2D); //wtf
  background(0);

  //initialize scraper
  scrape = new Scraper("binaryMagic.svg"); 
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
  //  stroke(255-i*2.5*sin(frameCount*0.7), i*2.5*sin(frameCount*0.5), 255*sin(frameCount*0.2));
  //  ellipse(width/2, height/2, i*100*sin(frameCount*0.02), i*100*sin(frameCount*0.02));
  //}
  // End test animation


  //rect(0,0,50,50); //test margin bounds
  scrape.display();

  //simple chase animation
  noStroke();
  //fill(255*sin(frameCount*0.1), 255*sin(frameCount*0.3), 255*cos(frameCount*0.6));
  fill(255, frameCount%255, 145, 232);
  if (pos<=width)pos+=5;
  else pos=0;
  rect(pos, 0, 100, height);
  
  fill(frameCount%255, 23, 145, 232);
  if (pos<=height)pos+=5;
  else pos=0;
  rect(0, pos, width, 100);
  //ellipse(mouseX, mouseY, 30, 30);


  //for (int i = 0; i < mouseX; i++) {
  //  stroke(i, mouseX, mouseY);
  //  line(i, 0, i, height); 
  //}
  noStroke();
  fill(100, 100, 100);
  ellipse(mouseX, mouseY, 30, 30);
}