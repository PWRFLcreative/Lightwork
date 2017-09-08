#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    int framerate = 30; // Used to set oF and camera framerate
    ofSetFrameRate(framerate);

	IP = "192.168.1.104";
    
    // Input
//    cam.listDevices();
//   cam.setDeviceID(1); // External webcam
//    cam.setup(640, 480);
//    cam.setDesiredFrameRate(framerate); // This gets overridden by ofSetFrameRate
    
	//Video Devices
	vector <ofVideoDevice> devices;
	devices = cam.listDevices();
	vector <string> deviceStrings;

	for (std::vector<ofVideoDevice>::iterator it = devices.begin(); it != devices.end(); ++it) {
		ofVideoDevice device = *it;
		string name = device.deviceName;
		int id = device.id;
		cout << "Device Name: " << id << name << endl;
		deviceStrings.push_back(name);
	}

	// Input
	//cam.setDeviceID(0); // External webcam
	cam.setup(1280, 720);
	cam.setDesiredFrameRate(30); // This gets overridden by ofSetFrameRate

	// GUI - OLD
	//gui.setup();
	//resetBackground.set("Reset Background", false);
	learningTime.set("Learning Time", 30, 0, 30);
	thresholdValue.set("Threshold Value", 10, 0, 255);

	//GUI
	ofxDatGui* gui = new ofxDatGui(ofxDatGuiAnchor::BOTTOM_LEFT);
	//gui->setTheme(new ofxDatGuiThemeCharcoal());

	gui->addDropdown("Select Camera", deviceStrings);
	gui->addBreak();

	vector<string> opts = { "PixelPusher", "Fadecandy/Octo" };
	gui->addDropdown("Select Driver Type", opts);
	gui->addBreak();

	gui->addTextInput("IP", IP);
	gui->addTextInput("LEDS", "150");
	gui->addBreak();

	ofxDatGuiFolder* folder = gui->addFolder("Mapping Settings", ofColor::white);
	folder->addSlider(learningTime);
	folder->addSlider(thresholdValue);
	folder->addButton("Test LEDS");
	folder->addButton("Map LEDS");
	//gui->addButton(resetBackground);
	folder->addButton("Save Layout");
	folder->expand();
	folder->addBreak();

	gui->addFRM();

	gui->addHeader(":: drag me to reposition ::");
	gui->addFooter();

	// once the gui has been assembled, register callbacks to listen for component specific events //
	gui->onButtonEvent(this, &ofApp::onButtonEvent);
	//gui->onToggleEvent(this, &ofApp::onToggleEvent);
	//gui->onSliderEvent(this, &ofApp::onSliderEvent);
	gui->onTextInputEvent(this, &ofApp::onTextInputEvent);
	//gui->on2dPadEvent(this, &ofApp::on2dPadEvent);
	gui->onDropdownEvent(this, &ofApp::onDropdownEvent);
	//gui->onColorPickerEvent(this, &ofApp::onColorPickerEvent);
	//gui->onMatrixEvent(this, &ofApp::onMatrixEvent);
    
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
    opcClient.setup(IP, 7890);
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
    //if(resetBackground) {
    //    background.reset();
    //    resetBackground = false;
    //}

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
    //gui.draw();
    
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

//Dropdown Handler
void ofApp::onDropdownEvent(ofxDatGuiDropdownEvent e)
{
	cout << "the option at index # " << e.child << " was selected " << endl;

	if (e.target->is("Select Camera")) {
		switchCamera(e.child);
	}

	if (e.target->is("Select Driver Type")) {
		if (e.child == 0) {
			cout << "Pixel Pusher was selected" << endl;
		}
		else if (e.child == 1) {
			cout << "Fadecandy/Octo was selected" << endl;
		}
	}
}


void ofApp::onTextInputEvent(ofxDatGuiTextInputEvent e)
{
	cout << "onTextInputEvent: " << e.target->getLabel() << " " << e.target->getText() << endl;

	if (e.target->is("IP")) {
		IP= e.target->getText();
		opcClient.setup(IP, 7890);
	}
}

void ofApp::onButtonEvent(ofxDatGuiButtonEvent e)
{
	cout << "onButtonEvent: " << e.target->getLabel() << endl;
}


void ofApp::switchCamera(int num)
{
	cam.close();
	cam.setDeviceID(num);
	cam.setup(1280, 720);
}
