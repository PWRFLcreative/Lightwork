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

// Generate Binary patterns for animation sequence and pattern-matching
void BinaryPattern::generatePattern(int num) {
    // Generate a bitset with 10 bits. If the bit sequence is shorter it will append zeros to make the length 10.
    // TODO: replace bitset< 10 > with bitset< patternLength >
    std::string s = std::bitset< 10 >( num ).to_string(); // string conversion
    
    // store the unmodified binary pattern as a string and int vector
    binaryPatternString = s;
    binaryPatternVector = convertStringToIntVector(binaryPatternString);
    
    // Insert START and OFF signals
    // Example: [START, OFF, HIGH, OFF, LOW, OFF, LOW, OFF, HIGH, OFF, etc].
    for (int i = 0; i<s.size()+1; i++) { // +1 for a trailing OFF message
        if (i == 0) {
            s.insert(i, "2"); // state == START
        }
        else if (i%2 == 0) {
            s.insert(i, "3"); // state == OFF
        }
    }
    // Insert OFF after START
    s.insert(1, "3");
    // Insert trailing OFF
    s.append("3");
    
    // Store bitstrings in pattern string
    animationPatternString = s;

    // Convert to int vector and store internally
    animationPatternVector = convertStringToIntVector(animationPatternString);
    
};

vector <int> BinaryPattern::convertStringToIntVector(string pattern) {
    // Convert binary string to vector of ints
    // TODO: Deal with 2s and 3s
//    cout << "convertStringToIntVector" << endl;
//    cout << "Pattern string: " << pattern << endl;
    
    std::vector<int> ints;
    
    ints.reserve(pattern.size()); //to save on memory reallocations
    
    std::transform(std::begin(pattern), std::end(pattern), std::back_inserter(ints),
                   [](char c) {
                       return c - '0'; // Distance between c and the string '0' (this is a common 'trick')
                   }
                   );
    return ints;
}

string BinaryPattern::convertIntVectorToString(vector <int> vec) {
    
    std::ostringstream oss;
    
    if (!vec.empty())
    {
        // Convert all but the last element to avoid a trailing ","
        std::copy(vec.begin(), vec.end()-1,
                  std::ostream_iterator<int>(oss, ""));
        
        // Now add the last element with no delimiter
        oss << vec.back();
    }
    
    return oss.str();
}

// Set the current 'state', read it from the patternVector
void BinaryPattern::advance() {
    // TODO: review the ordering of state + frameNum assignment
    // Set the LED State to HIGH/LOW depending on the patternVector location
    state = static_cast<pattern_state_t>(animationPatternVector[frameNum]);
    frameNum = frameNum+1;
    if (frameNum >= animationPatternLength) {
        frameNum = 0;
    }
}

// Write bit at index, this is so the tracker can update the detected pattern, bit-by-bit

void BinaryPattern::updateBitAtIndex(int bit, int index) {
    binaryPatternVector.at(index) = bit;
    binaryPatternString = convertIntVectorToString(binaryPatternVector);
}



