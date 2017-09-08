#pragma once

#include "ofMain.h"
#include "ofxCv.h"
#include "ofxGui.h"
#include "ofxOPC.h"
#include "ofxEditableSvg.h"
#include "ofxJSON.h"

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
    
        // OPC
        ofxOPC              opcClient;
        vector <ofColor>    pixels;
    
        int                 ledIndex;               // Index of LED being mapped (lit and detected).
        int                 numLedsPerStrip;                // Number of LEDs per strip
        int                 numStrips;              // How many strips total
        int                 currentStripNum;        // Strip currently being mapped
        int                 previousStripNum;       // The previous strip being mapped. This is used to turn off last LED in
                                                    //previous strip after switching to the next strip
        bool                isMapping;              // Top-level conditional. Indicates if we are currently mapping the LEDs
		bool				isTesting;              // Used for LED test pattern toggle
        int                 ledBrightness;          // Brightness of LED's in the animation sequence. Currently hard-coded but
                                                    // will be determined by camera frame brightness (to avoid flaring by
                                                    // excessively bright LEDs).
        float               ledTimeDelta;           // Used to report the on-time for LEDs in the sequential animation
        bool                isLedOn;                // Tracks LED state for the sequenctial animation
        bool                hasFoundFirstContour;   // Avoid registering 'fake' points before the first detection
    
        // Input
        ofVideoGrabber cam;                         // Video Camera
    
        // Background subtraction
        ofxCv::RunningBackground background;        // Background subtraction class with running average
        ofImage thresholded;                        // Binary threshold image
    
        // GUI
        ofxPanel gui;
        ofParameter<bool> resetBackground;          // Reset the background detection (TODO: Review if needed)
        ofParameter<float> learningTime;            // Set the time for the running averabe background detection.
        ofParameter<float> thresholdValue;
    
        // Contours
        float                   threshold;          // Brightness threshold for contour detection
        ofxCv::ContourFinder    contourFinder;      // Finds contours in the background subtraction binary image
        vector <ofPoint>        centroids;          // Stores the contour area centers.
    
        // SVG
        ofxEditableSVG svg;
        
};
