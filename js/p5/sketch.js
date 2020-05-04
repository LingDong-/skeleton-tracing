
var WIDTH = 250;
var HEIGHT = 200;

var img;
var canv;
var pg;

function preload(){
  img = loadImage("https://raw.githubusercontent.com/LingDong-/skeleton-tracing/master/test_images/horse_r.png");
}

function setup() {
  pixelDensity(1); // preventing p5 from automatically switching to 2x resolution for retina screens

  createCanvas(WIDTH,HEIGHT);

  pg = createGraphics(WIDTH,HEIGHT);
  pg.background(0);
  pg.image(img,0,0);
}

function draw() {
  
  // use mouse to draw
  pg.stroke(255);
  pg.strokeWeight(10);
  pg.line(pmouseX,pmouseY,mouseX,mouseY);

  // trace the skeleton
  var {polylines,rects} = TraceSkeleton.fromCanvas(pg.canvas);
  
  image(pg,0,0);


  // visualize

  noFill();
  // draw the rects
  stroke(128,20);
  for (var i = 0; i < rects.length; i++){
    rect(rects[i][0],rects[i][1],rects[i][2],rects[i][3])
  }
  // draw the polylines
  stroke(255,0,0);
  for (var i = 0; i < polylines.length; i++){
    for (var j = 1; j < polylines[i].length; j++){
      line(polylines[i][j-1][0],polylines[i][j-1][1],polylines[i][j][0],polylines[i][j][1])
    }
  }

}