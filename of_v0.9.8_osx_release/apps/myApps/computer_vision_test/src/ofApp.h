#pragma once

#include "ofMain.h"
#include "ofxOPC.h"
#include "ofxOpenCv.h"

class ofApp : public ofBaseApp{
    
public:
    void setup();
    void update();
    void draw();
    void keyPressed(int key);
    void keyReleased(int key);
    void exit();
    
    void chaseAnimation();
    void setAllLEDColours(ofColor col);
    
    // OPC
    ofxOPC opcClient;
    ofxNeoPixelStrip stick;
    Effects defaultEffects;

    int effect;
    bool hide;
    
    int ledIndex;
    int numLeds;
    vector <ofColor> pixels;
    
    // OpenCV
    
    ofVideoGrabber          vidGrabber;
    ofxCvColorImage			colorImg;
    
    ofxCvGrayscaleImage 	grayImage;
    ofxCvGrayscaleImage 	grayBg;
    ofxCvGrayscaleImage 	grayDiff;
    ofxCvGrayscaleImage     previousFrame;
    
    ofxCvContourFinder      contourFinder;
    vector <ofPoint>        centroids;
    
    int                     threshold;
    bool                    bLearnBakground;
    
    bool                    isMapping;
    int                     ledBrightness;
    

};
