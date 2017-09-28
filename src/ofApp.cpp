#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    // Set the log level
    ofSetLogLevel("tracking", OF_LOG_VERBOSE);
	//Window size based on screen dimensions, centered
	
	ofSetWindowShape((int)ofGetScreenWidth()*0.9, ((int)ofGetScreenHeight())*0.9);
	ofSetWindowPosition((ofGetScreenWidth()/2)-ofGetWindowWidth()/2, ((int)ofGetScreenHeight() / 2) - ofGetWindowHeight() / 2);

    ofLogToConsole();

    int framerate = 20; // Used to set oF and camera framerate
    ofSetFrameRate(framerate);
	ofBackground(ofColor::black);
	ofSetWindowTitle("LightWork");
    
	//Video Devices
	cam.setVerbose(false);
    cam.listDevices();
    cam.setDeviceID(1); // Default to external camera (falls back on built in cam if external is not available)
    cam.setup(640, 480);
	cam.setDesiredFrameRate(framerate); // This gets overridden by ofSetFrameRate

    //Fbos
    camFbo.allocate(cam.getWidth(), cam.getHeight());
    camFbo.begin();
    ofClear(255, 255, 255);
    camFbo.end();
    
    tracker.setup(&cam);
    tracker.setMode(TRACKER_MODE_CHASE);
    
	// GUI - OLD
	//gui.setup();

	tracker.learningTime.set("Learning Time", 4, 0, 30);
	tracker.thresholdValue.set("Threshold Value", 50, 0, 255);

    // Contours
    
    // LED
	IP = "192.168.1.104"; //Default IP for Fadecandy
    
    // Connect to the fcserver
    opcClient.setup(IP, 7890, 1);
    opcClient.setInterpolation(false);
    
    // Animator settings
    animator.setLedInterface(&opcClient); // Setting a POINTER to the interface, so the Animator class can update pixels internally
    animator.setMode(ANIMATION_MODE_CHASE);
    animator.setNumLedsPerStrip(50); // This also updates numLedsPerStrip in the OPC Client
//    animator.setNumStrips(3); // TODO: this breaks the last strip!
    animator.setLedBrightness(150);
    animator.setAllLEDColours(ofColor(0, 0,0)); // Clear the LED strips
    
    // Mapping
    isMapping = false;
    
    // SVG
    svg.setViewbox(0, 0, cam.getWidth(), cam.getHeight());

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

	cam.update();
    
    if (animator.mode == ANIMATION_MODE_TEST) {
        animator.update(); // Update the pixel values
    }
    
    if (animator.mode == ANIMATION_MODE_BINARY && isMapping) { // Redundant, for  now...
        // Update LEDs and Tracker
        animator.update();
        tracker.update();
        
        for (int j=0; j < animator.binaryPatterns.size(); j++)
        {
            for (int i = 0; i < tracker.detectedPatterns.size(); i++)
            {
                
                size_t found = animator.binaryPatterns[i].binaryPatternString.find(tracker.detectedPatterns[j].binaryPatternString);
                if(found != string::npos) {
                    cout << "WE HAVE A MATCH!" << endl;
                }
                
//                if (tracker.detectedPatterns[i].binaryPatternString == animator.binaryPatterns[j].binaryPatternString)
//                {
//                    //inputlist[i] ="*";
//                    cout << "WE HAVE A MATCH!" << endl;
//                }
            }
        }
        // Pattern matching
//        if (tracker.detectedPattern.binaryPatternString == animator.binaryPattern.binaryPatternString) {
//            ofLogNotice("Match FOUND!!!");
//        }
    }
    
    // New camera frame: Turn on a new LED and detect the location.
    // We are getting every third camera frame (to give the LEDs time to light up and the camera to pick it up).
    
    if(animator.mode == ANIMATION_MODE_CHASE && cam.isFrameNew() && (animator.mode == ANIMATION_MODE_CHASE) && isMapping && (ofGetFrameNum()%3 == 0)) {
        // Make sure you call animator.update() once when you activate CHASE mode
        // We check if the tracker has found the first contour before processing with the animation
        // This makes sure we don't miss the first LED
        if (tracker.hasFoundFirstContour) {
            animator.update();
        }
        tracker.update();
    }
    ofSetColor(ofColor::white);
}

