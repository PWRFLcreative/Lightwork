//
//  Tracker.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 26.9.2017.
//
//

#include "Tracker.h"


Tracker::Tracker() {
    setMinAreaRadius(1);
    setMaxAreaRadius(100);
    setThreshold(15);
    // wait for half a frame before forgetting something (15)
    getTracker().setPersistence(24); // TODO: make an interface for this. Should be 1 for sequential tracking
    // an object can move up to 32 pixels per frame
    getTracker().setMaximumDistance(32);
    getTracker().setSmoothingRate(1.0);
    
    hasFoundFirstContour = false;
    
}

Tracker::~Tracker() {
    
}
