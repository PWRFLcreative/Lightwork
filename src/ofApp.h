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
        ofVideoGrabber cam;
		void switchCamera(int num);
		vector <string> enumerateCams();
		ofFbo camFbo;
    
        // GUI
		void buildUI();
		ofxDatGui* gui;
		string IP;
    
        // Contours
        Detector                         detector;
    
        bool                            isMapping;         // Main program-state variable
    
        // SVG
        ofxEditableSVG svg;
        
};
