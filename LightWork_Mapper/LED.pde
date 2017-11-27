//
//  LED.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//  
//  This class tracks location, pattern and color data per LED
//
//////////////////////////////////////////////////////////////

public class LED {
  color c; // Current LED color
  int address; // LED Address
  int bPatternOffset; // Offset the Binary Pattern Seed to avoid 0000000000
  BinaryPattern binaryPattern;
  PVector coord;
  boolean foundMatch;

  LED() {
    c = color(0, 0, 0);
    address = 0;
    coord = new PVector(0, 0);
    bPatternOffset = 682; 
    binaryPattern = new BinaryPattern();
    foundMatch = false; 
  }

  void setColor(color col) {
    c = col;
  }

  void setAddress(int addr) {
    address = addr;
    binaryPattern.generatePattern(address+bPatternOffset);
  }

  //void LEDsetBinaryPattern(BinaryPattern pat) {
  //  binaryPattern = pat;
  //}

  void setCoord(PVector coordinates) {
    coord.set( coordinates.x, coordinates.y); //<>//
  }
}