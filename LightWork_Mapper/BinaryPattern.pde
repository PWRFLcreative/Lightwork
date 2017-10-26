/* BinaryPattern Generator Class
 created by Leó Stefánsson
 okt. 25 2017
 @ PWRFL / Lightwork
 */

// Pattern detection
int previousState;
int detectedState;
int animationPatternLength; // 6 bit pattern with a START at the end and an OFF after each one
int bitIndex;
int numBits;

String binaryPatternString; 
int[]  binaryPatternVector;
String animationPatternString;
int[]  animationPatternVector;

//enum pattern_state_t {
//  LOW, HIGH, START, OFF
//};

//pattern_state_t state;

int frameNum;

public class BinaryPattern {

  // Constructor

  BinaryPattern() {
    numBits = 10; 
    animationPatternLength = 10;
    frameNum = 0; // Used for animation
    bitIndex = 0; // Used by the detector to write bits 
    //state = pattern_state_t.START;
    //generatePattern(0);
    previousState = 0;
    detectedState = 0;

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

    // Convert Binary Pattern to Animation Sequence

    /*

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
     */
  }

  // Set the current 'state', read it from the patternVector
  void advance() {
    // TODO: review the ordering of state + frameNum assignment
    // Set the LED State to HIGH/LOW depending on the patternVector location

    //state = animationPatternVector[frameNum]; 
    // TODO: use animationPatternVector
    //switch(binaryPatternVector[frameNum]) {
    //case 0:
    //  state = pattern_state_t.LOW;
    //  break;
    //case 1: 
    //  state = pattern_state_t.HIGH;
    //  break;
    //}


    frameNum = frameNum+1;
    if (frameNum >= animationPatternLength) {
      frameNum = 0;
    }
  }
  
  int getState() {
    int state = binaryPatternVector[frameNum];

    advance();
    return state;
  }
}