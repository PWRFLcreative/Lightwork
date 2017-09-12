#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    // Set the log level
    ofSetLogLevel(OF_LOG_VERBOSE);
    
    ofLogToConsole();
    int framerate = 20; // Used to set oF and camera framerate
    ofSetFrameRate(framerate);
	ofBackground(0, 0, 0);

	IP = "192.168.1.104"; //Default IP for Fadecandy
    
	//Video Devices
	enumerateCams();
    cam.setDeviceID(1); // Default to external camera
	cam.setup(640, 480);
	cam.setDesiredFrameRate(30); // This gets overridden by ofSetFrameRate


	// GUI - OLD
	//gui.setup();
	//resetBackground.set("Reset Background", false);
	learningTime.set("Learning Time", 1.3, 0, 30);
	thresholdValue.set("Threshold Value", 50, 0, 255);

    
    // Contours
    contourFinder.setMinAreaRadius(1);
    contourFinder.setMaxAreaRadius(100);
    contourFinder.setThreshold(15);
    // wait for half a frame before forgetting something (15)
    contourFinder.getTracker().setPersistence(1);
    // an object can move up to 32 pixels per frame
    contourFinder.getTracker().setMaximumDistance(32);
    contourFinder.getTracker().setSmoothingRate(1.0);
    
    // Allocate the thresholded view so that it draws on launch (before calibration starts).
    thresholded.allocate(640, 480, OF_IMAGE_COLOR);
    
    // LED
    
    ledIndex = 0;
    numLedsPerStrip = 50; // TODO: Change name to ledsPerStrip or similar
    ledBrightness = 250;
    isMapping = false;
	isTesting = false;
    isLedOn = false; // Prevent sending multiple ON messages
    numStrips = 3;
    currentStripNum = 1;
    previousStripNum = currentStripNum;
    // Handle 'skipped' LEDs. This covers LEDs that are not visible (and shouldn't be, because reasons... something something hardware... hacky... somthing...)
    hasFoundFirstContour = false;
    ledTimeDelta = 0.0;
    
    // Set up the color vector, with all LEDs set to off(black)
    pixels.assign(numLedsPerStrip, ofColor(0,0,0));
    
    // Connect to the fcserver
    opcClient.setup(IP, 7890, 1, numLedsPerStrip);
    opcClient.sendFirmwareConfigPacket();
    setAllLEDColours(ofColor(0, 0,0));
    
    // SVG
    svg.setViewbox(0, 0, 640, 480);

	//GUI
	buildUI();
}

