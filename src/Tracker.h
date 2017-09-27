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

#endif /* Tracker_h */


class Tracker : public ofxCv::ContourFinder {
public:
    Tracker();
    ~Tracker();
    
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
    void update();
    void findSequential();
    
private:
    
    
};
