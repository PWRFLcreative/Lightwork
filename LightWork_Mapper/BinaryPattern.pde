/*
 *  BinaryPattern Generator Class
 *  
 *  This class generates binary patterns used in matching LED addressed to physical locations
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @author Leó Stefánsson
 */

public class BinaryPattern {

  // Pattern detection
  int previousState;
  int detectedState;
  int state; // Current bit state, used by animator
  int animationPatternLength; // 10 bit pattern with a START at the end and an OFF after each one
  int readIndex; // For reading bit at index (for the animation)
  int numBits;

  StringBuffer decodedString; 
  int writeIndex; // For writing detected bits

  String binaryPatternString; 
  int[]  binaryPatternVector;
  String animationPatternString;
  int[]  animationPatternVector;

  int frameNum;

  // Constructor
  BinaryPattern() {
    numBits = 10; 
    animationPatternLength = 10;
    frameNum = 0; // Used for animation
    readIndex = 0; // Used by the detector to write bits 
    writeIndex = 0; 
    previousState = 0;
    detectedState = 0;

    decodedString = new StringBuffer(10); // Init with capacity
    decodedString.append("W123456789");

    binaryPatternVector = new int[numBits];
    binaryPatternString = "";
    animationPatternVector = new int[animationPatternLength];
    animationPatternString = "";
  }

  // Generate Binary patterns for animation sequence and pattern-matching
  void generatePattern(int num) {
    // Convert int to String of fixed length
    String s = Integer.toBinaryString(num); 
    // TODO: string format, use numBits instead of hardcoded 10
    s = String.format("%10s", s).replace(" ", "0"); // Insert leading zeros to maintain pattern length
    binaryPatternString = s;

    // Convert Binary String to Vector of Ints
    for (int i = 0; i < binaryPatternVector.length; i++) {
      char c = binaryPatternString.charAt(i);
      int x = Character.getNumericValue(c);
      binaryPatternVector[i] = x;
    }
  }

  void advance() {
    state = binaryPatternVector[frameNum];
    frameNum = frameNum+1;
    if (frameNum >= animationPatternLength) {
      frameNum = 0;
    }
  }

  // Pattern storage
  void writeNextBit(int bit) {
    println("writing bit: "+bit+" to writeIndex: "+this.writeIndex); 
    String s =  String.valueOf(bit);
  
    decodedString.replace(this.writeIndex, this.writeIndex+1, s);
    
    this.writeIndex++; 
    if (writeIndex >= animationPatternLength) {
      writeIndex = 0;
    }
  }
  
}