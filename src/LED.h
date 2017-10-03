//
//  LED.hpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 3.10.2017.
//
// This class is an Abstraction of a single LED
// - Physical Address (int 0 to N)
// - Binary Pattern
// - Physical Coordinates (detected with webcam)

#ifndef LED_hpp
#define LED_hpp

#include <stdio.h>
#include <string>
#include "ofMain.h"
#include "BinaryPattern.h"

using namespace std;

class LED {
    public:
    LED();
    ~LED();
    
    ofColor color; // Current LED color
    int address; // LED Address
    BinaryPattern binaryPattern;
    ofPoint coord;
    
    void setColor(ofColor col);
    void setAddress(int addr);
    void setBinaryPattern(BinaryPattern pat);
    void setCoord(ofPoint coordinates);
    
    private:
    
    
};

#endif /* LED_hpp */
