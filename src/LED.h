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

using namespace std;

class LED {
    public:
    LED();
    ~LED();
    
    ofColor color; // Current LED color
    int address; // LED Address
    string binaryPatternString;
    int x;
    int y;
    
    void setColor(ofColor col);
    void setAddress(int addr);
    void setBinaryPattern(string pat);
    void setCoord(int xLoc, int yLoc);
    
    
    
    
    private:
    
    
};

#endif /* LED_hpp */
