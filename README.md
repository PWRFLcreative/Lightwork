# Lightwork BETA

![Lightwork GIF](https://media.giphy.com/media/xUNd9SDWXJ85FUaUbC/giphy.gif)

Lightwork simplifies the process of mapping complex arrangements of LEDs, removing the limitations of straight lines and grids from your light based creations.

 * Quick binary mapping tutorial: [LightWork Tutorial](https://youtu.be/7UJ1Ocxc8eg)


Requirements
--------------

**Libraries:**
**PixelPusher, OpenCV, ControlP5**

All available from the `Sketch > Import Library > Add Library` dialog in the Processing IDE.

**Operating System**

Tested and developed in OSX 10.12 and Windows 10, may not behave well in other operating systems.

**A Webcam**

We recommend, and have built this using the Logitech C920 webcam. It's cheap, is tripod mount compatible, and generally provides high quality and high speed capture.

**Hardware**

PixelPusher, Fadecandy or Artnet controller and individually addressable LEDs are required.

1440x900 or higher resolution monitor recommended.

Hardware Setup Reference
--------------

This readme assumes you have set up your driver hardware and LEDs first.
Here are some references to get you started if this is your first time:

**PixelPusher setup reference:**
[https://sites.google.com/a/heroicrobot.com/pixelpusher/home/getting-started](https://sites.google.com/a/heroicrobot.com/pixelpusher/home/getting-started)

**FadeCandy:**
[https://github.com/scanlime/fadecandy](https://github.com/scanlime/fadecandy)

This guide is very useful for setting up a raspberry pi to drive FadeCandy controllers over network:
[https://learn.adafruit.com/1500-neopixel-led-curtain-with-raspberry-pi-fadecandy/fadecandy-server-setup](https://learn.adafruit.com/1500-neopixel-led-curtain-with-raspberry-pi-fadecandy/fadecandy-server-setup)

**ArtNet:**
Consult your hardware’s manual for setup. (ArtNet support is currently incomplete)


LightWork Mapper
--------------

![Lightwork Mapper Screenshot](https://raw.github.com/PWRFLcreative/Lightwork/master/doc/images/LightworkUI_BETA.png)

The application used to map your LED array. Use an attached webcam to capture LED states and translate their physical locations into screen locations. Outputs a normalized CSV of LED locations for use in the Lightwork Scraper, or any software of your choice.

UI controls:
--------------

**Camera:** select a connected USB webcam

**Refresh:** refreshes the list of connected webcams  - if a camera only shows black, unplug it and then refresh (this is to do with OS drivers not releasing properly)

**Stereo Toggle:** Enable multiple captures for depth mapping. Estimates Z depth based on 2 captures. Once enabled, you'll need to use Map Left and Map Right before saving the layout.

**FPS:** Number in the top right is the current framerate, useful for performance testing.

**Driver:** LED driver hardware. Currently FadeCandy and PixelPusher are supported (Artnet is incomplete). Selecting a driver from the dropdown will reveal the required settings to connect. Pixelpusher configuration is stored on its USB, and will be discovered over network.

**IP:** The local IP of the driver hardware. Use 127.0.0.1 for a USB connected fadecandy. Press enter to set the value.

**Strips:** Number of strips connected to the driver hardware. Press enter to set the value.

**LEDs per strip:** Number of LEDs on each attached strip. Use the longest string if they aren’t consistent. Note that FadeCandy supports a max of 64 per channel, and PixelPusher supports a max of 480 per channel. Press enter to set the value.

**Connect:** Connect to driver hardware using current settings. Button turns green on successful connection. Once connected, this button can be used to update the strip settings on the driver hardware.

**Contrast:** Adjusts the contrast on the OpenCV input. Useful for compensating for ambient lighting.

**Threshold:** OpenCV is performed on a binary image (black and white). Pixels above the threshold become white, pixels below the threshold become black. Use to isolate your LEDs in a noisy scene.

**LED Brightness:** 0-255. This can help reduce lens flaring, or compensate for ambient light in a scene.

**Pattern/ Sequence:** Select mapping method.

Sequence fires the LEDs in order of their address, and associates them with a physical location one at a time. Sequential can be very accurate, but is slower on large arrays. Sequential is also beneficial on arrays where the LEDs are very close together or when their light blends.

Pattern flashes the full LED array in binary patterns, capturing a video frame for each bit of the pattern. Once captured, the patterns are associated with their physical location, all at once. Binary mapping is an exponential decrease in mapping time as the number of LEDs increases, but is not suitable for all arrangements.

**Calibrate:** Run a test to check physical connections and ensure all LEDs are working. Also useful for adjusting settings to compensate for ambient lighting or other environmental factors. Press Calibrate again to stop.

**Map:** Run the selected mapping method. This will display detected LED locations in the output window. Runs until mapping is complete.

**Frameskip** Amount of frames to wait between animator actions. Lower numbers speed up mapping but can reduce accuracy.

**Min/ Max Blob Size:** Isolate size of blobs elegible for detection. Increasing minimum size helps eliminate noise, increasing maximum size helps compensate for larger LEDs.

**Min Blob Distance:** Minimum distance between detected blobs. Blobs closer than this will be filtered out as erroneous.

**Save Layout:** Saves a CSV of the mapping layout, to be used in the Lightwork Scraper.


Keyboard Controls:
--------------

**ALT-SHIFT-S** : Save UI properties to file

**ALT-SHIFT-L** : Load UI properties to file

Note: ALT also enables dragging in ControlP5, try to release the alt key first after using these commands. If it's releases last it can enable dragging.

**SHIFT-H** : Disable dragging (if activated with alt)


## Lightwork Scraper

![Lightwork Scraper Screenshot](https://raw.github.com/PWRFLcreative/Lightwork/master/doc/images/LightworkScraper.png)

Use with your own sketch to map your content onto the LED array.

Requires `Interface.pde`, `OPC.pde` and `Scraper.pde` in your sketch folder, as well as a layout CSV in the sketch or data folder.

Replace the drawing code in the example to display your own content.


**Example Setup:**
```
void setup() {
  size(1280, 960, P3D);

  //initialize scraper
  //replace with your filename, make sure it's in the sketch or /data folder
  scrape = new Scraper("layout.csv");

  //initialize connection to LED driver - replace with adress and LED config for your setup
  //(Device type, address (not required for PixelPusher), number of strips, LEDs per strip)
  network = new Interface(device.FADECANDY, "fade2.local", 3, 50);
  network.connect(this);

  //update scraper after network connects
  scrape.update();
}
```

**Example draw loop:**
```
void draw() {
  //Your drawing code here

  //Scraper functions
  scrape.update(); //Update colors to be sent to LEDs
  network.update(scrape.getColors()); //Send colors to LEDs
  scrape.display(); //Show locations loaded from CSV
}
```

--------------

Developed with the participation of Creative BC, the Province of British Columbia and the British Columbia Arts Council.

![CBCBCACLogos](https://raw.github.com/PWRFLcreative/Lightwork/master/doc/images/CreativeBC_BC_joint_RGB.png)
