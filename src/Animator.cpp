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
    ledBrightness = 255;
    numStrips = 8;
    ledIndex = 0; // Internal counter
    mode = ANIMATION_MODE_CHASE;
    
    testIndex = 0;
    frameCount = 0;

    populateLeds();
}

// Destructor
Animator::~Animator(void) {
    cout << "Animator destroyed" << endl;
}

//////////////////////////////////////////////////////////////
// Setters and getters
//////////////////////////////////////////////////////////////
void Animator::setLedInterface(ofxOPC *interface) {
    opcClient = interface;
}

void Animator::setMode(animation_mode_t m) {
    mode = m;
    ledIndex = 0; // TODO: resetInternalVariables() method?
    testIndex = 0;
    frameCount = 0;
    resetPixels();
}

void Animator::setLedBrightness(int brightness) {
    ledBrightness = brightness;
    opcClient->autoWriteData(getPixels());
}

void Animator::setNumLedsPerStrip(int num) {
    ofLogNotice("animator") << "setNumLedsPerStrip(): " << num;
    numLedsPerStrip = num;
    
    // Update OPC client
    opcClient->setLedsPerStrip(numLedsPerStrip);
    
    // Reset LEDs vector
    resetPixels();
}

int Animator::getNumLedsPerStrip() {
    return numLedsPerStrip;
}

void Animator::setNumStrips(int num) {
    ofLogNotice("animator") << "setNumStrips(): " << num;
    numStrips = num;
    resetPixels();
}

int Animator::getNumStrips() {
    return numStrips;
}

// Internal method to reassign pixels with a vector of the right length. Gives all pixels a value of (0,0,0) (black/off).
void Animator::resetPixels() {
    populateLeds();
}

// Return pixels (to update OPC or PixelPusher)
vector <ofColor> Animator::getPixels() {
    vector <ofColor> pixels;
    for (int i = 0; i<leds.size(); i++) {
        pixels.push_back(leds[i].color);
    }
    return pixels;
}

// Reset the LED vector
void Animator::populateLeds() {
    
    int bPatOffset = 150; // Offset to get more meaningful patterns (and avoid 000000000);
    int numLeds = numLedsPerStrip*numStrips;
    ofLogNotice("animator") << "populateLeds() -> numLeds: " << numLeds;
    
    leds.clear();
    for (int i = 0; i < numLeds; i++) {
        leds.push_back(LED());
        leds[i].setAddress(i);
        leds[i].binaryPattern.generatePattern(i+bPatOffset); // Generate a unique binary pattern for each LED
    }
}


//////////////////////////////////////////////////////////////
// Animation Methods
//////////////////////////////////////////////////////////////

void Animator::update() {
    switch(mode) {
        case ANIMATION_MODE_CHASE: {
            chase();
            break;
        }
        case ANIMATION_MODE_TEST: {
            test();
            break;
        }
        case ANIMATION_MODE_BINARY: {
            binaryAnimation();
        }
    };
    // Advance the internal counter
    frameCount++;
    
    // Update pixels on external interface
    opcClient->autoWriteData(this->getPixels()); // Send pixel values to OPC

}
// Update the pixels for all the strips
// This method does not return the pixels, it's up to the users to send animator.pixels to the driver (FadeCandy, PixelPusher).
void Animator::chase() {
    for (int i = 0; i <  numLedsPerStrip*numStrips; i++) {
        ofColor col;
        if (i == ledIndex) {
            col = ofColor(ledBrightness, ledBrightness, ledBrightness);
        }
        else {
            col = ofColor(0, 0, 0);
        }
        leds.at(i).color = col;
    }
    
    ledIndex++;
    if (ledIndex == numLedsPerStrip+numLedsPerStrip*numStrips) {
        ledIndex = 0;
    }
}

// Set all LEDs to the same colour (useful to turn them all on or off).
void Animator::setAllLEDColours(ofColor col) {
    for (int i = 0; i <  numLedsPerStrip*numStrips; i++) {
        leds.at(i).color = col;
    }
}

//LED Pre-flight test
void Animator::test() {
    testIndex++;
    
    if (testIndex < 30) {
        setAllLEDColours(ofColor(255, 0, 0));
    }
    else if (testIndex > 30 && testIndex < 60) {
        setAllLEDColours(ofColor(0, 255, 0));
    }
    else if (testIndex > 60 && testIndex < 90) {
        setAllLEDColours(ofColor(0, 0, 255));
    }
    
    if (testIndex > 90) {
        testIndex = 0;
    }
}

void Animator::binaryAnimation() {
    // LED binary state. START -> GREEN, HIGH -> BLUE, LOW -> RED, OFF -> (off)
    
    // Slow down the animation, set new state every 3 frames
    if (frameCount % 5 == 0) {
//        cout << leds.size() << endl;
        for (int i = 0; i < leds.size(); i++) {
                switch (leds[i].binaryPattern.state){ // 0
                    case BinaryPattern::LOW: {
                        leds.at(i).color = ofColor(ledBrightness, 0, 0); // RED
                        break;
                    }
                    case BinaryPattern::HIGH: { // 1
                        leds.at(i).color = ofColor(0, 0, ledBrightness); // BLUE
                        break;
                    }
                    case BinaryPattern::START: { // 2
                        leds.at(i).color = ofColor(0, ledBrightness, 0); // GREEN
                        break;
                    }
                    case BinaryPattern::OFF: { // 3
                        leds.at(i).color = ofColor(0, 0, 0); // BLACK
                        break;
                    }
                }
            
            leds[i].binaryPattern.advance();
        }
    }
}
