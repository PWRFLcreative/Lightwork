int currentFrame = 0; 

void setMovieFrame(int n) {
  mov.play();
    
  // The duration of a single frame:
  float frameDuration = 1.0 / mov.frameRate;
    
  // We move to the middle of the frame by adding 0.5:
  float where = (n + 0.5) * frameDuration; 
    
  // Taking into account border effects:
  float diff = mov.duration() - where;
  if (diff < 0) {
    where += diff - 0.25 * frameDuration;
  }
    
  mov.jump(where);
  mov.pause();  
}  

int getMovieLength() {
  return int(mov.duration() * mov.frameRate);
}

void nextFrame() {
  setMovieFrame(currentFrame); 
  if (currentFrame < getLength() - 1) {
    newFrame++;
  }
  else {
    currentFrame = 0; 
  } 
}