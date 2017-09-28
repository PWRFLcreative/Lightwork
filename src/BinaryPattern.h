//
//  BinaryPattern.hpp
//  Lightwork-Mapper
//
//  Created by Leo Stefansson on 28.8.2017.
//
//

#ifndef BinaryPattern_h
#define BinaryPattern_h

#include <stdio.h>
#include <string>
#include <vector>
#include <iostream>
#include <sstream>
#include <bitset>

#include <algorithm>
#include <iterator>



using namespace std;

class BinaryPattern {
    
    
public:
    BinaryPattern(); // Constructor
    ~BinaryPattern(); // Destructor
    
    void generatePattern(int num);
    void advance(); // Advance the framecount and set the state accordingly
    void updateBitAtIndex(int bit, int index);
    
    string binaryPatternString; // Stores the actual binary pattern, use this for pattern matching.
    vector <int> binaryPatternVector; // Stores the actual binary pattern as a vector
    
    string animationPatternString; // Stores a single binary pattern with START and OFF signals inserted (4 states)
    vector <int> animationPatternVector; // Stores binary pattern as vector of ints
    const int animationPatternLength = 22; // 10 bit pattern with a START at the end and an OFF after each one
    // TODO: get rid of patternLength, use pattern.size() instead
    
    //std::vector <std::string> patterns; // For Storing Binary Patterns
    
    // LED binary state. START -> GREEN, HIGH -> BLUE, LOW -> RED, OFF -> (off)
    enum pattern_state_t {LOW, HIGH, START, OFF};
    pattern_state_t state;

    int frameNum;
    
private:
    vector <int> convertStringToIntVector(string pattern);
    string convertIntVectorToString(vector <int> pattern);
    
};

#endif /* BinaryPattern_h */
