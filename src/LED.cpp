//
//  LED.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 3.10.2017.
//
//

#include "LED.h"


LED::LED() {
    color = ofColor(0, 0, 0);
    address = 0;
    binaryPatternString = "0000000000";
    x = 0;
    y = 0;
}

LED::~LED() {
    
}

void LED::setColor(ofColor col) {
    color = col;
}

void LED::setAddress(int addr) {
    address = addr;
}

void LED::setBinaryPattern(string pat) {
    binaryPatternString = pat;
}

void LED::setCoord(int xLoc, int yLoc) {
    x = xLoc;
    y = yLoc;
}
