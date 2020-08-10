// TraceSkeleton.hx
// Trace skeletonization result into polylines
//
// Lingdong Huang 2020

package traceskeleton;

import haxe.ds.Vector;

class TraceSkeleton{  

  
  /** Binary image thinning (skeletonization) in-place.
    * Implements Zhang-Suen algorithm.
    * http://agcggs680.pbworks.com/f/Zhan-Suen_algorithm.pdf
    * @param im   the binary image
    * @param w    width
    * @param h    height
    */
  public static function thinningZS(im:Vector<Bool>, w:Int, h:Int){
    var diff : Int = 1;
    var marker : Vector<Bool> = new Vector(w*h);
    do {
      diff &= thinningZSIteration(im,marker,w,h,0)?1:0;
      diff &= thinningZSIteration(im,marker,w,h,1)?1:0;
    }while (diff>0);
  }
  // 1 pass of Zhang-Suen thinning 
  static function thinningZSIteration(im:Vector<Bool>, marker:Vector<Bool>, w:Int, h:Int, iter:Int) : Bool {
    var diff : Bool = false;
    for (i in 1...h-1){
      for (j in 1...w-1){
        
        var p2 : Int = im[(i-1)*w+j]  ?1:0;
        var p3 : Int = im[(i-1)*w+j+1]?1:0;
        var p4 : Int = im[(i)*w+j+1]  ?1:0;
        var p5 : Int = im[(i+1)*w+j+1]?1:0;
        var p6 : Int = im[(i+1)*w+j]  ?1:0;
        var p7 : Int = im[(i+1)*w+j-1]?1:0;
        var p8 : Int = im[(i)*w+j-1]  ?1:0;
        var p9 : Int = im[(i-1)*w+j-1]?1:0;
  
        var A : Int = ((p2 == 0 && p3 == 1)?1:0) + ((p3 == 0 && p4 == 1)?1:0) + 
                      ((p4 == 0 && p5 == 1)?1:0) + ((p5 == 0 && p6 == 1)?1:0) + 
                      ((p6 == 0 && p7 == 1)?1:0) + ((p7 == 0 && p8 == 1)?1:0) +
                      ((p8 == 0 && p9 == 1)?1:0) + ((p9 == 0 && p2 == 1)?1:0);
        var B : Int = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
        var m1: Int = iter == 0 ? (p2 * p4 * p6) : (p2 * p4 * p8);
        var m2: Int = iter == 0 ? (p4 * p6 * p8) : (p2 * p6 * p8);
  
        marker[i*w+j] = (A == 1 && (B >= 2 && B <= 6) && m1 == 0 && m2 == 0);
      }
    }
    for (i in 0...h*w){
      var old : Bool = im[i];
      im[i] = im[i] && (!marker[i]);
      if ((!diff) && (im[i] != old)){
        diff = true;
      }
    }
    return diff;
  }
  
  // check if a region has any white pixel
  static function notEmpty(im:Vector<Bool>, W:Int, H:Int, x:Int, y:Int, w:Int, h:Int) : Bool{
    for (i in y...y+h){
      for (j in x...x+w){
        if (im[i*W+j]){
          return true;
        }
      }
    }
    return false;
  }

  

  /**merge ith fragment of second chunk to first chunk
   * @param c0   fragments from first  chunk
   * @param c1   fragments from second chunk
   * @param i    index of the fragment in first chunk
   * @param sx   (x or y) coordinate of the seam
   * @param isv  is vertical, not horizontal?
   * @param mode 2-bit flag, 
   *             MSB = is matching the left (not right) end of the fragment from first  chunk
   *             LSB = is matching the right (not left) end of the fragment from second chunk
   * @return     matching successful?             
   */
  static function mergeImpl(c0:Array<Array<Vector<Int>>>, c1:Array<Array<Vector<Int>>>, i:Int, sx:Int, isv:Bool, mode:Int) : Bool{

    var B0:Bool = (mode >> 1 & 1)>0; // match c0 left
    var B1:Bool = (mode >> 0 & 1)>0; // match c1 left
    var mj:Int = -1;
    var md:Float = 4; // maximum offset to be regarded as continuous
    
    var l1:Int = c1[i].length-1;
    var p1:Vector<Int> = c1[i][B1?0:l1];
    
    if (Math.abs(p1[isv?1:0]-sx)>0){ // not on the seam, skip
      return false;
    }
    
    // find the best match
    for (j in 0...c0.length){
      var l0:Int = c0[j].length-1;
      
      var p0:Vector<Int> = c0[j][B0?0:l0];
      if (Math.abs(p0[isv?1:0]-sx)>1){ // not on the seam, skip
        continue;
      }
      var d:Float = Math.abs(p0[isv?0:1] - p1[isv?0:1]);
      if (d < md){
        mj = j;
        md = d;
      }
    }
    
    if (mj != -1){ // best match is good enough, merge them
      if (B0 && B1){
        c1[i].reverse();
        c0[mj] = c1[i].concat(c0[mj]);
      }else if (!B0 && B1){
        c0[mj] = c0[mj].concat(c1[i]);
      }else if (B0 && !B1){
        c0[mj] = c1[i].concat(c0[mj]);
      }else {
        c1[i].reverse();
        c0[mj] = c0[mj].concat(c1[i]);
      }
      c1.splice(i,1);
      return true;
    }
    return false;
  }
  
