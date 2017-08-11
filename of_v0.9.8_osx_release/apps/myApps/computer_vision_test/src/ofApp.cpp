#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup()
{
    ofSetFrameRate(60);
    effect = 3;
    
    ledIndex = 0;
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
    
    // Now Draw the effects to the stage
    //opcClient.beginStage();
    
    // Draw what you want rendered here
    
    // For now here are some default effects
    //defaultEffects.draw(effect);
    
    //opcClient.endStage();
    
    // New Get Method
    //opcClient.getStagePixels(stick.getPixelCoordinates(), stick.colors);
    
    // If the client is not connected do not try and send information
    if (!opcClient.isConnected()) {
        // Will continue to try and reconnect to the Pixel Server
        opcClient.tryConnecting();
    }
    else {
        // Write out the first set of data
        opcClient.writeChannelOne(stick.colorData());
    }
    
    int numLeds = 50;
    
    for (int i = 0; i <  numLeds; i++) {
        ofColor col = ofColor(0, 0, 255);
        pixels.push_back(col);
    }
    
    opcClient.writeChannel(1, pixels);
    
    ledIndex++;
    
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
