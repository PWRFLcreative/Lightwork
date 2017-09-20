//
//  BinaryPattern.cpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 28.8.2017.
//
//

#include "BinaryPattern.h"

using namespace std;

// Constructor
BinaryPattern::BinaryPattern(void) {
    frameNum = 0;
    state = START;
}

BinaryPattern::~BinaryPattern(void) {
    
}

void BinaryPattern::generatePattern(int num) {
    // Generate a bitset with 10 bits. If the bit sequence is shorter it will append zeros to make the length 10.
    
    // TODO: replace bitset< 10 > with bitset< patternLength > 
    std::string s = std::bitset< 10 >( num ).to_string(); // string conversion
    
    
    
    // Insert START and OFF signals
    // Example: [START, OFF, HIGH, OFF, LOW, OFF, LOW, OFF, HIGH, OFF, etc].
    cout << s << endl;
    for (int i = 0; i<s.size()+1; i++) { // +1 for a trailing OFF message
        if (i == 0) {
            s.insert(i, "2"); // state == START
        }
//        else if (i == 1) {
//            s.insert(i, "3");
//        }
        else if (i%2 == 0) {
            s.insert(i, "3"); // state == OFF
        }
    }
    // Insert OFF after START
    s.insert(1, "3");
    // Insert trailing OFF
    s.append("3");
    
    // Store bitstrings in pattern string
    pattern = s;
    
    cout << s << endl;
    // Convert to int vector and store internally
    patternVector = convertStringToIntVector(pattern);
    
};

vector <int> BinaryPattern::convertStringToIntVector(string pattern) {
    // Convert binary string to vector of ints
    // TODO: Deal with 2s and 3s
    cout << "convertStringToIntVector" << endl;
    cout << "Pattern string: " << pattern << endl;
    
    std::vector<int> ints;
    
    ints.reserve(pattern.size()); //to save on memory reallocations
    
    std::transform(std::begin(pattern), std::end(pattern), std::back_inserter(ints),
                   [](char c) {
                       return c - '0'; // Distance between c and the string '0' (this is a common 'trick')
                   }
                   );
    return ints;
}

void BinaryPattern::advance() {
    
    
    // TODO: review the ordering of state + frameNum assignment
    // Set the LED State to HIGH/LOW depending on the patternVector location
    state = static_cast<led_state_t>(patternVector[frameNum]);
    if (state == LOW) {
        cout << "LOW" << endl;
    }
    else if (state == HIGH) {
        cout << "HIGH" << endl;
    }
    else if (state == START) {
        cout << "START" << endl;
    }
    else if (state == OFF) {
        cout << "OFF" << endl;
    }
    else {
        cout << state << endl;
    }
//    cout << state << endl;
//    cout << "\n";
//    cout << frameNum << "\n";
    
    frameNum = frameNum+1;
    if (frameNum >= patternLength) {
        frameNum = 0;
    }
    
}



