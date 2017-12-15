/*
 *  Blob Manager
 *  
 *  This class manages blobs used to detect locations and patterns
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @author Leó Stefánsson
 */

class BlobManager {

  private PApplet parent;

  int minBlobSize = 5;
  int maxBlobSize = 30;
  float distanceThreshold = 2; 
  int lifetime = 200; 

  //ArrayList<Contour> contours;
  // List of detected contours parsed as blobs (every frame)
  ArrayList<Contour> newBlobs;
  // List of my blob objects (persistent)
  ArrayList<Blob> blobList;
  // Number of blobs detected over all time. Used to set IDs.
  int blobCount = 0; // Use this to assign new (unique) ID's to blobs

  BlobManager(PApplet parent, OpenCV cv) {
    this.parent = parent; 
    blobList = new ArrayList<Blob>();
  }

  void update(ArrayList<Contour> contours) {
    // Find all contours
    //blobCV.loadImage(opencv.getSnapshot());
    //ArrayList<Contour> contours = opencv.findContours();

    // Filter contours, remove contours that are too big or too small
    // The filtered results are our 'Blobs' (Should be detected LEDs)
    ArrayList<Contour> newBlobs = filterContours(contours); // Stores all blobs found in this frame

    // Note: newBlobs is actually of the Contours datatype
    // Register all the new blobs if the blobList is empty
    if (blobList.isEmpty()) {
      //println("Blob List is Empty, adding " + newBlobs.size() + " new blobs.");
      for (int i = 0; i < newBlobs.size(); i++) {
        //println("+++ New blob detected with ID: " + blobCount);
        int id = blobCount; 
        blobList.add(new Blob(parent, id, newBlobs.get(i)));
        blobCount++;
      }
    }

    // Check if newBlobs are actually new...
    // First, check if the location is unique, so we don't register new blobs with the same (or similar) coordinates
    else {
      // New blobs must be further away to qualify as new blobs
      // Store new, qualified blobs found in this frame

      // Go through all the new blobs and check if they match an existing blob
      for (int i = 0; i < newBlobs.size(); i++) {
        PVector p = new PVector(); // New blob center coord
        Contour c = newBlobs.get(i);
        // Get the center coordinate for the new blob
        float x = (float)c.getBoundingBox().getCenterX();
        float y = (float)c.getBoundingBox().getCenterY();
        p.set(x, y);

        // Check if an existing blob is under the distance threshold
        // If it is under the threshold it is the 'same' blob
        boolean didMatch = false;
        for (int j = 0; j < blobList.size(); j++) {
          Blob blob = blobList.get(j);
          // Get existing blob coord
          PVector p2 = new PVector();
          p2.x = (float)blob.contour.getBoundingBox().getCenterX();
          p2.y = (float)blob.contour.getBoundingBox().getCenterY();

          float distance = p.dist(p2);
          if (distance <= distanceThreshold) {
            didMatch = true;
            // New blob (c) is the same as old blob (blobList.get(j))
            // Update old blob with new contour
            blobList.get(j).update(c);
            break;
          }
        }

        // If none of the existing blobs are too close, add this one to the blob list
        if (!didMatch) {
          Blob b = new Blob(parent, blobCount, c);
          blobCount++;
          blobList.add(b);
        }
        // If new blob isTooClose to a a previous blob, reset the age.
      }
    }

    // Update the blob age
    //for (int i = blobList.size()-1; i > 0; i--) {
    for (int i = 0; i < blobList.size(); i++) {
      Blob b = blobList.get(i);
      b.countDown();
      if (b.dead()) {
        blobList.remove(i); // TODO: Is this safe? Removing from array I'm iterating over...
      }
    }
  }

  void display() {

    for (Blob b : blobList) {
      strokeWeight(1);
      b.display();
    }
  }
  
  void setBlobLifetime(int lt) {
    for (Blob b : blobList) {
      b.timer = lt;
    }
  }
  
  void clearAllBlobs() {
    blobList.clear(); 
  }
  
  int numBlobs(){
    return blobList.size();
  }

  // Filter out contours that are too small or too big
  ArrayList<Contour> filterContours(ArrayList<Contour> newContours) {

    ArrayList<Contour> blobs = new ArrayList<Contour>();

    // Which of these contours are blobs?
    for (int i=0; i<newContours.size(); i++) {

      Contour contour = newContours.get(i);
      Rectangle r = contour.getBoundingBox();

      // If contour is too small, don't add blob
      if (r.width < minBlobSize || r.height < minBlobSize || r.width > maxBlobSize || r.height > maxBlobSize) {
        continue;
      }
      blobs.add(contour);
    }

    return blobs;
  }

  
}