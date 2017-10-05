//
//  Tracker.hpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 26.9.2017.
//
//

#ifndef Tracker_h
#define Tracker_h

#include <stdio.h>
#include "ofxCv.h"
#include "BinaryPattern.h"


enum detector_mode_t {DETECTOR_MODE_CHASE, DETECTOR_MODE_BINARY};

class Detector : public ofxCv::ContourFinder {
    
public:
    Detector();
    ~Detector();
    
    // Background subtraction
    ofxCv::RunningBackground        background;        // Background subtraction class with running average
    ofImage                         thresholded;       // Binary threshold image
    
    float                   threshold;          // Brightness threshold for contour detection
    vector <ofPoint>        centroids;          // Stores the contour area centers.
    bool                    hasFoundFirstContour;   // Avoid registering 'fake' points before the first detection
    ofParameter<float>      learningTime;
    ofParameter<float>      thresholdValue; // Redundant? Was ofParameter...
    ofVideoGrabber          *cam;
    
    void setup(ofVideoGrabber *camera);
    void setMode(detector_mode_t m);
    detector_mode_t mode;
    
    void update();
    void findBinary();
    void findSequential();
    
    vector <BinaryPattern>          detectedPatterns;
    int                             index;
    int                             previousState;
    
    
private:
    
    
};

#endif /* Tracker_h */
