#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    ofSetFrameRate(15);
    
    // Input
    cam.listDevices();
    cam.setDeviceID(1); // External webcam
    cam.setup(640, 480);
    
    
    // GUI
    gui.setup();
    gui.add(resetBackground.set("Reset Background", false));
    gui.add(learningTime.set("Learning Time", 1.2, 0, 30));
    gui.add(thresholdValue.set("Threshold Value", 53, 0, 255));
    
    // Contours
    contourFinder.setMinAreaRadius(1);
    contourFinder.setMaxAreaRadius(100);
    contourFinder.setThreshold(15);
    // wait for half a frame before forgetting something
    contourFinder.getTracker().setPersistence(15);
    // an object can move up to 32 pixels per frame
    contourFinder.getTracker().setMaximumDistance(32);
    
    
    // LED
    
    ledIndex = 0;
    numLeds = 51;
    ledBrightness = 100;
    isMapping = false;
    
    // Set up the color vector, with all LEDs set to off(black)
    pixels.assign(numLeds, ofColor(0,0,0));
    setAllLEDColours(ofColor(0, 0,0));
    
    // Connect to the fcserver
    opcClient.setup("192.168.1.104", 7890);
//    opcClient.setup("127.0.0.1", 7890);
    opcClient.sendFirmwareConfigPacket();
    
    // SVG
    svg.setViewbox(0, 0, 640, 480);
}

//--------------------------------------------------------------
void ofApp::update(){
    opcClient.update();
    
    // If the client is not connected do not try and send information
    if (!opcClient.isConnected()) {
        // Will continue to try and reconnect to the Pixel Server
        opcClient.tryConnecting();
    }
    
    cam.update();
    if(resetBackground) {
        background.reset();
        resetBackground = false;
    }
    
    // TODO: turn on LED here
    if(cam.isFrameNew()) {
        // Light up a new LED for every frame
        if (isMapping) {
            chaseAnimation();
        }
        // Background subtraction
        background.setLearningTime(learningTime);
        background.setThresholdValue(thresholdValue);
        background.update(cam, thresholded);
        thresholded.update();
        
        // Contour
        ofxCv::blur(thresholded, 10);
        contourFinder.findContours(thresholded);
        // TODO: Turn off LED here
        
        // We have 1 contour
        if (contourFinder.size() < 2 ) {
            ofLogNotice("Detected one contour, as expected.");
            ofPoint center = ofxCv::toOf(contourFinder.getCenter(0));
            centroids.push_back(center);
        }
        // We have more than 1 contour, deal with it.
        else {
            ofLogNotice("Detected more contours than needed.");
            for(int i = 0; i < contourFinder.size(); i++) {
                ofLogNotice("num contours: " + ofToString(contourFinder.size()));
            }
        }
    }
    
    ofSetColor(ofColor::white);
}

//--------------------------------------------------------------
void ofApp::draw(){
    cam.draw(0, 0);
    if(thresholded.isAllocated()) {
        thresholded.draw(640, 0);
    }
    gui.draw();
    
    ofxCv::RectTracker& tracker = contourFinder.getTracker();
    
    ofSetColor(0, 255, 0);
    //movie.draw(0, 0);
    contourFinder.draw(); // Draws the blob rect surrounding the contour
    
    // Draw the detected contour center points
    for (int i = 0; i < centroids.size(); i++) {
        ofDrawCircle(centroids[i].x, centroids[i].y, 3);
    }
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    switch (key){
        case ' ':
            centroids.clear();
            break;
        case '+':
            threshold ++;
            cout << "Threshold: " << threshold;
            if (threshold > 255) threshold = 255;
            break;
        case '-':
            threshold --;
            cout << "Threshold: " << threshold;
            if (threshold < 0) threshold = 0;
            break;
        case 's':
            isMapping = true;
            break;
        case 'g':
            generateSVG(centroids);
        case 'j':
            generateJSON(centroids);
    }

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}

// Cycle through all LEDs, return false when done
void ofApp::chaseAnimation()
{
    // Chase animation
    for (int i = 0; i <  numLeds; i++) {
        ofColor col;
        if (i == ledIndex) {
            col = ofColor(ledBrightness, ledBrightness, ledBrightness);
        }
        // wait a bit if this is the last LED
        //else if (i == numLeds) {
        
        //}
        else {
            col = ofColor(0, 0, 0);
        }
        pixels.at(i) = col;
    }
    
    opcClient.writeChannel(1, pixels);
    
    ledIndex++;
    if (ledIndex >= numLeds) {
        ledIndex = 0;
        setAllLEDColours(ofColor(0, 0, 0));
        isMapping = false;
    }
}

// Set all LEDs to the same colour (useful to turn them all on or off).
void ofApp::setAllLEDColours(ofColor col) {
    // Chase animation
    for (int i = 0; i <  numLeds; i++) {
        pixels.at(i) = col;
    }
    opcClient.writeChannel(1, pixels);
}

void ofApp::generateSVG(vector <ofPoint> points) {
    ofPath path;
    for (int i = 0; i < points.size(); i++) {
        path.lineTo(points[i]);
        cout << points[i].x;
        cout << ", ";
        cout << points[i].y;
        cout << "\n";
    }
    svg.addPath(path);
    path.draw();
    svg.save("mapper-test-new.svg");
}

void ofApp::generateJSON(vector<ofPoint> points) {
    /*
     [
     {"point": [1.32, 0.00, 1.32]},
     {"point": [1.32, 0.00, 1.21]}
     ]
     */
    
    int maxX = ofToInt(svg.info.width);
    int maxY = ofToInt(svg.info.height);
    cout << maxX;
    cout << maxY;
    
    ofxJSONElement json; // For output
    
    for (int i = 0; i < points.size(); i++) {
        Json::Value event;
        Json::Value vec(Json::arrayValue);
        vec.append(Json::Value(points[i].x/maxX)); // Normalized
        vec.append(Json::Value(0.0)); // Normalized
        vec.append(Json::Value(points[i].y/maxY));
        event["point"]=vec;
        json.append(event);
    }
    
    json.save("testLayout.json");
    
}
