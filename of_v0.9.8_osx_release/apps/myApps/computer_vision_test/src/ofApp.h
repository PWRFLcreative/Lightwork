#pragma once

#include "ofMain.h"
#include "ofxOPC.h"

class ofApp : public ofBaseApp{
    
public:
    void setup();
    void update();
    void draw();
    void keyPressed(int key);
    void keyReleased(int key);
    void exit();
    
    ofxOPC opcClient;
    ofxNeoPixelStrip stick;
    
    Effects defaultEffects;
    
    int effect;
    bool hide;
    
    int ledIndex;
    int numLeds;
    vector <ofColor> pixels;

};
