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
  private int lifeTime = 3; //127;
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

    available = true;

    timer = lifeTime;

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
    
    float opacity = map(timer, 0, lifeTime, 0, 127);
    fill(0, 255, 0, opacity);
    stroke(0, 255, 0);
    rect(x,y, r.width, r.height);
    fill(255, 0, 0);
    textSize(12);
    //text(""+id, r.x+10, r.y+5);
    String decoded = detectedPattern.decodedString.toString();
    //text(decoded, x+25, y+5);
  }


  // Give me a new contour for this blob (shape, points, location, size)
  // Oooh, it would be nice to lerp here!
  void update(Contour newC) {

    contour = new Contour(parent, newC.pointMat);

    // Is there a way to update the contour's points without creating a new one?
    /*ArrayList<PVector> newPoints = newC.getPoints();
     Point[] inputPoints = new Point[newPoints.size()];
     
     for(int i = 0; i < newPoints.size(); i++){
     inputPoints[i] = new Point(newPoints.get(i).x, newPoints.get(i).y);
     }
     contour.loadPoints(inputPoints);*/

    timer = lifeTime;
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
  void decode() {
    int br = brightness;
    int threshold = 180; 
    // Edge detection (rising/falling);
    int frameDelta = 0; 
    boolean didTransition = false; 
    if (br >= threshold && detectedPattern.state == 0) {
      didTransition = true; 
      detectedPattern.state = 1;
      //println(frameDelta+"],");
      //previousFrameCount = frameCount;
    } else if (br < threshold && detectedPattern.state == 1) {
      didTransition = true;
      detectedPattern.state = 0; 
      //print("0, ");  
      //println(frameCount);
    }
    if (didTransition) {
      frameDelta = frameCount-previousFrameCount;
      int frameSkip = 3;  // TODO: link this with Animator frameskip

      // Find out how many instances of the previous state occurred (000 = 3, 11 = 2, 1111 = 4, etc)
      int numRepeats = frameDelta/frameSkip;

      for (int i = 0; i < numRepeats; i++) {
        detectedPattern.writeNextBit(detectedPattern.state);
      }




      print(frameDelta+", ");
      //print("["+detectedPattern.state+", "+frameDelta+"], ");
      previousFrameCount = frameCount;
    }
  }
}