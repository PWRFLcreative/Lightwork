/* BinaryPattern Generator Class
 created by Leó Stefánsson
 okt. 25 2017
 @ PWRFL / Lightwork
 */



public class BinaryPattern {

  // Pattern detection
  int previousState;
  int detectedState;
  int state; // Current bit state, used by animator
  int animationPatternLength; // 6 bit pattern with a START at the end and an OFF after each one
  int readIndex; // For reading bit at index (for the animation)
  int numBits;
  
  StringBuffer decodedString; 
  int writeIndex; // For writing detected bits

  String binaryPatternString; 
  int[]  binaryPatternVector;
  String animationPatternString;
  int[]  animationPatternVector;

  //enum pattern_state_t {
  //  LOW, HIGH, START, OFF
  //};

  //pattern_state_t state;

  int frameNum;

  // Constructor

  BinaryPattern() {
    numBits = 10; 
    animationPatternLength = 10;
    frameNum = 0; // Used for animation
    readIndex = 0; // Used by the detector to write bits 
    writeIndex = 0; 
    //state = pattern_state_t.START;
    //generatePattern(0);
    previousState = 0;
    detectedState = 0;
    
    writeIndex = 0; 
    decodedString = new StringBuffer(10); // Init with capacity
    decodedString.append("0000000000");
    
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
  // TODO: Finish or delete this part
  void writeNextBit(int bit) {
    //decodedString.append(bit);
    String s =  String.valueOf(bit);
    decodedString.replace(writeIndex,writeIndex+1,s);
    //decodedString.setCharAt(writeIndex,s);
    println("decodedString: "+decodedString);
    
    //binaryPatternString.charAt(writeIndex) = String(bit);
    
    writeIndex++; 
    if (writeIndex >= animationPatternLength) {
    writeIndex = 0;  
    }
  }
  
}