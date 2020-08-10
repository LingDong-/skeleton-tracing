import haxe.ds.Vector;
import haxe.Timer;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.Assets;
import openfl.Lib;

import traceskeleton.TraceSkeleton;

class Main extends Sprite {

  public function new () {
    
    super ();

    var bitmapData = Assets.getBitmapData ("assets/opencv-thinning-src-img.png");
    var W = bitmapData.width;
    var H = bitmapData.height;
    Lib.application.window.resize(W*2,H*2);

    var im:Vector<Bool> = new Vector(W*H);

    for (i in 0...H){
      for (j in 0...W){
        // im[i*W+j] = bitmapData.getPixel32(j,i)!=0;
        im[i*W+j] = bitmapData.getPixel(j,i)&255 > 128;
      }
    }

    TraceSkeleton.thinningZS(im,W,H);

    // for (i in 0...H){
    //   for (j in 0...W){
    //     if (im[i*W+j]){
    //       bitmapData.setPixel32(j,i,0xFFFFFFFF);
    //     }else{
    //       bitmapData.setPixel32(j,i,0xFF000000);
    //     }
    //   }
    // }

    var bitmap = new Bitmap(bitmapData);
    bitmap.scaleX = 2;
    bitmap.scaleY = 2;
    addChild(bitmap);

    // var polylines = TraceSkeleton.trace(im,W,H,8);

    var rects:Array<Vector<Int>> = [];

    var t0 = Timer.stamp();
    var polylines:Array<Array<Vector<Int>>> = [];

    polylines = TraceSkeleton.traceSkeleton(im,W,H,0,0,W,H,8,999,rects);

    // for (i in 0...1000) polylines = TraceSkeleton.traceSkeleton(im,W,H,0,0,W,H,8,999,null);
    
    trace(Timer.stamp()-t0);

    trace(polylines.length);

    var s = new Sprite();
    s.scaleX = 2;
    s.scaleY = 2;
    
    s.graphics.lineStyle(0.5, 0x7F7F7F);

    for (i in 0...rects.length){
      s.graphics.drawRect(rects[i][0],rects[i][1],rects[i][2],rects[i][3]);
    }

    s.graphics.lineStyle(1, 0xFF0000);

    for (i in 0...polylines.length){
      for (j in 0...polylines[i].length){
        if (j == 0){
          s.graphics.moveTo(polylines[i][j][0],polylines[i][j][1]);
        }else{
          s.graphics.lineTo(polylines[i][j][0],polylines[i][j][1]);
        }
      }
    }
    addChild(s);

  }

}