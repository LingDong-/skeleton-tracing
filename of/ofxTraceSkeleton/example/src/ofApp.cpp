#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
  
  // set up the GUI for tweaking params
  gui.setup();
  gui.add(ui_useCam.setup   ("use webcam",   false));        //use live webcam?
  gui.add(ui_drawRects.setup("draw rects",   false));        //visualize rects processd by algorithm?
  gui.add(ui_chunkSize.setup("chunk size",   10, 5, 20));    //affects level of detail
  gui.add(ui_camThresh.setup("webcam thresh",128, 0, 512));  //threshold to binarize webcam input
  gui.setPosition(INPUT_WIDTH*VIEW_SCALE,0);
  
  preprocessed.allocate(INPUT_WIDTH,INPUT_HEIGHT,OF_IMAGE_COLOR); // pre-allocate the preprocessed image
}

//--------------------------------------------------------------
void ofApp::update(){
  // update parameters from GUI
  ofxTraceSkeleton::CHUNK_SIZE  = (int)ui_chunkSize;
  ofxTraceSkeleton::SAVE_RECTS  = (int)ui_drawRects;
  
  ofPixels im; // this is the input image (as ofPixels)
               // only the first channel will be used if there are multiple
               // (pixel value > 127) -> foreground, (pixel value <= 127) -> background
  
  if (ui_useCam){
    if (!isCapInit){
      cap.setup(INPUT_WIDTH,INPUT_HEIGHT);
      isCapInit = true;
    }
    cap.update();
    
    if (cap.isFrameNew()){
      im = cap.getPixels();
      im.resize(INPUT_WIDTH,INPUT_HEIGHT);
      preprocessWebcam(im);
      
      // ========================
      // Trace the Skeleton!
      // ========================
      polylines = ofxTraceSkeleton::trace(preprocessed.getPixels());
      // ofxTraceSkeleton::trace returns a vector<vector<ofVec2f>>
    }

    
  }else{
    if (!isVidInit){
      vid.load("utensils.mp4");
      vid.play();
      vid.setLoopState(OF_LOOP_NORMAL);
      isVidInit = true;
    }
    vid.update();
    
    if (vid.isFrameNew()){
      im = vid.getPixels();
      im.resize(INPUT_WIDTH,INPUT_HEIGHT);
      
      // ========================
      // Trace the Skeleton!
      // ========================
      polylines = ofxTraceSkeleton::trace(im);
    }
  }
  

}

//--------------------------------------------------------------
void ofApp::draw(){
  ofPushMatrix();
  ofScale(VIEW_SCALE);
  
  if (ui_useCam){
    if (preprocessed.isAllocated()){
      preprocessed.draw(0,0,INPUT_WIDTH,INPUT_HEIGHT);
    }
  }else{
    vid.draw(0,0,INPUT_WIDTH,INPUT_HEIGHT);
  }
  
  // quick visualization for debugging
  if (ui_drawRects){
    // ofxTraceSkeleton::getRects() gives the rects from previous run
    // returns a vector<ofRectangle>
    // costs linear time, as it is pealed from internal datastructure
    // so save it intead of making repeated calls.
    // also make sure ofxTraceSkeleton::SAVE_RECTS == 1 otherwise this will be empty
    ofxTraceSkeleton::draw(polylines, ofxTraceSkeleton::getRects());
  }else{
    // ofxTraceSkeleton::draw can also be called without the rects
    ofxTraceSkeleton::draw(polylines);
  }
  
  ofPopMatrix();
  ofDrawBitmapStringHighlight("FPS: " + ofToString(ofGetFrameRate(),2), 10, 20);
  
  gui.draw();
}

// some blurring, vignetting and thresholding for webcam input
// not required for using the library, not required to understand
// just makes it look nicer for the demo
void ofApp::preprocessWebcam(ofPixels& im){
  float n =INPUT_WIDTH+INPUT_HEIGHT;
  for (int i = 0; i < im.size(); i+=3){
    int x = (i/3)%INPUT_WIDTH;
    int y = (i/3)/INPUT_WIDTH;
    float c = 0;
    int g;
    if (x < 3 || x >= INPUT_WIDTH-3 || y < 3 || y >= INPUT_HEIGHT-3){
      g = 0;
    }else{
      // 7x7 box blur
      for (int j = y-3; j < y+3; j++){
        for (int k = x-3; k < x+3; k++){
          c += (float)im[(j*INPUT_WIDTH+k)*3]/49.0;
        }
      }
      // calculate vignette
      float dx =x-INPUT_WIDTH/2;
      float dy =y-INPUT_HEIGHT/2;
      float z = sqrt(dx*dx+dy*dy);
      float d = 1-z/(n/0.75);
      // threshold
      g = (ui_camThresh<256)?((d*c)>ui_camThresh?255:0):(((d*c)>ui_camThresh-256)?0:255);
    }
    preprocessed.getPixels()[i]   = g;
    preprocessed.getPixels()[i+1] = g;
    preprocessed.getPixels()[i+2] = (int)((float)im[i]*0.5+(float)g*0.5);
  }
  preprocessed.update();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
