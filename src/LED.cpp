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
    coord = ofPoint(0, 0);
//    binaryPattern = BinaryPattern();
}

LED::~LED() {
    
}

void LED::setColor(ofColor col) {
    color = col;
}

void LED::setAddress(int addr) {
    address = addr;
}

void LED::setBinaryPattern(BinaryPattern pat) {
    binaryPattern = pat;
}

void LED::setCoord(ofPoint coordinates) {
    coord = coordinates;
}
