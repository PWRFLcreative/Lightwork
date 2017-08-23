#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    int framerate = 5; // Used to set oF and camera framerate
    ofSetFrameRate(framerate);
    
    // Input
    cam.listDevices();
    cam.setDeviceID(1); // External webcam
    cam.setup(640, 480);
    cam.setDesiredFrameRate(framerate); // This gets overridden by ofSetFrameRate
    
    // GUI
    gui.setup();
    gui.add(resetBackground.set("Reset Background", false));
    gui.add(learningTime.set("Learning Time", 1.2, 0, 30));
    gui.add(thresholdValue.set("Threshold Value", 53, 0, 255)); //TODO: update at runtime
    
    // Contours
    contourFinder.setMinAreaRadius(1);
    contourFinder.setMaxAreaRadius(100);
    contourFinder.setThreshold(15);
    // wait for half a frame before forgetting something (15)
    contourFinder.getTracker().setPersistence(1);
    // an object can move up to 32 pixels per frame
    contourFinder.getTracker().setMaximumDistance(32);
    contourFinder.getTracker().setSmoothingRate(1.0);
    
    
    // LED
    
    ledIndex = 0;
    numLeds = 50;
    ledBrightness = 200;
    isMapping = false;
	isTesting = false;
    isLedOn = false; // Prevent sending multiple ON messages
    
    // Set up the color vector, with all LEDs set to off(black)
    pixels.assign(numLeds, ofColor(0,0,0));
    
    
    // Connect to the fcserver
    opcClient.setup("192.168.1.104", 7890);
//    opcClient.setup("127.0.0.1", 7890);
    opcClient.sendFirmwareConfigPacket();
    setAllLEDColours(ofColor(0, 0,0));
    
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

	if (isTesting) {
		test(); // TODO: turn off blob detection while testing - also find source of delay
	}

	cam.update();
    if(resetBackground) {
        background.reset();
        resetBackground = false;
    }

    if (isMapping && !isLedOn) {
        chaseAnimationOn();
    }
    if(cam.isFrameNew() && !isTesting && isMapping) {
        // Light up a new LED for every frame
        bool success = false; // Indicate if we successfully mapped an LED on this frame
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
        if (contourFinder.size() == 1 && isLedOn) {
//            ofLogNotice("Detected one contour, as expected.");
            ofPoint center = ofxCv::toOf(contourFinder.getCenter(0));
            centroids.push_back(center);
            success = true;
            ofLogNotice("added point (only found 1)");
        }
        // We have more than 1 contour, select the brightest one.
        
        else if (contourFinder.size() > 1 && isLedOn){
            //ofLogNotice("num contours: " + ofToString(contourFinder.size()));
            int brightestIndex = 0;
            int previousBrightness = 0;
            for(int i = 0; i < contourFinder.size(); i++) {
                int brightness = 0;
                cv::Rect rect = contourFinder.getBoundingRect(i);
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
                
                //ofLogNotice("Brightness: " + ofToString(brightness));
            }
            //ofLogNotice("brightest index: " + ofToString(brightestIndex));
            ofPoint center = ofxCv::toOf(contourFinder.getCenter(brightestIndex));
            centroids.push_back(center);
            success = true;
            ofLogNotice("added point, ignored additional points");
        }
        // Deal with no contours found
        
        else if (isMapping && !success && isLedOn){
            // This doesn't care if we're trying to find a contour or not, it goes in here by default
            ofLogNotice("NO CONTOUR FOUND!!!");
            //chaseAnimationOn();
        }
        
        if(isMapping && success) {
            chaseAnimationOff();
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
//    if (isMapping) {
//        ofSaveFrame();
//    }
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    switch (key){
        case ' ':
            centroids.clear();
            break;
        case '+':
		case '=':
            threshold ++;
            cout << "Threshold: " << threshold;
            if (threshold > 255) threshold = 255;
            break;
        case '-':
		case '_':
            threshold --;
            cout << "Threshold: " << threshold;
            if (threshold < 0) threshold = 0;
            break;
        case 's':
            isMapping = true;
            break;
        case 'g':
            generateSVG(centroids);
            break;
        case 'j':
            generateJSON(centroids);
            break;
		case 't':
			isTesting = true;
			break;
        case 'f': // filter points
            centroids = removeDuplicatesFromPoints(centroids);
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
void ofApp::chaseAnimationOn()
{
    ofLogNotice("animation: ON");
    // Chase animation
    for (int i = 0; i <  numLeds; i++) {
        ofColor col;
        if (i == ledIndex) {
            col = ofColor(ledBrightness, ledBrightness, ledBrightness);
        }
        else {
            col = ofColor(0, 0, 0);
        }
        pixels.at(i) = col;
    }
    
    opcClient.writeChannel(1, pixels);
    
    isLedOn = true;
}

void ofApp::chaseAnimationOff()
{
    ofLogNotice("animation: OFF");
    
    ledIndex++;
    if (ledIndex > numLeds) {
        ledIndex = 0;
        setAllLEDColours(ofColor(0, 0, 0));
        isMapping = false;
    }
    isLedOn = false;
}
// Set all LEDs to the same colour (useful to turn them all on or off).
void ofApp::setAllLEDColours(ofColor col) {
    for (int i = 0; i <  numLeds; i++) {
        pixels.at(i) = col;
    }
    opcClient.writeChannel(1, pixels);
}

//LED Pre-flight test
void ofApp::test() {
	//ofSetFrameRate(1);
	setAllLEDColours(ofColor(255, 0, 0));
	ofSleepMillis(2000);
	setAllLEDColours(ofColor(0, 255, 0));
	ofSleepMillis(2000);
	setAllLEDColours(ofColor(0, 0, 255));
	ofSleepMillis(2000);
	setAllLEDColours(ofColor(0, 0, 0));
	//ofSetFrameRate(30);
	ofSleepMillis(3000); // wait to stop blob detection - remove when cam algorithm changed
	isTesting = false;
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
    svg.save("mapper-test-tilted.svg");
}

void ofApp::generateJSON(vector<ofPoint> points) {
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

vector <ofPoint> ofApp::removeDuplicatesFromPoints(vector <ofPoint> points) {
    
    vector <ofPoint> filtered;
    
    float thresh = 5.0;
    for (int i = 0; i < points.size(); i++) {
        float dist = points[i].distance(points[i-1]);
        ofLogNotice("distance: "+ofToString(dist));
        if (dist > thresh) {
            filtered.push_back(points[i]);
        }
        else {
            ofLogNotice("distance below threshold, removing point. distance: " + ofToString(dist));
        }
  
    }
    
    return filtered;
}