  static inline var HORIZONTAL : Int = 1;
  static inline var VERTICAL : Int = 2;
  
  /**merge fragments from two chunks
   * @param c0   fragments from first  chunk
   * @param c1   fragments from second chunk
   * @param sx   (x or y) coordinate of the seam
   * @param dr   merge direction, HORIZONTAL or VERTICAL?
   */
  static function mergeFrags(c0:Array<Array<Vector<Int>>>, c1:Array<Array<Vector<Int>>>, sx:Int, dr:Int) : Void{
    var i : Int = c1.length;
    while (i>0){
      i --;
      if (dr == HORIZONTAL){
        if (mergeImpl(c0,c1,i,sx,false,1))continue;
        if (mergeImpl(c0,c1,i,sx,false,3))continue;
        if (mergeImpl(c0,c1,i,sx,false,0))continue;
        if (mergeImpl(c0,c1,i,sx,false,2))continue;
      }else{
        if (mergeImpl(c0,c1,i,sx,true,1))continue;
        if (mergeImpl(c0,c1,i,sx,true,3))continue;
        if (mergeImpl(c0,c1,i,sx,true,0))continue;
        if (mergeImpl(c0,c1,i,sx,true,2))continue;      
      }
    }
    for (x in c1) c0.push(x);
  }

  /**recursive bottom: turn chunk into polyline fragments;
   * look around on 4 edges of the chunk, and identify the "outgoing" pixels;
   * add segments connecting these pixels to center of chunk;
   * apply heuristics to adjust center of chunk
   *
   * @param im   the bitmap image
   * @param W    width of  image
   * @param H    height of image
   * @param x    left of   chunk
   * @param y    top of    chunk
   * @param w    width of  chunk
   * @param h    height of chunk
   * @return     the polyline fragments
   */
  static function chunkToFrags(im:Vector<Bool>, W:Int, H:Int, x:Int, y:Int, w:Int, h:Int) : Array<Array<Vector<Int>>>{
    var frags : Array<Array<Vector<Int>>> = [];
    var on : Bool = false; // to deal with strokes thicker than 1px
    var li : Int =-1;
    var lj : Int =-1;
    
    // walk around the edge clockwise
    for (k in 0...h+h+w+w-4){
      var i : Int; var j : Int;
      if (k < w){
        i = y+0; j = x+k;
      }else if (k < w+h-1){
        i = y+k-w+1; j = x+w-1;
      }else if (k < w+h+w-2){
        i = y+h-1; j = x+w-(k-w-h+3); 
      }else{
        i = y+h-(k-w-h-w+4); j = x+0;
      }
      if (im[i*W+j]){ // found an outgoing pixel
        if (!on){     // left side of stroke
          on = true;
          var f : Array<Vector<Int>> = [new Vector(2), new Vector(2)];
          f[0][0] = j;     f[0][1] = i;
          f[1][0] = x+Std.int(w/2);  f[1][1] = y+Std.int(h/2);
          frags.push(f);
        }
      }else{
        if (on){// right side of stroke, average to get center of stroke
          frags[frags.length-1][0][0]= Std.int((frags[frags.length-1][0][0]+lj)/2);
          frags[frags.length-1][0][1]= Std.int((frags[frags.length-1][0][1]+li)/2);
          on = false;
        }
      }
      li = i;
      lj = j;
    }
    if (frags.length == 2){ // probably just a line, connect them
      var f : Array<Vector<Int>> = [];
      f.push(frags[0][0]);
      f.push(frags[1][0]);
      frags.shift();
      frags.shift();
      frags.push(f);
    }else if (frags.length > 2){ // it's a crossroad, guess the intersection
      var ms:Int = 0;
      var mi:Int = -1;
      var mj:Int = -1;
      // use convolution to find brightest blob
      for (i in y+1...y+h-1){
        for (j in x+1...x+w-1){
          var s : Int = 
            (im[i*W-W+j-1]?1:0) + (im[i*W-W+j]?1:0) + (im[i*W-W+j-1+1]?1:0)+
            (im[i*W+j-1]?1:0) +   (im[i*W+j]?1:0) +   (im[i*W+j+1]?1:0)+
            (im[i*W+W+j-1]?1:0) + (im[i*W+W+j]?1:0) + (im[i*W+W+j+1]?1:0);
          if (s > ms){
            mi = i;
            mj = j;
            ms = s;
          }else if (s == ms && Math.abs(j-(x+w/2))+Math.abs(i-(y+h/2)) < Math.abs(mj-(x+w/2))+Math.abs(mi-(y+h/2))){
            mi = i;
            mj = j;
            ms = s;
          }
        }
      }
      if (mi != -1){
        for (i in 0...frags.length){
          frags[i][1][0] = mj;
          frags[i][1][1] = mi;
        }
      }
    }
    return frags;
  
  }
    
