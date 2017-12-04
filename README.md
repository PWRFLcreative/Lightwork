# Lightwork BETA Quick Reference

Lightwork helps simplify the process of mapping complex arrangements of LEDs. To use it, you’ll want to set up your driver hardware and LEDs first.

## Requirements

**Libraries:**
All available from the Sketch>Import Library>Add Library dialog in the Processing IDE:

**PixelPusher, OpenCV, ControlP5**

We recommend, and have built this using the Logitech C920 webcam. It's cheap, is tripod mount compatible, and generally provides high quality capture.

Tested and developed in OSX 10.12 and Windows 10, may not behave well in other operating systems.

1440x900 or higher resolution recommended.

PixelPusher, Fadecandy or Artnet controller and individually addressable LEDs.

**PixelPusher setup reference:**

[https://sites.google.com/a/heroicrobot.com/pixelpusher/home/getting-started](https://sites.google.com/a/heroicrobot.com/pixelpusher/home/getting-started)

**FadeCandy:**

[https://github.com/scanlime/fadecandy](https://github.com/scanlime/fadecandy)

This guide is very useful for setting up a raspberry pi to drive FadeCandy controllers over network:

[https://learn.adafruit.com/1500-neopixel-led-curtain-with-raspberry-pi-fadecandy/fadecandy-server-setup](https://learn.adafruit.com/1500-neopixel-led-curtain-with-raspberry-pi-fadecandy/fadecandy-server-setup)

**Artnet**, you’ll need to consult your hardware’s manual for setup. (ArtNet support is currently incomplete)


# LightWork Mapper

The application used to map your LED array.

## UI controls:

**Camera:** select a connected USB webcam

**Refresh:** refreshes the list of connected webcams  - if a camera only shows black, unplug it and then refresh (this is to do with OS drivers not releasing properly)

**Stereo Toggle:** Enable second camera input for depth mapping (currently incomplete)

**FPS:** Number in the top right is the current framerate, useful for performance testing.

**Driver:** LED driver hardware. Currently FadeCandy and PixelPusher are supported (Artnet is incomplete)

**IP:** The local IP of the driver hardware. Use 127.0.0.1 for a USB connected fadecandy. IP not required for PixelPusher, as it uses discovery. Press enter to set the value.

**Strips:** Number of strips connected to the driver hardware. Press enter to set the value.

**LEDs per strip:** Number of LEDs on each attached strip. Use the longest string if they aren’t consistent. Note that FadeCandy supports a max of 64 per channel, and PixelPusher supports a max of 480 per channel. Press enter to set the value.

**Connect:** Connect to driver hardware using current settings. Button turns green on successful connection. Once connected, this button can be used to update the strip settings on the driver hardware.

**Test:** Run a cycling test pattern: white, red, green, blue. Use this to check physical connections and ensure all LEDs are working. Also useful for adjusting settings to compensate for ambient lighting or other environmental factors.

**Binary/ Sequential:** Select mapping method.

Sequential fires the LEDs in order of their address, and associates them with a physical location one at a time. Sequential can be very accurate, but is slower on large arrays. Sequential is also beneficial on arrays where the LEDs are very close together or when their light blends.

Binary flashes the full array in binary patterns, capturing a video frame for each bit of the pattern. Once captured, the patterns are associated with their physical location, all at once. Binary mapping is an exponential decrease in mapping time as the number of LEDs increases, but is not suitable for all arrangements.

**Map:** Run the selected mapping method. This will display detected LED locations in the output window. Runs until mapping is complete.

**Save:** Saves a CSV of the mapping layout, to be used in the Lightwork Scraper.

## Keyboard controls:

Can be enabled in Keypress.pde - disabled to prevent interfering with text field entry

S: save

M: sequential mapping

I: Image sequence mapping

L: save layout to CSV

T: test mode

# LightWork Scraper

Use with your own sketch to map your content onto the LED array

Requires Interface.pde, OPC.pde and Scraper.pde in your sketch folder, as well as a layout SVG in the sketch or data folder.

Replace the drawing code in the example to display your own content.