//--------------------------------------------------------------
void ofApp::draw(){
	//Draw into Fbo to allow scaling regardless of camera resolution
	camFbo.begin();
	cam.draw(0,0);

    
    ofSetColor(0, 255, 0);
	tracker.draw(); // Draws the blob rect surrounding the contour
    for (int i = 0; i < tracker.size(); i++) {
        int label = tracker.getLabel(i);
        ofDrawBitmapString(ofToString(label), tracker.getCenter(i).x+10, tracker.getCenter(i).y);
        
    }
    
    // Draw the detected contour center points
    for (int i = 0; i < tracker.centroids.size(); i++) {
		ofDrawCircle(tracker.centroids[i].x, tracker.centroids[i].y, 3);
    }
	camFbo.end();

	ofSetColor(ofColor::white); //reset color, else it tints the camera

	//Draw Fbo and Thresholding images to screen
	camFbo.draw(0, 0, cam.getWidth(), cam.getHeight());
	if (tracker.thresholded.isAllocated()) {
        // TODO: Tracker.draw()
        tracker.thresholded.draw(cam.getWidth(), 0, cam.getWidth(), cam.getHeight());
	}

}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    switch (key){
        case ' ':
            tracker.centroids.clear();
            break;
        case 's':
            tracker.setMode(TRACKER_MODE_CHASE);
            tracker.centroids.clear();
            isMapping = !isMapping;
            animator.setMode(ANIMATION_MODE_CHASE);
            animator.update();
            break;
        case 'b':
            tracker.setMode(TRACKER_MODE_BINARY);
            tracker.centroids.clear();
            isMapping = !isMapping;
            animator.setMode(ANIMATION_MODE_BINARY);
            animator.update();
            break;
        case 'g':
            generateSVG(tracker.centroids);
            break;
        case 'j':
            generateJSON(tracker.centroids);
            break;
		case 't':
            animator.setMode(ANIMATION_MODE_TEST);
            animator.update();
			break;
        case 'f': // filter points
            tracker.centroids = removeDuplicatesFromPoints(tracker.centroids);
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

void ofApp::exit(){
	// Close Connection
	opcClient.close();
}

void ofApp::generateSVG(vector <ofPoint> points) {
	if (points.size() == 0) {
		//User is trying to save without anything to output - bail
		ofLogError("No point data to save, run mapping first");
		return;
	}
	
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
	if (tracker.centroids.size() == 0) {
		//User is trying to save without anything to output - bail
		ofLogError("No point data to save, run mapping first");
		return;
	}

	ofFileDialogResult saveFileResult = ofSystemSaveDialog("layout.svg", "Save layout file");
	if (saveFileResult.bSuccess) {
		svg.save(saveFileResult.filePath);
        ofLogNotice("output") << "Saved SVG file.";
	}
}

void ofApp::generateJSON(vector<ofPoint> points) {
    int maxX = ofToInt(svg.info.width);
    int maxY = ofToInt(svg.info.height);
    ofLogNotice("output") << "maxX, maxY: " << maxX << ", " << maxY;
	ofLogNotice() << maxX;
	ofLogNotice() << maxY;
    
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
	if (e.target->is("Select Camera")) {
		//enumerateCams();
		gui->getDropdown("Select Camera")->update(); //TODO : Not working
		gui->update();
		switchCamera(e.child);
		ofLogNotice() << "Camera " << e.child << " was selected";
	}

	if (e.target->is("Select Driver Type")) {
		if (e.child == 0) {
			ofLogNotice() << "Pixel Pusher was selected";
			gui->getFolder("PixelPusher Settings")->setVisible(true);
			gui->getFolder("PixelPusher Settings")->expand();
			gui->getFolder("Mapping Settings")->setVisible(true);
			gui->getFolder("Mapping Settings")->expand();
			gui->getFolder("Fadecandy Settings")->setVisible(false);
			gui->getFolder("Fadecandy Settings")->collapse();
		}
		else if (e.child == 1) {
			ofLogNotice() << "Fadecandy/Octo was selected";
			gui->getFolder("Fadecandy Settings")->setVisible(true);
			gui->getFolder("Fadecandy Settings")->expand();
			gui->getFolder("Mapping Settings")->setVisible(true);
			gui->getFolder("Mapping Settings")->expand();
			gui->getFolder("PixelPusher Settings")->setVisible(false);
			gui->getFolder("PixelPusher Settings")->collapse();
		}
	}
}

//GUI event handlers
void ofApp::onSliderEvent(ofxDatGuiSliderEvent e)
{
		ofLogVerbose("gui") << "onSliderEvent: " << e.target->getLabel() << " "; e.target->printValue(); //TODO: stop from spamming output
		if (e.target->is("gui opacity")) gui->setOpacity(e.scale);
}

void ofApp::onTextInputEvent(ofxDatGuiTextInputEvent e)
{
	ofLogNotice("gui") << "onTextInputEvent: " << e.target->getLabel() << " " << e.target->getText();

	if (e.target->is("IP")) {
		IP= e.target->getText();
		opcClient.close();
		opcClient.setup(IP, 7890);
	}

	if (e.target->is("LEDS per Strip")) {
		string temp = e.target->getText();
        animator.setNumLedsPerStrip(ofToInt(temp));
	}

	if (e.target->is("STRIPS")) {
		string temp = e.target->getText();
		animator.setNumStrips(ofToInt(temp));
	}
}

void ofApp::onButtonEvent(ofxDatGuiButtonEvent e)
{
	ofLogNotice("gui") << "onButtonEvent: " << e.target->getLabel();

	if (e.target->is("TEST LEDS")) {
        animator.setMode(ANIMATION_MODE_TEST);
//        opcClient.autoWriteData(animator.getPixels());
	}
	if (e.target->is("MAP LEDS")) {
        isMapping = !isMapping;
	}
	if (e.target->is("SAVE LAYOUT")) {
		tracker.centroids = removeDuplicatesFromPoints(tracker.centroids);
		generateSVG(tracker.centroids);
	}

}

//Used to change acctive camera during runtime. Necessary to close old camera first before initializing the new one.
void ofApp::switchCamera(int num)
{
    ofLogNotice("gui") << "Switching camera";
	cam.close(); 
	cam.setDeviceID(num);
	cam.setup(1280, 720);
}
//Returns a vector containing all the attached cameras
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
		ofLogNotice() << "Camera " << id << ": " <<  name << endl;
		//newStrings[i] = name;
		deviceStrings.push_back(name);

	}
	
	//deviceStrings = new vector<string>(newStrings);
	return deviceStrings;
}

