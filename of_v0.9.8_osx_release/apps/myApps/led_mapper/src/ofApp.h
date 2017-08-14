#pragma once

#include "ofMain.h"
#include "ofxCv.h"
#include "ofxGui.h"
#include "ofxOPC.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
    
        void chaseAnimation();
        void setAllLEDColours(ofColor col);
        
        // OPC
        ofxOPC              opcClient;
        Effects             defaultEffects;
        vector <ofColor>    pixels;
    
        int                 ledIndex;
        int                 numLeds;
        bool                isMapping;
        int                 ledBrightness;
    
        // Input
        ofVideoGrabber cam;
    
        // Background subtraction
        ofxCv::RunningBackground background;
        ofImage thresholded;
    
        // GUI
        ofxPanel gui;
        ofParameter<bool> resetBackground;
        ofParameter<float> learningTime, thresholdValue;
    
        // Contours
        float                   threshold;
        ofxCv::ContourFinder    contourFinder;
        bool                    showLabels;
        vector <ofPoint>        centroids;
    
};
