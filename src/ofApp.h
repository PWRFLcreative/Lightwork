#pragma once

#include "ofMain.h"
#include "ofxCv.h"
//#include "ofxGui.h"
#include "ofxOPC.h"
#include "ofxEditableSvg.h"
#include "ofxJSON.h"
#include "ofxDatGui.h"
#include "ofVideoGrabber.h"
#include "Animator.h"

#define RETINA_MIN_WIDTH 2560
#define RETINA_MIN_HEIGHT 1600

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
		void exit();
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);

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
		
    
        // OPC
        ofxOPC              opcClient;
        Animator            animator;

        bool                hasFoundFirstContour;   // Avoid registering 'fake' points before the first detection
    
        // Input
		int camWidth;
		int camHeight;
		float camAspect;
        ofVideoGrabber cam;
		ofVideoGrabber cam2;
		ofVideoGrabber* camPtr;
		void switchCamera(int num, int w, int h);
		vector <string> enumerateCams();
		ofFbo camFbo;
		
        // Background subtraction
        ofxCv::RunningBackground background;        // Background subtraction class with running average
        ofImage thresholded;                        // Binary threshold image
    
        // GUI
		void buildUI(int mult);
		ofxDatGui* gui;
		ofxDatGui* guiBottom;
        bool resetBackground;
        ofParameter<float> learningTime;
        ofParameter<float> thresholdValue;
		string IP;
    
        // Contours
        float                   threshold;          // Brightness threshold for contour detection
        ofxCv::ContourFinder    contourFinder;      // Finds contours in the background subtraction binary image
        vector <ofPoint>        centroids;          // Stores the contour area centers.
        bool                    isMapping;
    
        // SVG
        ofxEditableSVG svg;
        
};
