//
//  Tracker.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 26.9.2017.
//
//

#include "Tracker.h"

Tracker::Tracker() {
    bPat.generatePattern(0); // Populates bPat.pattern and bPat.patternVector with zeros
}

Tracker::~Tracker() {
    
}

void Tracker::setup(ofVideoGrabber *camera) {
    cam = camera;
    mode = TRACKER_MODE_CHASE; // TODO review
    setMinAreaRadius(1);
    setMaxAreaRadius(100);
    setThreshold(15);
    // wait for half a frame before forgetting something (15)
    getTracker().setPersistence(24); // TODO: make an interface for this. Should be 1 for sequential tracking
    // an object can move up to 32 pixels per frame
    getTracker().setMaximumDistance(32);
    getTracker().setSmoothingRate(1.0);
    
    hasFoundFirstContour = false;
    
    // Allocate the thresholded view so that it draws on launch (before calibration starts).
    thresholded.allocate(cam->getWidth(), cam->getHeight(), OF_IMAGE_COLOR);
    thresholded.clear();
    
    
}

void Tracker::setMode(tracker_mode_t m) {
    mode = m;
}

void Tracker::update() {
    
    // Binary pattern detection
    // Background subtraction
    background.setLearningTime(learningTime);
    background.setThresholdValue(thresholdValue);
    background.update(*cam, thresholded);
    
    
    // Get contours
    ofxCv::blur(thresholded, 10); // TODO: do we need this?
    findContours(thresholded);
    thresholded.update();
    
    if (mode == TRACKER_MODE_BINARY) {
        findBinary();
    }
    else if (mode == TRACKER_MODE_CHASE) {
        findSequential();
    }
}

void Tracker::findBinary() {
    // Get colour from original frame in contour areas
    for (int i = 0; i < size(); i++) {
        cv::Rect rect = getBoundingRect(i);
        ofImage img;
        img = cam->getPixels();
        img.crop(rect.x, rect.y, rect.width, rect.height);
        ofPixels pixels = img.getPixels();
        // Pixel format is RGB
        float r = 0;
        float g = 0;
        float b = 0;
        float brightness = 0;
        for (int i = 0; i < pixels.getWidth(); i++) {
            for (int j = 0; j < pixels.getHeight(); j++) {
                ofFloatColor col = pixels.getColor(i, j);
                r += col.r;
                g += col.g;
                b += col.b;
                brightness = col.getBrightness();
                //                    cout << brightness << endl;
                //                    cout << col.r << endl;
            }
        }
        float avgR, avgG, avgB = 0;
        int numPixels = pixels.getWidth()*pixels.getHeight();
        avgR = r/numPixels;
        avgG = g/numPixels;
        avgB = b/numPixels;
        
        //            cout << "[" << avgR << ", " << avgG << ", " << avgB << "]," << endl;
        
        // If brightness is above threshold, get the brightest colour
        // Analysis suggests the threshold is around 0.4, I'll use 0.45
        // TODO: Automatically detect threshold value (depends on lighting conditions, background material colour etc.)
        string detectedColor = "";
        float brightnessThreshold = 0.45;
        if (brightness >= brightnessThreshold) {
            //                ofLogVerbose("binary") << "Above threshold, check for brightest color" << endl;
            vector<float> colours;
            colours.push_back(avgR);
            colours.push_back(avgG);
            colours.push_back(avgB);
            
            // Get the index of the brightest average colour
            int dist = distance(colours.begin(), max_element(colours.begin(), colours.end()));
            //                cout << dist << endl;
            
            switch (dist) {
                case 0:
                    detectedColor = "RED";
                    break;
                case 1:
                    detectedColor = "GREEN";
                    break;
                case 2:
                    detectedColor = "BLUE";
                    break;
                default:
                    ofLogError("binary") << "Brightest colour is not a known colour!" << endl;
            }
            
        }
        else {
            detectedColor = "BLACK";
            //                cout << "BLACK" << endl;
            //                ofLogVerbose("binary") << "Below Threshold, no need to check for brightnest color" << endl;
        }
        cout << detectedColor << endl;
        
        int maxIndex = 0;
        
        
    }
    // Profit
}
void Tracker::findSequential() {
    bool success = false; // Indicate if we successfully mapped an LED on this frame (visible or off-canvas
    
    // We have 1 contour
    if (size() == 1 && !success) {
        ofLogVerbose("tracking") << "Detected one contour, as expected.";
        ofPoint center = ofxCv::toOf(getCenter(0));
        centroids.push_back(center);
        success = true;
    }
    
    // We have more than 1 contour, select the brightest one.
    else if (size() > 1 && !success){ // TODO: review isLedOn vs isMapping()
        ofLogVerbose("tracking") << "num contours: " << ofToString(size());
        int brightestIndex = 0;
        int previousBrightness = 0;
        for(int i = 0; i < size(); i++) {
            int brightness = 0;
            cv::Rect rect = getBoundingRect(i);
            //ofLogNotice("x:" + ofToString(rect.x)+" y:"+ ofToString(rect.y)+" w:" + ofToString(rect.width) + " h:"+ ofToString(rect.height));
            ofImage img;
            img = thresholded;
            img.crop(rect.x, rect.y, rect.width, rect.height);
            ofPixels pixels = img.getPixels();
            
            for (int i = 0; i< pixels.size(); i++) {
                brightness += pixels[i];
            }
            brightness /= pixels.size();
            
            // Check if the brightness is greater than the previous contour brightness
            if (brightness > previousBrightness) {
                brightestIndex = i;
            }
            previousBrightness = brightness;
            success = true;
            //ofLogNotice("Brightness: " + ofToString(brightness));
        }
        ofLogNotice("tracking") << "brightest index: " << ofToString(brightestIndex);
        ofPoint center = ofxCv::toOf(getCenter(brightestIndex));
        centroids.push_back(center);
        hasFoundFirstContour = true;
        //ofLogVerbose("tracking") << "added point, ignored additional points. FrameCount: " << ofToString(ofGetFrameNum())+ " ledIndex: " << animator.ledIndex+(animator.currentStripNum-1)*animator.numLedsPerStrip;
    }
    // Deal with no contours found
    else if (!success && hasFoundFirstContour){
        ofLogVerbose("tracking") << "NO CONTOUR FOUND!!!";
        
        // No point detected, create fake point
        ofPoint fakePoint;
        fakePoint.set(0, 0);
        centroids.push_back(fakePoint);
        success = true;
        //ofLogVerbose("tracking") << "CREATING FAKE POINT                     at frame: " << ofToString(ofGetFrameNum()) << " ledIndex " << animator.ledIndex+(animator.currentStripNum-1)*animator.numLedsPerStrip;
    }
    
    if(success) {
        hasFoundFirstContour = true;
        //animator.chaseAnimationOff();
        //            opcClient.autoWriteData(animator.getPixels());
    }
    
}
