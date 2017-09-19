//
//  Animator.hpp
//  Lightwork-Mapper
//
//  Created by Leó Stefánsson on 11.9.2017.
//
//
#pragma once

#ifndef Animator_h
#define Animator_h

#include <stdio.h>
#include "ofMain.h"

#endif /* Animator_h */

#include "BinaryPattern.h"

using namespace std;

enum animation_mode_t {ANIMATION_MODE_CHASE, ANIMATION_MODE_TEST, ANIMATION_MODE_BINARY};

class Animator {
    
public:
    Animator();  // Constructor
    ~Animator(); // Destructor
    
    animation_mode_t mode;
    void setMode(animation_mode_t m);
    void setLedBrightness(int brightness);
    
    // Setters and getters
    void setNumLedsPerStrip(int num);
    void setNumStrips(int num);
    
    int getNumLedsPerStrip();
    int getNumStrips();
    
    vector <ofColor> getPixels();
    
    // Animation methods
    void update(); // Updates depending on animation_mode_t
    void chase();
    void setAllLEDColours(ofColor col);
    void test();
    void binaryAnimation();
    
private:
    
    vector <ofColor>    pixels;
    
    int                 ledIndex;               // Index of LED being mapped (lit and detected).
    int                 numLedsPerStrip;                // Number of LEDs per strip
    int                 numStrips;              // How many strips total
    int                 ledBrightness;          // Brightness of LED's in the animation sequence. Currently hard-coded but
                                                // will be determined by camera frame brightness (to avoid flaring by
                                                // excessively bright LEDs).
    int                 testIndex;              // Used for the test() animation sequence
    
    void resetPixels(); // Reassign pixels vector to fit numLedsPerStrip * numStrips
    
    BinaryPattern binaryPattern;

};





