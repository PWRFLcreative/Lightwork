//
//  Animator.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 11.9.2017.
//
//

#include "Animator.h"

using namespace std;

Animator::Animator(void) {
    cout << "Animator created" << endl;
    numLedsPerStrip = 64;
    ledBrightness = 200;
    numStrips = 8;
    isMapping = false;
    isTesting = false;
    isLedOn = false; // Prevent sending multiple ON messages
    
    ledIndex = 0;
    currentStripNum = 1;
    previousStripNum = currentStripNum;
    ledTimeDelta = 0.0;
    
    // TODO: assign pixels for the full setup (all the channels)iter
    // TODO: Make pixels private and declare a getter
    pixels.assign(numLedsPerStrip, ofColor(0,0,0));
}

Animator::~Animator(void) {
    cout << "Animator destroyed" << endl;
}

void Animator::setNumLedsPerStrip(int num) {
    ofLogNotice("Setting up Animator");
    numLedsPerStrip = num;
    vector <ofColor> pix;
    pix.assign(numLedsPerStrip, ofColor(0,0,0));
    pixels = pix;
}

void Animator::setNumStrips(int num) {
    numStrips = num;
}

// Update the pixels for all the strips
// This method does not return the pixels, it's up to the users to send animator.pixels to the driver (FadeCandy, PixelPusher).
void Animator::chaseAnimationOn() {
    ofLogVerbose("LED") << "Animation ON: " << ofToString(ofGetElapsedTimef());
    ledTimeDelta = ofGetElapsedTimef();
    // Chase animation
    // Set the colors of all LEDs on the current strip
    
    if (!isLedOn) {
        for (int i = 0; i <  numLedsPerStrip; i++) {
            ofColor col;
            if (i == ledIndex) {
                col = ofColor(ledBrightness, ledBrightness, ledBrightness);
            }
            else {
                col = ofColor(0, 0, 0);
            }
            pixels.at(i) = col;
        }
    }
    isLedOn = true;
}

void Animator::chaseAnimationOff()
{
    if (isLedOn) {
        if (currentStripNum != previousStripNum) {

            previousStripNum = currentStripNum;
        }
        
        ledTimeDelta = ofGetElapsedTimef()-ledTimeDelta;
        ofLogVerbose("LED") << "Animation OFF, duration: " << ofToString(ledTimeDelta);
        
        ledIndex++;
        if (ledIndex == numLedsPerStrip) {
            for (int i = 0; i <  numLedsPerStrip; i++) {
                ofColor col;
                col = ofColor(0, 0, 0);
                pixels.at(i) = col;
            }
            
            ledIndex = 0;
            previousStripNum = currentStripNum;
            currentStripNum++;
        }
        
        // TODO: review this conditional
        if (currentStripNum > numStrips) {
            isMapping = false;
        }
        
        isLedOn = false;
    }
    
}


// Set all LEDs to the same colour (useful to turn them all on or off).
void Animator::setAllLEDColours(ofColor col) {
    for (int i = 0; i <  numLedsPerStrip; i++) {
        pixels.at(i) = col;
    }
    for (int i = 1; i <= numStrips; i++) {
        //opcClient.writeChannel(i, pixels);
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
        isTesting = false;
    }
    
}
