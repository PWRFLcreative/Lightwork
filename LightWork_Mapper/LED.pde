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
  BinaryPattern binaryPattern;
  PVector coord;


  LED() {
    c = color(0, 0, 0);
    address = 0;
    coord= new PVector(0, 0);
    binaryPattern = new BinaryPattern();
  }

  void setColor(color col) {
    c = col;
  }

  void setAddress(int addr) {
    address = addr;
    int bPatternOffset = 150; // TODO: review, make accessible...
    binaryPattern.generatePattern(address+bPatternOffset);
  }

  //void LEDsetBinaryPattern(BinaryPattern pat) {
  //  binaryPattern = pat;
  //}

  void setCoord(PVector coordinates) {
    coord.set( coordinates.x, coordinates.y);
  }
}