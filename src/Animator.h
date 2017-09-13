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

using namespace std;

class Animator {
    
public:
    Animator();  // Constructor
    ~Animator(); // Destructor
    
    // Setters and getters
    void setNumLedsPerStrip(int num);
    void setNumStrips(int num);
    
    int getNumLedsPerStrip();
    int getNumStrips();
    
    bool isTesting();
    bool isMapping();
    
    void toggleMapping();
    void toggleTesting();
    
    vector <ofColor> getPixels();
    
    // Animation methods
    void chaseAnimationOn();
    void setAllLEDColours(ofColor col);
    void test();
    
private:
    
    vector <ofColor>    pixels;
    
    int                 ledIndex;               // Index of LED being mapped (lit and detected).
    int                 numLedsPerStrip;                // Number of LEDs per strip
    int                 numStrips;              // How many strips total
    int                 currentStripNum;        // Strip currently being mapped
    int                 previousStripNum;       // The previous strip being mapped. This is used to turn off last LED in
                                                //previous strip after switching to the next strip
    bool                isMapping_;              // Top-level conditional. Indicates if we are currently mapping the LEDs
    bool				isTesting_;              // Used for LED test pattern toggle
    int                 ledBrightness;          // Brightness of LED's in the animation sequence. Currently hard-coded but
                                                // will be determined by camera frame brightness (to avoid flaring by
                                                // excessively bright LEDs).
    float               ledTimeDelta;           // Used to report the on-time for LEDs in the sequential animation
    

    void resetPixels(); // Reassign pixels to fit numLedsPerStrip * numStrips

};