void ofApp::buildUI()
{
	//GUI
	int multiplier = 1;
	if (ofGetScreenWidth() >= 1440) { multiplier = 2; } // correct for high resolution displays
	gui = new ofxDatGui(ofGetWidth()-285*multiplier,40*multiplier);
	//gui = new ofxDatGui(ofxDatGuiAnchor::TOP_RIGHT);
	//gui->setTheme(new ofxDatGuiThemeSmoke());
	gui->addHeader(":: drag me to reposition ::");

	gui->addDropdown("Select Camera", enumerateCams());
	gui->addBreak();

	vector<string> opts = { "PixelPusher", "Fadecandy/Octo" };
	gui->addDropdown("Select Driver Type", opts);
	gui->addBreak();

	string connection;
	if (opcClient.isConnected()) { connection = "connected"; }
	else { connection = "disconnected"; }

	ofxDatGuiFolder* fcSettings = gui->addFolder("Fadecandy Settings", ofColor::white);
	fcSettings->addTextInput("IP", IP);

	fcSettings->addTextInput("STRIPS", ofToString(animator.getNumStrips()));
	fcSettings->addTextInput("LEDS per Strip", ofToString(animator.getNumLedsPerStrip()));
	fcSettings->setVisible(false);
	fcSettings->addBreak();
	
	ofxDatGuiFolder* ppSettings = gui->addFolder("PixelPusher Settings", ofColor::white);
	ppSettings->addTextInput("IP", IP);
	ppSettings->addTextInput("STRIPS", ofToString(animator.getNumStrips()));
	ppSettings->addTextInput("LEDS per Strip", ofToString(animator.getNumLedsPerStrip()));
	ppSettings->setVisible(false);
	ppSettings->addBreak();

	ofxDatGuiFolder* mapSettings = gui->addFolder("Mapping Settings", ofColor::dimGrey);
	mapSettings->addSlider(tracker.learningTime);
	mapSettings->addSlider(tracker.thresholdValue);
	mapSettings->addButton("Test LEDS");
	mapSettings->addButton("Map LEDS");
	mapSettings->addButton("Save Layout");
	mapSettings->setVisible(false);
	mapSettings->addBreak();

	gui->addSlider("gui opacity", 0, 100, 50);
	gui->addFRM();

	gui->addFooter();
	gui->setOpacity(gui->getSlider("gui opacity")->getScale());

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