  /**Trace skeleton from thinning result.
   * Algorithm:
   * 1. if chunk size is small enough, reach recursive bottom and turn it into segments
   * 2. attempt to split the chunk into 2 smaller chunks, either horizontall or vertically;
   *    find the best "seam" to carve along, and avoid possible degenerate cases
   * 3. recurse on each chunk, and merge their segments
   *
   * @param im      the bitmap image
   * @param W       width of  image
   * @param H       height of image
   * @param x       left of   chunk
   * @param y       top of    chunk
   * @param w       width of  chunk
   * @param h       height of chunk
   * @param csize   chunk size
   * @param maxIter maximum number of iterations
   * @param rects   if not null, will be populated with chunk bounding boxes (e.g. for visualization)
   * @return        an array of polylines
  */
  public static function traceSkeleton(im : Vector<Bool>, W:Int, H:Int, x:Int, y:Int, w:Int, h:Int, csize:Int, maxIter:Int, rects:Array<Vector<Int>>) : Array<Array<Vector<Int>>>{

    var frags : Array<Array<Vector<Int>>> = [];
    
    if (maxIter == 0){ // gameover
      return frags;
    }
    if (w <= csize && h <= csize){ // recursive bottom
      return frags.concat(chunkToFrags(im,W,H,x,y,w,h));
    }
   
    var ms : Int = W+H; // number of white pixels on the seam, less the better
    var mi : Int = -1;  // horizontal seam candidate
    var mj : Int = -1;  // vertical   seam candidate
    
    if (h > csize){ // try splitting top and bottom
      for (i in y+3...y+h-3){
        if (im[i*W+x] ||im[(i-1)*W+x] ||im[i*W+x+w-1] ||im[(i-1)*W+x+w-1]){
          continue;
        }
        var s : Int = 0;
        for (j in x...x+w){
          s += im[i*W+j]?1:0;
          s += im[(i-1)*W+j]?1:0;
        }
        if (s < ms){
          ms = s; mi = i;
        }else if (s == ms && Math.abs(i-(y+h/2))<Math.abs(mi-(y+h/2))){
          // if there is a draw (very common), we want the seam to be near the middle
          // to balance the divide and conquer tree
          ms = s; mi = i;
        }
      }
    }
    
    if (w > csize){ // same as above, try splitting left and right
      for (j in x+3...x+w-3){
        if (im[W*y+j]||im[W*(y+h)-W+j]||im[W*y+j-1]||im[W*(y+h)-W+j-1]){
          continue;
        }
        var s : Int = 0;
        for (i in y...y+h){
          s += im[i*W+j]?1:0;
          s += im[i*W+j-1]?1:0;
        }
        if (s < ms){
          ms = s;
          mi = -1; // horizontal seam is defeated
          mj = j;
        }else if (s == ms && Math.abs(j-(x+w/2))<Math.abs(mj-(x+w/2))){
          ms = s;
          mi = -1;
          mj = j;
        }
      }
    }

    if (h > csize && mi != -1){ // split top and bottom
      var L:Vector<Int> = new Vector(4); // new chunk bounding boxes
      L[0]=x;L[1]=y;L[2]=w;L[3]=mi-y;    
      var R:Vector<Int> = new Vector(4);
      R[0]=x;R[1]=mi;R[2]=w;R[3]=y+h-mi;
      
      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){ // if there are no white pixels, don't waste time
        if(rects!=null)rects.push(L);
        frags = traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects); // recurse
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.push(R);
        mergeFrags(frags,traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mi,VERTICAL);
      }
    }else if (w > csize && mj != -1){ // split left and right
      var L:Vector<Int> = new Vector(4);
      L[0]=x;L[1]=y;L[2]=mj-x;L[3]=h;    
      var R:Vector<Int> = new Vector(4);
      R[0]=mj;R[1]=y;R[2]=x+w-mj;R[3]=h;

      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){
        if(rects!=null)rects.push(L);
        frags = traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects);
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.push(R);
        mergeFrags(frags,traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mj,HORIZONTAL);
      }
    }

    if (mi == -1 && mj == -1){ // splitting failed! do the recursive bottom instead
      frags = chunkToFrags(im,W,H,x,y,w,h);
    }
    return frags;
  }

  /**First apply raster thinning (skeletonization), then vectorize the result into polylines
   * @param im      the bitmap image
   * @param W       width of  image
   * @param H       height of image
   * @param csize   chunk size
   * @return        an array of polylines
  */
  public static function trace(im : Vector<Bool>, W:Int, H:Int, csize:Int) : Array<Array<Vector<Int>>>{
    thinningZS(im,W,H);
    return traceSkeleton(im,W,H,0,0,W,H,csize,W*H,null);
  }
}