#!/usr/bin/env python
# Using OpenCV verison 3.1.0
# Light LEDs in sequence and stores the coordinates for each one.

import cv2
import opc, time
import numpy as np

numLEDs = 50

#client = opc.Client('localhost:7890')
# FadeCandy Client
client = opc.Client('fade1.local:7890')

# OpenCV video capture
cap = cv2.VideoCapture(0)

cv2.waitKey(1) & 0xFF == ord('q')

while True:
	# Capture frame-by-frame
    ret, frame = cap.read()

    # Our operations on the frame come here
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Display the resulting frame
    cv2.imshow('frame', gray)
    for i in range(numLEDs):
        pixels = [(0,0,0)] * numLEDs
        pixels[i] = (100, 0, 0)
        client.put_pixels(pixels)
        time.sleep(0.01)
	# Exit condition
	

# When everything done, release the capture
cap.release()
cv2.destroyAllWindows()
