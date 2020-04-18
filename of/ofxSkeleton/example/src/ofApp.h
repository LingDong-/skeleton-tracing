#pragma once

#include "ofMain.h"
#include "ofxGui.h"
#include "ofxSkeleton.h" // include the library

#define INPUT_WIDTH   240 // input frame dimensions
#define INPUT_HEIGHT  180
#define VIEW_SCALE    3   // upscale the result for viewing

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
  
  // read from webcam/video file for demo
  ofVideoGrabber    cap;
  ofVideoPlayer     vid;
  
  std::vector<std::vector<ofVec2f>> polylines; // the polylines holding the skeleton

  // GUI for tweaking params
  ofxPanel       gui;
  ofxFloatSlider ui_chunkSize; // affacts level of detail
  ofxToggle      ui_drawRects; // visualize rects processed by algorithm
  ofxToggle      ui_useCam;    // use live webcam input
  ofxFloatSlider ui_camThresh; // threshold to binarize webcam input
  
  bool isVidInit; // because ofVideoPlayer::isInitialized() is broken...
  bool isCapInit;
  
  void preprocessWebcam(ofPixels& im); // add some vignette, some bluring and thresholding
  ofImage preprocessed;                // the preprocessed image
};
