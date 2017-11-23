/**
 * Blob Class
 *
 * Based on this example by Daniel Shiffman:
 * http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
 * 
 * @author: Jordi Tost (@jorditost)
 * 
 * University of Applied Sciences Potsdam, 2014
 */

class Blob {

  private PApplet parent;

  // Contour
  public Contour contour;

  // Am I available to be matched?
  public boolean available;

  // How long should I live if I have disappeared?
  private int initTimer = 200; //127;
  public int timer;

  // Unique ID for each blob
  int id;

  // Pattern Detection
  BinaryPattern detectedPattern;
  int brightness;
  int previousFrameCount; // FrameCount when last edge was detected


  // Make me
  Blob(PApplet parent, int id, Contour c) {
    this.parent = parent;
    this.id = id;
    this.contour = new Contour(parent, c.pointMat);

    this.available = true;

    this.timer = initTimer;

    detectedPattern = new BinaryPattern();
    brightness = 0; 
    previousFrameCount = 0;
  }

  // Show me
  void display() {
    Rectangle r = contour.getBoundingBox();

    //set draw location based on displayed camera position, accounts for moving cam in UI
    float x = map(r.x,0,(float)camWidth,(float)camArea.x,camArea.x+camArea.width);
    float y = map(r.y,0,(float)camHeight,(float)camArea.y,camArea.y+camArea.height);
    //float x = r.x;
    //float y = r.y; 
    float opacity = map(timer, 0, initTimer, 0, 127);
    fill(0, 255, 0, opacity);
    stroke(255, 0, 0);
    rect(x, y, r.width, r.height);
    fill(255, 0, 0);
    textSize(12);
    stroke(0, 255, 0); 
    
    text(""+id, x+3, y+5);
    String decoded = detectedPattern.decodedString.toString();
    fill(0, 255, 0); 
    text(decoded, x+30, y+5);
  }

  void update(Contour newContour) {
    this.contour = newContour;
    this.timer = initTimer;
  }

  // Count me down, I am gone
  void countDown() {    
    timer--;
  }

  // I am dead, delete me
  boolean dead() {
    if (timer < 0) return true;
    return false;
  }

  public Rectangle getBoundingBox() {
    return contour.getBoundingBox();
  }

  void registerBrightness(int br) {
    brightness = br;
  }

  // Decode Binary Pattern
  // TODO: Note: this has been changed a lot
  void decode() { 
    int br = brightness;
    int threshold = 15; 
    println(brightness);
    // Edge detection (rising/falling);

 
    if (br >= threshold) {
      detectedPattern.state = 1;
    } else if (br < threshold) {
      detectedPattern.state = 0; 
    }
    //print(detectedPattern.state);
    // temporary target pattern for testing

    // Find out how many instances of the previous state occurred (000 = 3, 11 = 2, 1111 = 4, etc)
    //int numRepeats = frameDelta/frameSkip;
    //println(numRepeats);

   detectedPattern.writeNextBit(detectedPattern.state);



    String targetPattern = "1010101010";
    if (targetPattern.equals(detectedPattern)) {
      println("MATCH FOUND!!!!");
    }

    //print(detectedPattern.state);
  }
}