#pragma once

#include "ofMain.h"
#include "ofxCv.h"
//#include "ofxGui.h"
//#include "ofxOPC.h"
#include "ofxEditableSvg.h"
#include "ofxJSON.h"
#include "ofxDatGui.h"
#include "ofVideoGrabber.h"
#include "Animator.h"
#include "Detector.h"

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
		
    
        // OPC, Animator
        ofxOPC              opcClient; // 
        Animator            animator;
    
        // Input
		int camWidth;
		int camHeight;
		float camAspect;
		vector <ofVideoDevice> devices;
        ofVideoGrabber cams[8];
		ofVideoGrabber* camPtr;
		void switchCamera(int num, int w, int h);
		vector <string> enumerateCams();
		ofFbo camFbo;

    
        // GUI
		void buildUI(int mult);
		ofxDatGui* gui;
        ofxDatGui* guiBottom;
		string IP;
    
        // Contours
        Detector                         detector;
    
        bool                            isMapping;         // Main program-state variable
    
        // SVG
        ofxEditableSVG svg;
        
};
