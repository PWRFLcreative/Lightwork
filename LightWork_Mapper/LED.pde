/*
 *  LED
 *  
 *  This class tracks location, pattern and color data per LED
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @authors Leó Stefánsson and Tim Rolls
 */

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

  // Set LED address and generate a unique binary pattern
  void setAddress(int addr) {
    address = addr;
    binaryPattern.generatePattern(address+bPatternOffset);
    println("LED Address: "+addr+" pattern: "+binaryPattern.binaryPatternString);
  }

  void setCoord(PVector coordinates) {
    coord.set( coordinates.x, coordinates.y);
  }
}