// Processing Video Wall Code
// Updated from the OctoWS2811 Video Library by AvWuff
// Receives TPM2.NET data



import processing.serial.*;
import java.awt.Rectangle;
import hypermedia.net.*;

UDP udp;//Create UDP object for recieving

// SETUP VALUES FOR TEENSIES
int PINS = 8; // number of pins on the teensy that are connected to LED strips.
int numPorts=0;  // the number of serial ports in use
int maxPorts=24; // maximum number of serial ports

Serial[] ledSerial = new Serial[maxPorts];     // each port's actual Serial port
Rectangle[] ledArea = new Rectangle[maxPorts]; // the area of the movie each port gets, in % (0-100)
boolean[] ledLayout = new boolean[maxPorts];   // layout of rows, true = even is left->right
PImage[] ledImage = new PImage[maxPorts];      // image sent to each port
PGraphics tLayer;
PImage pDraw; // Graphics layer for display.
PImage pLoad; // Image that gets loaded.
PImage[] allFrames;
PFont f;

// GLOBALS
int errorCount=0;
float framerate = 30;
int colorIndex = 0;
long pcount = 0;
int tPos = 150;



// *********************** PLAYBACK MODE
// Change this mode to test out a bunch of different effects.
int mode = 6; // 0 - Video, 1 - Plasma, 2 = text, 3 = colors, 4 - stars, 5 - image, 6 - tpm2.net

int udpCount = 0; // Frames received in last time period
long udpTimer = 0; // Timer.

void setup() {
  String[] list = Serial.list();
  delay(20);
  println("Serial Ports List:");
  println(list);
  
  serialConfigure("COM3");  // change these to your port names
  serialConfigure("COM4");



  // This seems like a good framerate.
  frameRate(30);

  tLayer =   createGraphics(150,32);

  f = createFont("Lucida Handwriting",16,true); // Arial, 16 point, anti-aliasing on

  // if (errorCount > 0) exit();
  size(600, 600);  // create the window

  // This is the image used for effects.
  pDraw = new PImage(150, 32, RGB);
  
  switch (mode)
  {
    case 0:
      break;
    case 5: 
      break;
    case 6:
      udp = new UDP(this, 65506, "127.0.0.1");
      //udp.log(true);
      udp.listen(true);
      break;
    
  }



}

void receive(byte[] data, String HOST_IP, int PORT_RX){

  int w = 150;
  int h = 32;
  int s = 6; // Start at.
  
  if (data[0] == (byte)0x9C)
  {
    if (data[1] == (byte)0xDA) // Frame data! 
    {
      
      int pblen = (data[2] & 0xFF) * 256 + (data[3]  & 0xFF);
      
      if (pblen >= w * h * 3)
      {
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            int loc = x + y * w;
            int i = ((y * w) + x) * 3;
            
            pDraw.pixels[loc] = color( data[s+i]  & 0xFF, data[s+i+1] & 0xFF, data[s+i+2] & 0xFF  );  
            
          }
        }

        pDraw.updatePixels();
        sendToSigns(pDraw);
  
        udpCount++;
        if (millis() > udpTimer + 1000)
        {
          // Calculate framerate.
          float fr = (float)udpCount / ((millis() - udpTimer) / 1000);
          println("Framerate: " + fr);
         
          udpTimer = millis();
          udpCount = 0;
        }
        
      }

    }
  }
    
}

void textTest()
{

  int h = 32;
  int w = 150;
  
  tLayer.beginDraw();
  
  tLayer.fill(0);
  tLayer.rect(0, 0, w, h);
  tLayer.fill(color(255,255,255));
  tLayer.textFont(f, 28);
  tLayer.text("I am very large text. Success!", tPos, 28);
  tLayer.endDraw();
  
  tPos--;
  if (tPos < -500) tPos = 150;
  
  pDraw.copy(tLayer, 0, 0, w, h,
                     0, 0, w, h);
  
  /*
  tLayer.loadPixels();
  
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int loc = x + y * w;
      pDraw.pixels[loc] = tLayer.pixels[loc];  
    }
  }
      
  pDraw.updatePixels();
  */
  //
  //fill(color(255,0,0));
  //text("Hello", 10, 100);

  sendToSigns(pDraw);
}

