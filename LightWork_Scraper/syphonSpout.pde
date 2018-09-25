//////////////////
// Syphon / Spout Loading - used to pipe input from another software
// Comment/uncomment for your appropriate operating system
//////////////////

PImage img;

///////////////////////////////////////
/*
// SYPHON (MAC)
 import codeanticode.syphon.*;
 SyphonClient client;
 void setupSyphonSpout() {
 tex = createGraphics(width, height, P2D);
 client = new SyphonClient(this);
 }
 void updateSyphonSpout() {
 background(0);
 if (client.newFrame()) {
 // The first time getImage() is called with 
 // a null argument, it will initialize the PImage
 // object with the correct size.
 img = client.getImage(img); // load the pixels array with the updated image info (slow)
 //img = client.getImage(img, false); // does not load the pixels array (faster)    
 }
 if (img != null) {
 image(img, 0, 0, width, height);  
 }
 }
 */
///////////////////////////////////////

// SPOUT (WIN)
import spout.*;

Spout client;

void setupSyphonSpout() {
  client = new Spout(this);
  client.receiveTexture();
}

void updateSyphonSpout() {
  client.receiveTexture();
}

/////////////////////////////////////////
