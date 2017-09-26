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
    
    float                   threshold;          // Brightness threshold for contour detection
//    ofxCv::ContourFinder    contourFinder;      // Finds contours in the background subtraction binary image
    vector <ofPoint>        centroids;          // Stores the contour area centers.
    bool                hasFoundFirstContour;   // Avoid registering 'fake' points before the first detection
    
private:
    
    
};
