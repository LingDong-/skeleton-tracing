import java.io.*;
import java.lang.reflect.*;
import java.lang.*;
import java.awt.geom.AffineTransform;
import java.util.*;

import traceskeleton.*;

int scl = 2;

PGraphics pg;
ArrayList<ArrayList<int[]>>  c;
ArrayList<int[]> rects = new ArrayList<int[]>();
boolean[]  im;
int W = 300;
int H = 300;
PImage img;

void setup(){
  size(600,600);
  img = loadImage("opencv-thinning-src-img.png");
  
  pg = createGraphics(W,H);
  pg.beginDraw();
  pg.background(0);
  pg.image(img,0,0);
  pg.endDraw();
  
  im = new boolean[W*H];
  
}
void draw(){

  pg.beginDraw();
  pg.noFill();
  pg.strokeWeight(10);
  pg.stroke(255);
  pg.line(pmouseX/scl, pmouseY/scl, mouseX/scl,mouseY/scl);
  
  pg.loadPixels();
  for (int i = 0; i < im.length; i++){
    im[i] = (pg.pixels[i]>>16&0xFF)>128;
  }
  TraceSkeleton.thinningZS(im,W,H);

  pg.endDraw();

  rects.clear();
  c = TraceSkeleton.traceSkeleton(im,W,H,0,0,W,H,10,999,rects);

  pushMatrix();
  scale(scl);
  image(pg,0,0);
  popMatrix();
  noFill();
  
  for (int i = 0; i < rects.size(); i++){
    stroke(255,0,0);
    rect(rects.get(i)[0]*scl,rects.get(i)[1]*scl,rects.get(i)[2]*scl,rects.get(i)[3]*scl);
  }
  strokeWeight(1);
  for (int i = 0; i < c.size(); i++){
    stroke(random(255),random(255),random(255));
    //strokeWeight(random(10));
    beginShape();
    //rect(c.get(i).P.get(0)[0]*scl,c.get(i).P.get(0)[1]*scl,2,2);
    for (int j = 0; j < c.get(i).size(); j++){
      vertex(c.get(i).get(j)[0]*scl,c.get(i).get(j)[1]*scl);
      rect(c.get(i).get(j)[0]*scl-2,c.get(i).get(j)[1]*scl-2,4,4);
    }
    endShape();
    
  }
  fill(255,0,0);
  text(frameRate,0,10);
 
}
