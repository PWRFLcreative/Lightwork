#pragma once

#include "ofMain.h"
#include "ofxCv.h"
#include "ofxGui.h"
#include "ofxOPC.h"
#include "ofxEditableSvg.h"
#include "ofxJSON.h"
#include "ofxDatGui.h"
#include "ofVideoGrabber.h"

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
    
        void chaseAnimationOn();
        void chaseAnimationOff();
		void test();
        void setAllLEDColours(ofColor col);
        void generateSVG(vector <ofPoint> points);
        void generateJSON(vector <ofPoint> points);
        vector <ofPoint> removeDuplicatesFromPoints(vector <ofPoint> points);

		//GUI
		void onButtonEvent(ofxDatGuiButtonEvent e);
		void onToggleEvent(ofxDatGuiToggleEvent e);
		void onSliderEvent(ofxDatGuiSliderEvent e);
		void onTextInputEvent(ofxDatGuiTextInputEvent e);
		void on2dPadEvent(ofxDatGui2dPadEvent e);
		void onDropdownEvent(ofxDatGuiDropdownEvent e);
		void onColorPickerEvent(ofxDatGuiColorPickerEvent e);
		void onMatrixEvent(ofxDatGuiMatrixEvent e);
		void switchCamera(int num);
    
        // OPC
        ofxOPC              opcClient;
        Effects             defaultEffects;
        vector <ofColor>    pixels;
    
        int                 ledIndex;
        int                 numLeds;
        bool                isMapping;
		bool				isTesting;
        int                 ledBrightness;
    
        bool                isLedOn;
    
        // Input
        ofVideoGrabber cam;
    
        // Background subtraction
        ofxCv::RunningBackground background;
        ofImage thresholded;
    
        // GUI
        //ofxPanel gui;
        bool resetBackground;
        ofParameter<float> learningTime, thresholdValue;
		string IP;
    
        // Contours
        float                   threshold;
        ofxCv::ContourFinder    contourFinder;
        vector <ofPoint>        centroids;
    
        // SVG
        ofxEditableSVG svg;
        
};