void solidColors()
{

  int h = 32;
  int w = 150;
 
  int r = 0, g = 0, b = 0;
  
  colorIndex = colorIndex % 16;

  tLayer.beginDraw();
  switch (colorIndex % 8)
  {
    case 0: break;
    case 1: r = 255; break;
    case 2: g = 255; break;
    case 3: b = 255; break;
    case 4: r = 255; g = 255; b = 255; break;
    case 5: r = 200; g = 200; b = 200; break;
    case 6: r = 0; g = 255; b = 255; break;
    case 7: r = 255; g = 0; b = 255; break;
  }
  
  
  for (int i = 0; i < w; i++)
  {
    float p = (float)i / (float)w;  
    if (colorIndex > 7) p = 1;
    tLayer.stroke(color((float)r * p, (float)g * p, (float)b * p));
    tLayer.line(i, 0, i, h);
  }
   
  tLayer.endDraw();
  pDraw.copy(tLayer, 0, 0, w, h,
                     0, 0, w, h);
  sendToSigns(pDraw);
}



void stars()
{

  int h = 32;
  int w = 150;
  
  // tLayer.beginDraw();
  
  // random pixel
  tLayer.beginDraw();
  tLayer.loadPixels();
  for (int i = 0; i < 30; i++)
  {
    int x = (int)random(w);
    int y = (int)random(h);
    int c =  30+ (int)random(220);
    
    tLayer.pixels[x + y * w] = color(random(255), random(255), random(255));
  }
  tLayer.updatePixels();
  tLayer.endDraw();
  
  pDraw.copy(tLayer, 0, 0, w, h,
                     0, 0, w, h);
  sendToSigns(pDraw);
}



void funEffects()
{
  
  int w = 150;
  int h = 32;
  
  // Plasma
  float yv;
  float xv;

  long end_ts = 90;
  
  float o1, o2, o3;
  float timer = (float)millis() / 1000;
 
  
  o1 = (float)(4 - (end_ts - timer)) / 4;
  o2 = (float)(end_ts - timer) / 4;
  o3 = (float)timer;
  
  //pDraw.loadPixels();
  for (int y = 0; y < h; y++) {
 
    yv = (float)y / (float)h - 0.5;
    
    
    for (int x = 0; x < w; x++) {
      int loc = x + y * w;
      
      xv = (float)x / (float)w - 0.5;
      
      
      pDraw.pixels[loc] = color(calc_v(xv, yv, o1), calc_v(xv, yv, o2), calc_v(xv, yv, o3));  
      
      // pDraw.pixels[loc] = color(0,calc_v(-0.5, 0.5, 0),0);
      //color(((sin(x + o1) * cos(y)) + 1) * 126, 0, 0);
    }
    //println("row: " + yv);
  }
      
  pDraw.updatePixels();
  
  sendToSigns(pDraw);
  
  //println("drawing " + millis() + ", " + o1);
  
}

// For plasma effect
int calc_v(float xv, float yv, float offset)
{
    float o_div_3 = offset / 3;
    float cy = yv + 0.5 * cos(o_div_3);
    float xv_sin_half = xv * sin(offset / 2);
    float yv_cos_od3 = yv * cos(o_div_3);
    float cx = xv + 0.5 * sin(offset / 5);
    float v2 = sin(10 * (xv_sin_half + yv_cos_od3) + offset);
    float magic = Hypot(cx, cy) * 10;
    float v1 = sin(xv * 10 + offset);
    float v3 = sin(magic + offset);
    float v = (v1 + v2 + v3) * PI / 2;
    return (int)(127.5 * sin(v) + 127.5);
}

