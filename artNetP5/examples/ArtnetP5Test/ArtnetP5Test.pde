import artnetP5.*;

ArtnetP5 artnet;
PImage img;

void setup(){
  size(640, 480);
  artnet = new ArtnetP5();
  artnet.setup();
   //printArray( artnet.getNodes());
  img = new PImage(170, 1, PApplet.RGB);
}

void draw(){
  int r = mouseX % 255;
  int g = mouseY % 255;
  int b = (mouseX + mouseY) % 255;
  
  noStroke();
  fill(r, g, b);
  rect(0, 0, width, height);
  
  for(int i = 0; i < img.width * img.height; i++){
    img.set(i % img.width, i / img.width, get(i % width, i / width));
  }
  //artnet.broadcast(img.pixels);
}