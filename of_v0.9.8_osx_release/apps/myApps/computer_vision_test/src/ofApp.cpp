#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup()
{
    ofSetFrameRate(60);
    effect = 3;
    
    ledIndex = 0;
    numLeds = 50;
    // Set up the color vector, with all LEDs set to off(black)
    pixels.assign(numLeds, ofColor(88,12,0));
    
    // Connect to the fcserver
    opcClient.setup("192.168.0.211", 7890);
    
    // You define the stage size and draw into the stage
    //opcClient.setupStage(500, 500);
    
    //defaultEffects.setup(opcClient.getStageCenterX(), opcClient.getStageCenterY(), opcClient.getStageWidth(), opcClient.getStageHeight());
    
    //stick.setupLedStrip(0, 0, 50, 7);
}
//--------------------------------------------------------------
void ofApp::update()
{
    ofSetWindowTitle("example_ofxNeoPixelStrips");
    
    opcClient.update();
    
    // If the client is not connected do not try and send information
    if (!opcClient.isConnected()) {
        // Will continue to try and reconnect to the Pixel Server
        opcClient.tryConnecting();
    }
    // TODO: Look into why opcClient isConnected is returning false
//    else {
//        // Write out the first set of data
//        //opcClient.writeChannelOne(stick.colorData());
//        cout << "OPC Not Connected \n";
//        opcClient.writeChannel(1, pixels);
//        
//    }
    
    // Chase animation
    for (int i = 0; i <  numLeds; i++) {
        ofColor col;
        if (i == ledIndex) {
            col = ofColor(255, 255, 255);
        }
        else {
            col = ofColor(0, 0, 0);
        }
        pixels.at(i) = col;
    }

    opcClient.writeChannel(1, pixels);
    
    
    ledIndex++;
    if (ledIndex >= numLeds) ledIndex = 0;
    
}
//--------------------------------------------------------------
void ofApp::draw()
{
    ofBackground(0);
    //opcClient.drawStage(hide);
    
    
    // Show the grabber area
    //stick.drawGrabRegion(hide);
    
    // Draw the output
    //stick.draw(opcClient.getStageWidth()+25, 10);
    
    // Report Messages
    stringstream ss;
    ss << "Press Left and Right to Change Effect Mode" << endl;
    ss << "FPS: " << ofToString((int)(ofGetFrameRate())) << endl;
    ofDrawBitmapStringHighlight(ss.str(), 5,ofGetHeight()-30);
    
}
//--------------------------------------------------------------
void ofApp::keyPressed(int key)
{
    if (key == OF_KEY_LEFT) {
        effect--;
    }
    if (key == OF_KEY_RIGHT) {
        effect++;
    }
    if (key == ' ') {
        hide = !hide;
    }
}
//--------------------------------------------------------------
void ofApp::keyReleased(int key)
{
    
}
//--------------------------------------------------------------
void ofApp::exit()
{
    // Close Connection
    opcClient.close();
}