float Hypot(float x, float y) { return sqrt(pow(x, 2) + pow(y, 2)); }


void sendToSigns(PImage m)
{
  for (int i=0; i < numPorts; i++) {    
    // copy a portion of the movie's image to the LED image
    int xoffset = percentage(m.width, ledArea[i].x);
    int yoffset = percentage(m.height, ledArea[i].y);
    int xwidth =  percentage(m.width, ledArea[i].width);
    int yheight = percentage(m.height, ledArea[i].height);
    
    ledImage[i].copy(m, xoffset, yoffset, xwidth, yheight,
                     0, 0, ledImage[i].width, ledImage[i].height);
                     
    // convert the LED image to raw data
    byte[] ledData =  new byte[(ledImage[i].width * ledImage[i].height * 3) + 3];
    image2data(ledImage[i], ledData, ledLayout[i], yoffset);
    
    // HACKHACK; THis has been changed to send the Master frame to all Teensy's
    // It might result in tearing, but doesn't seem to actually harm it in any way.
    if (i == 0 /*|| true*/) {
      ledData[0] = '*';  // first Teensy is the frame sync master
      int usec = (int)((1000000.0 / framerate) * 0.75);
      ledData[1] = (byte)(usec);   // request the frame sync pulse
      ledData[2] = (byte)(usec >> 8); // at 75% of the frame time
    } else {
      ledData[0] = '%';  // others sync to the master board
      ledData[1] = 0;
      ledData[2] = 0;
    }
    // send the raw data to the LEDs  :-)
    ledSerial[i].write(ledData); 
  } 
}

// image2data converts an image to OctoWS2811's raw data format.
// The number of vertical pixels in the image must be a multiple
// of PINS(8).  The data array must be the proper size for the image.
void image2data(PImage image, byte[] data, boolean layout, int ledy) {
  int offset = 3;
  int x, y, xbegin, xend, xinc, mask;

  int linesPerPin = image.height / 8; // XXX this seems to break when using 6 instead of 8
  int pixel[] = new int[PINS];
  
  for (y = 0; y < linesPerPin; y++) {
    if ((y & 1) == (layout ? 0 : 1)) {
      // even numbered rows are left to right
      xbegin = 0;
      xend = image.width;
      xinc = 1;
    } else {
      // odd numbered rows are right to left
      xbegin = image.width - 1;
      xend = -1;
      xinc = -1;
    }
    for (x = xbegin; x != xend; x += xinc) {
      for (int i=0; i < PINS; i++) {
        // fetch 8 pixels from the image, 1 for each pin
        pixel[i] = image.pixels[x + (y + linesPerPin * i) * image.width];
        pixel[i] = colorWiring(pixel[i], ledy + (i * linesPerPin) + y);
      }
      // convert 8 pixels to 24 bytes -- XXX
      for (mask = 0x800000; mask != 0; mask >>= 1) {
        byte b = 0;
        for (int i=0; i < PINS; i++) {
          if ((pixel[i] & mask) != 0) b |= (1 << i);
        }
        data[offset++] = b;
      }
    }
  } 
}

// translate the 24 bit color from RGB to the actual
// order used by the LED wiring.  GRB is the most common.
int colorWiring(int c, int rownum) {
  //   return c;  // RGB
  // Correct gamma
  c = (gamma((c & 0xFF0000) >> 16, 1, rownum) << 16) |
      (gamma((c & 0x00FF00) >> 8, 2, rownum) << 8) |
      (gamma(c & 0x0000FF, 3, rownum));
  
  return ((c & 0xFF0000) >> 8) | ((c & 0x00FF00) << 8) | (c & 0x0000FF); // GRB - most common wiring
}


int gamma(int c, int cID, int rownum) {
  // Correct the gamma of the display -- The display is already almost at max brightness by value 200~ or so, so we adjust this.
  if (cID == 1 && rownum >= 13 && rownum <= 17) return (int)(pow(c, 2) / 255 * 0.75);
  return (int)(pow(c, 2) / 255);
}

