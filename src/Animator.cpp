//
//  Animator.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 11.9.2017.
//
//

#include "Animator.h"

using namespace std;

// Constructor
Animator::Animator(void) {
    cout << "Animator created" << endl;
    numLedsPerStrip = 64;
    ledBrightness = 200;
    numStrips = 8;
    isMapping_ = false;
    isTesting_ = false;
    
    ledIndex = 0;
    currentStripNum = 1;
    previousStripNum = currentStripNum;
    ledTimeDelta = 0.0;
    
    // TODO: assign pixels for the full setup (all the channels)iter
    // TODO: Make pixels private and declare a getter
    pixels.assign(numLedsPerStrip*numStrips, ofColor(0,0,0));
}

// Destructor
Animator::~Animator(void) {
    cout << "Animator destroyed" << endl;
}

//////////////////////////////////////////////////////////////
// Setters and getters
//////////////////////////////////////////////////////////////

void Animator::setNumLedsPerStrip(int num) {
    ofLogNotice("Setting up Animator");
    numLedsPerStrip = num;
    resetPixels();
}

int Animator::getNumLedsPerStrip() {
    return numLedsPerStrip;
}

void Animator::setNumStrips(int num) {
    numStrips = num;
    resetPixels();
}

int Animator::getNumStrips() {
    return numStrips;
}

bool Animator::isTesting() {
    return isTesting_;
}

bool Animator::isMapping() {
    return isMapping_;
}

void Animator::toggleTesting() {
    isTesting_ = !isTesting_;
}

void Animator::toggleMapping() {
    isMapping_ = !isMapping_;
}

// Internal method to reassign pixels with a vector of the right length. Gives all pixels a value of (0,0,0) (black/off).
void Animator::resetPixels() {
    vector <ofColor> pix;
    pix.assign(numLedsPerStrip*numStrips, ofColor(0,0,0));
    pixels = pix;
}

// Return pixels (to update OPC or PixelPusher)
vector <ofColor> Animator::getPixels() {
    return pixels;
}

//////////////////////////////////////////////////////////////
// Animation Methods
//////////////////////////////////////////////////////////////

// Update the pixels for all the strips
// This method does not return the pixels, it's up to the users to send animator.pixels to the driver (FadeCandy, PixelPusher).
void Animator::chaseAnimationOn() {
    ofLogVerbose("LED") << "Animation ON: " << ofToString(ofGetElapsedTimef());
    ledTimeDelta = ofGetElapsedTimef();
    // Chase animation
    // Set the colors of all LEDs on the current strip
    
    for (int i = 0; i <  numLedsPerStrip*numStrips; i++) {
        ofColor col;
        if (i == ledIndex) {
            col = ofColor(ledBrightness, ledBrightness, ledBrightness);
        }
        else {
            col = ofColor(0, 0, 0);
        }
        pixels.at(i) = col;
    }
    
    ledIndex++;
    if (ledIndex == numLedsPerStrip+numLedsPerStrip*numStrips) {
        ledIndex = 0;
        previousStripNum = currentStripNum;
        currentStripNum++;
    }
    
    // TODO: review this conditional
    if (currentStripNum > numStrips) {
        isMapping_ = false;
    }
}

// Set all LEDs to the same colour (useful to turn them all on or off).
void Animator::setAllLEDColours(ofColor col) {
    for (int i = 0; i <  numLedsPerStrip*numStrips; i++) {
        pixels.at(i) = col;
    }
}

//LED Pre-flight test
void Animator::test() {
    int start = ofGetFrameNum(); // needs global variables to work properly
    int currFrame = start;
    int diff = currFrame - start;
    if (diff <300){
        if (diff < 100) { setAllLEDColours(ofColor(255, 0, 0)); }
        else if (diff <200 && diff >100){ setAllLEDColours(ofColor(0, 255, 0)); }
        else if (diff < 300 && diff >200) { setAllLEDColours(ofColor(0, 0, 255)); }
    }
    currFrame = ofGetFrameNum();
    diff = currFrame - start;
    
    if (diff >= 300) {
        setAllLEDColours(ofColor(0, 0, 0));
        isTesting_ = false;
    }
    
}
