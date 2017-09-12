//
//  Animator.hpp
//  Lightwork-Mapper
//
//  Created by Leó Stefánsson on 11.9.2017.
//
//

#ifndef Animator_h
#define Animator_h

#include <stdio.h>
#include "ofMain.h"

#endif /* Animator_h */

class Animator {
public:
    Animator();  // Constructor
    ~Animator(); // Destructor
    
    void setup();
    
};

void Animator::setup() {
    ofLogNotice("Setting up Animator");
}