// ask a Teensy board for its LED configuration, and set up the info for it.
void serialConfigure(String portName) {
  if (numPorts >= maxPorts) {
    println("too many serial ports, please increase maxPorts");
    errorCount++;
    return;
  }
  try {
    ledSerial[numPorts] = new Serial(this, portName);
    if (ledSerial[numPorts] == null) throw new NullPointerException();
    ledSerial[numPorts].write('?');
  } catch (Throwable e) {
    println("Serial port " + portName + " does not exist or is non-functional");
    errorCount++;
    return;
  }
  delay(50);
  String line = ledSerial[numPorts].readStringUntil(10);
  if (line == null) {
    println("Serial port " + portName + " is not responding.");
    println("Is it really a Teensy 3.0 running VideoDisplay?");
    errorCount++;
    return;
  }
  String param[] = line.split(",");
  if (param.length != 12) {
    println("Error: port " + portName + " did not respond to LED config query");
    errorCount++;
    return;
  }
  // only store the info and increase numPorts if Teensy responds properly
  ledImage[numPorts] = new PImage(Integer.parseInt(param[0]), Integer.parseInt(param[1]), RGB);
  ledArea[numPorts] = new Rectangle(Integer.parseInt(param[5]), Integer.parseInt(param[6]),
                     Integer.parseInt(param[7]), Integer.parseInt(param[8]));
  ledLayout[numPorts] = (Integer.parseInt(param[5]) == 0);
  
  println("Port #" + numPorts + ": Area: " + param[5] + ", " + param[6] + " size " + param[7] + "x" + param[8] + "%");
  
  numPorts++;
}

// draw runs every time the screen is redrawn - show the movie...
void draw() {
  // show the original video
  if (mode == 1) funEffects();
  if (mode == 2) textTest();
  if (mode == 3) solidColors();
  if (mode == 4) stars();
  
  image(pDraw, 0, 80, 600, 128);
  
  // then try to show what was most recently sent to the LEDs
  // by displaying all the images for each port.
  for (int i=0; i < numPorts; i++) {
    // compute the intended size of the entire LED array
    int xsize = percentageInverse(ledImage[i].width, ledArea[i].width);
    int ysize = percentageInverse(ledImage[i].height, ledArea[i].height);
    // computer this image's position within it
    int xloc =  percentage(xsize, ledArea[i].x);
    int yloc =  percentage(ysize, ledArea[i].y) * 2;
    // show what should appear on the LEDs
    image(ledImage[i], 240 - xsize / 2 + xloc, 10 + yloc, 300, 32);
  } 
}

// respond to mouse clicks as pause/play
boolean isPlaying = true;
void mousePressed() {
  switch (mode)
  {
    case 0:
      break;
    case 2:
      tPos = 0;
      break;
    case 3:
      colorIndex++;
      break;
    case 5: 
      break;
  }
}

// scale a number by a percentage, from 0 to 100
int percentage(int num, int percent) {
  double mult = percentageFloat(percent);
  double output = num * mult;
  return (int)output;
}

// scale a number by the inverse of a percentage, from 0 to 100
int percentageInverse(int num, int percent) {
  double div = percentageFloat(percent);
  double output = num / div;
  return (int)output;
}

// convert an integer from 0 to 100 to a float percentage
// from 0.0 to 1.0.  Special cases for 1/3, 1/6, 1/7, etc
// are handled automatically to fix integer rounding.
double percentageFloat(int percent) {
  if (percent == 33) return 1.0 / 3.0;
  if (percent == 17) return 1.0 / 6.0;
  if (percent == 14) return 1.0 / 7.0;
  if (percent == 13) return 1.0 / 8.0;
  if (percent == 11) return 1.0 / 9.0;
  if (percent ==  9) return 1.0 / 11.0;
  if (percent ==  8) return 1.0 / 12.0;
  return (double)percent / 100.0;
}