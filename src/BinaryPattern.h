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

#endif /* BinaryPattern_h */

using namespace std;

class BinaryPattern {
    
    
public:
    BinaryPattern(); // Constructor
    ~BinaryPattern(); // Destructor
    
    void generatePattern(int num);
    void advance(); // Advance the framecount and set the state accordingly
    
    string pattern; // Stores a single binary pattern
    vector <int> patternVector; // Stores binary pattern as vector of ints
    const int patternLength = 10;
    
    //std::vector <std::string> patterns; // For Storing Binary Patterns
    
    enum led_state_t {LOW, HIGH, START, OFF}; // LED binary state. START -> GREEN, HIGH -> BLUE, LOW -> RED, OFF -> (off)
    led_state_t state;

    int frameNum;
    
private:
    vector <int> convertStringToIntVector(string pattern);
};