//--------------------------------------------------------------
void ofApp::update(){
    opcClient.update();
    
    // If the client is not connected do not try and send information
    if (!opcClient.isConnected()) {
        // Will continue to try connecting to the OPC Pixel Server
        opcClient.tryConnecting();
    }

	if (isTesting) {
		test(); // TODO: turn off blob detection while testing
	}

	cam.update();
    
    // New camera frame: Turn on a new LED and detect the location.
    // We are getting every third camera frame (to give the LEDs time to light up and the camera to pick it up).
    if(cam.isFrameNew() && !isTesting && isMapping && (ofGetFrameNum()%3 == 0)) {
        bool success = false; // Indicate if we successfully mapped an LED on this frame (visible or off-canvas)
        
        // Light up a new LED for every frame
        if (!isLedOn) {
            chaseAnimationOn();
        }
        
        // Background subtraction
        background.setLearningTime(learningTime);
        background.setThresholdValue(thresholdValue);
        background.update(cam, thresholded);
        thresholded.update();
        
        // Contour
        ofxCv::blur(thresholded, 10);
        contourFinder.findContours(thresholded);
        
        // We have 1 contour
        if (contourFinder.size() == 1 && isLedOn && !success) {
            ofLogVerbose("tracking") << "Detected one contour, as expected.";
            ofPoint center = ofxCv::toOf(contourFinder.getCenter(0));
            centroids.push_back(center);
            success = true;
        }
        
        // We have more than 1 contour, select the brightest one.
        else if (contourFinder.size() > 1 && isLedOn && !success){
            ofLogVerbose("tracking") << "num contours: " << ofToString(contourFinder.size());
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
                success = true;
                //ofLogNotice("Brightness: " + ofToString(brightness));
            }
            ofLogNotice() << "brightest index: " << ofToString(brightestIndex);
            ofPoint center = ofxCv::toOf(contourFinder.getCenter(brightestIndex));
            centroids.push_back(center);
            hasFoundFirstContour = true;
            ofLogVerbose("tracking") << "added point, ignored additional points. FrameCount: " << ofToString(ofGetFrameNum())+ " ledIndex: " << ofToString(ledIndex+(currentStripNum-1)*numLedsPerStrip);
        }
        
        // Deal with no contours found
        else if (isMapping && !success && hasFoundFirstContour){
            ofLogVerbose("tracking") << "NO CONTOUR FOUND!!!";
            
            // No point detected, create fake point
            ofPoint fakePoint;
            fakePoint.set(0, 0);
            centroids.push_back(fakePoint);
            success = true;
            ofLogVerbose("tracking") << "CREATING FAKE POINT                     at frame: " << ofToString(ofGetFrameNum()) << " ledIndex " << ofToString(ledIndex+(currentStripNum-1)*numLedsPerStrip);
        }
        
        if(isMapping && success) {
            hasFoundFirstContour = true;
            chaseAnimationOff(); // TODO: this is redundant, see above else if
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
            isMapping = !isMapping;
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

    opcClient.writeChannel(currentStripNum, pixels);
    
    if (currentStripNum != previousStripNum) {
        for (int i = 0; i <  numLedsPerStrip; i++) {
            ofColor col;
            
            col = ofColor(0, 0, 0);
            
            pixels.at(i) = col;
        }
        opcClient.writeChannel(previousStripNum, pixels);
        previousStripNum = currentStripNum;
    }
    isLedOn = true;
}

void ofApp::chaseAnimationOff()
{
    if (isLedOn) {
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
void ofApp::setAllLEDColours(ofColor col) {
    for (int i = 0; i <  numLedsPerStrip; i++) {
        pixels.at(i) = col;
    }
    for (int i = 1; i <= numStrips; i++) {
        opcClient.writeChannel(i, pixels);
    }
    
}

//LED Pre-flight test
void ofApp::test() {
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

void ofApp::generateSVG(vector <ofPoint> points) {
    ofPath path;
    for (int i = 0; i < points.size(); i++) {
        // Avoid generating a moveTo AND lineTo for the first point
        // If we don't specify the first moveTo message then the first lineTo will also produce a moveTo point with the same coordinates
        if (i == 0) {
            path.moveTo(points[i]);
        }
        else {
           path.lineTo(points[i]);
        }
        ofLogVerbose("output") << points[i].x << ", "<< points[i].y;
    }
    svg.addPath(path);
    path.draw();
    svg.save("layout.svg");
    ofLogNotice("output") << "Saved SVG file.";
}

void ofApp::generateJSON(vector<ofPoint> points) {
    int maxX = ofToInt(svg.info.width);
    int maxY = ofToInt(svg.info.height);
    ofLogNotice("output") << "maxX, maxY: " << maxX << ", " << maxY;
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
    ofLogNotice("output") << "Saved JSON file.";
}

/*
 I'm expecting a series of 2D points. I need to filter out points that are too close together, but keep
 negative points. The one that are negative represent 'invisible' or 'skipped' LEDs that have a physical presence
 in an LED strip but are not visuable. We need to store them 'off the canvas' so that our client application (Lightwork Scraper) can be aware of the missing LEDs (as they are treated sequentially, with no 'fixed' address mapping.
 IDEA: Can we store the physical address as the 'z' in a Vec3 or otherwise encode it in the SVG. Maybe we can make another
 'path' in the SVG that stores the address in a path of the same length.
 */
vector <ofPoint> ofApp::removeDuplicatesFromPoints(vector <ofPoint> points) {
    ofLogNotice("tracking") << "Removing duplicates";
    
    float thresh = 3.0; // TODO: Add interface to GUI
    
    std::vector<ofPoint>::iterator iter;
    
    // Iterate through all the points and remove duplicates and 'extra' points (under threshold distance).
    for (iter = points.begin(); iter < points.end(); iter++) {
        int i = std::distance(points.begin(), iter); // Index of iter, used to avoid comporating a point to itself
        ofPoint pt = *iter;
        ofLogVerbose("tracking") << "BASE: " << pt << endl;
        
        // Do not remove 0,0 points (they're 'invisible' LEDs, we need to keep them).
        if (pt.x == 0 && pt.y == 0) {
            continue; // Go to the next iteration
        }
        
        // Compare point to all other points
        std::vector<ofPoint>::iterator j_iter;
        for (j_iter = points.begin(); j_iter < points.end(); j_iter++) {
            int j = std::distance(points.begin(), j_iter); // Index of j_iter
            ofPoint pt2 = *j_iter;
            ofLogVerbose("tracking") << "NESTED: " << pt2 << endl;
            float dist = pt.distance(pt2);
            ofLogVerbose("tracking") << "DISTANCE: " << dist << endl;
            ofLogVerbose("tracking") << "i: " << i << " j: " << j << endl;
            // Comparing point to itself... do nothing and move on.
            if (i == j) {
                ofLogVerbose("tracking") << "COMPARING POINT TO ITSELF " << pt << endl;
                continue; // Move on to the next j point
            }
            // Duplicate point detection. (This might be covered by the distance check below and therefor redundant...)
            else if (pt.x == pt2.x && pt.y == pt2.y) {
                ofLogVerbose("tracking") << "FOUND DUPLICATE POINT (that is not 0,0) - removing..." << endl;
                iter = points.erase(iter);
                break;
            }
            // Check point distance, remove points that are too close
            else if (dist < thresh) {
                ofLogVerbose("tracking") << "REMOVING" << endl;
                iter = points.erase(iter);
                break;
            }
        }
    }
    
    return points;
}

//Dropdown Handler
void ofApp::onDropdownEvent(ofxDatGuiDropdownEvent e)
{
	cout << "the option at index # " << e.child << " was selected " << endl;

	if (e.target->is("Select Camera")) {
		enumerateCams();
		gui->getDropdown("Select Camera")->update(); //TODO : Not working
		gui->update();
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


void ofApp::onSliderEvent(ofxDatGuiSliderEvent e)
{
		cout << "onSliderEvent: " << e.target->getLabel() << " "; e.target->printValue(); //TODO: stop from spamming output

}

void ofApp::onTextInputEvent(ofxDatGuiTextInputEvent e)
{
	cout << "onTextInputEvent: " << e.target->getLabel() << " " << e.target->getText() << endl;

	if (e.target->is("IP")) {
		IP= e.target->getText();
		opcClient.setup(IP, 7890);
	}

	if (e.target->is("LEDS")) {
		string temp = e.target->getText();
		numLedsPerStrip = ofToInt(temp);
	}
}

void ofApp::onButtonEvent(ofxDatGuiButtonEvent e)
{
	cout << "onButtonEvent: " << e.target->getLabel() << endl;

	if (e.target->is("TEST LEDS")) {
		isTesting = true;
	}
	if (e.target->is("MAP LEDS")) {
		isMapping = true;
	}
	if (e.target->is("SAVE LAYOUT")) {
		centroids = removeDuplicatesFromPoints(centroids);
		generateSVG(centroids);
	}

}


void ofApp::switchCamera(int num)
{
    ofLogNotice("Switching camera");
    cam.listDevices();
	cam.setDeviceID(num);
	cam.setup(640, 480);
}

vector<string> ofApp::enumerateCams()
{
	vector <ofVideoDevice> devices;
	devices = cam.listDevices();
	vector<string> deviceStrings;

	for (std::vector<ofVideoDevice>::iterator it = devices.begin(); it != devices.end(); ++it) {
		int i = std::distance(devices.begin(), it);
		ofVideoDevice device = *it;
		string name = device.deviceName;
		int id = device.id;
		cout << "Camera " << id << ": " <<  name << endl;
		//newStrings[i] = name;
		deviceStrings.push_back(name);

	}
	
	//deviceStrings = new vector<string>(newStrings);
	return deviceStrings;
}

void ofApp::buildUI()
{
	//GUI
	gui = new ofxDatGui(0,0);
	//gui->setTheme(new ofxDatGuiThemeCharcoal());
	gui->addDropdown("Select Camera", enumerateCams());
	gui->addBreak();

	vector<string> opts = { "PixelPusher", "Fadecandy/Octo" };
	gui->addDropdown("Select Driver Type", opts);
	gui->addBreak();

	gui->addTextInput("IP", IP);
	gui->addTextInput("LEDS", ofToString(numLedsPerStrip));
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
	gui->onSliderEvent(this, &ofApp::onSliderEvent);
	gui->onTextInputEvent(this, &ofApp::onTextInputEvent);
	//gui->on2dPadEvent(this, &ofApp::on2dPadEvent);
	gui->onDropdownEvent(this, &ofApp::onDropdownEvent);
	//gui->onColorPickerEvent(this, &ofApp::onColorPickerEvent);
	//gui->onMatrixEvent(this, &ofApp::onMatrixEvent);
}
