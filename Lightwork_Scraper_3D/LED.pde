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
  PVector coord;
  boolean foundMatch;

  LED() {
    c = color(0, 0, 0);
    address = 0;
    coord = new PVector(0, 0);
  }

  void setColor(color col) {
    c = col;
  }

  void setAddress(int addr) {
    address = addr;
  }

  void setCoord(PVector coordinates) {
    coord.set( coordinates.x, coordinates.y);
  }
  
  void display() {
  
  }
}