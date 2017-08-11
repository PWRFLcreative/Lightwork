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
    
    // OpenCV
    vidGrabber.setVerbose(true);
    vidGrabber.setup(320,240);
    
    colorImg.allocate(320,240);
    grayImage.allocate(320,240);
    grayBg.allocate(320,240);
    grayDiff.allocate(320,240);
    
    bLearnBakground = true;
    threshold = 80;
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
    
    // OpenCV
    bool bNewFrame = false;
    
    vidGrabber.update();
    bNewFrame = vidGrabber.isFrameNew();
    
    if (bNewFrame){
        colorImg.setFromPixels(vidGrabber.getPixels());
        
        
        grayImage = colorImg;
        if (bLearnBakground == true){
            grayBg = grayImage;		// the = sign copys the pixels from grayImage into grayBg (operator overloading)
            bLearnBakground = false;
        }
        
        // take the abs value of the difference between background and incoming and then threshold:
        grayDiff.absDiff(grayBg, grayImage);
        grayDiff.threshold(threshold);
        
        // find contours which are between the size of 20 pixels and 1/3 the w*h pixels.
        // also, find holes is set to true so we will get interior contours as well....
        contourFinder.findContours(grayDiff, 20, (340*240)/3, 10, true);	// find holes
    }
}
//--------------------------------------------------------------
void ofApp::draw()
{
    ofBackground(0);
    // draw the incoming, the grayscale, the bg and the thresholded difference
    ofSetHexColor(0xffffff);
    colorImg.draw(20,20);
    grayImage.draw(360,20);
    grayBg.draw(20,280);
    grayDiff.draw(360,280);
    
    // then draw the contours:
    
    ofFill();
    ofSetHexColor(0x333333);
    ofDrawRectangle(360,540,320,240);
    ofSetHexColor(0xffffff);
    
    // we could draw the whole contour finder
    //contourFinder.draw(360,540);
    
    // or, instead we can draw each blob individually from the blobs vector,
    // this is how to get access to them:
    for (int i = 0; i < contourFinder.nBlobs; i++){
        contourFinder.blobs[i].draw(360,540);
        
        // draw over the centroid if the blob is a hole
        ofSetColor(255);
        if(contourFinder.blobs[i].hole){
            ofDrawBitmapString("hole",
                               contourFinder.blobs[i].boundingRect.getCenter().x + 360,
                               contourFinder.blobs[i].boundingRect.getCenter().y + 540);
        }
    }
    
    // finally, a report:
    ofSetHexColor(0xffffff);
    stringstream reportStr;
    reportStr << "bg subtraction and blob detection" << endl
    << "press ' ' to capture bg" << endl
    << "threshold " << threshold << " (press: +/-)" << endl
    << "num blobs found " << contourFinder.nBlobs << ", fps: " << ofGetFrameRate();
    ofDrawBitmapString(reportStr.str(), 20, 600);
    
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
