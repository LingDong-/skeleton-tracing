// trace_skeleton.vanilla.js
// Trace skeletonization result into polylines
//
// Lingdong Huang 2020


var TraceSkeleton = new function(){ var that = this; 
  
  /** Binary image thinning (skeletonization) in-place.
    * Implements Zhang-Suen algorithm.
    * http://agcggs680.pbworks.com/f/Zhan-Suen_algorithm.pdf
    * @param im   the binary image
    * @param w    width
    * @param h    height
    */
  that.thinningZS = function(im, w, h){
    var diff = true;
    do {
      diff &= thinningZSIteration(im,w,h,0);
      diff &= thinningZSIteration(im,w,h,1);
    }while (diff);
  }
  // 1 pass of Zhang-Suen thinning 
  function thinningZSIteration(im, w, h, iter) {
    var diff = 0
    for (var i = 1; i < h-1; i++){
      for (var j = 1; j < w-1; j++){
        
        var p2 = im[(i-1)*w+j]  &1;
        var p3 = im[(i-1)*w+j+1]&1;
        var p4 = im[(i)*w+j+1]  &1;
        var p5 = im[(i+1)*w+j+1]&1;
        var p6 = im[(i+1)*w+j]  &1;
        var p7 = im[(i+1)*w+j-1]&1;
        var p8 = im[(i)*w+j-1]  &1;
        var p9 = im[(i-1)*w+j-1]&1;
  
        var A  = (p2 == 0 && p3 == 1) + (p3 == 0 && p4 == 1) + 
                 (p4 == 0 && p5 == 1) + (p5 == 0 && p6 == 1) + 
                 (p6 == 0 && p7 == 1) + (p7 == 0 && p8 == 1) +
                 (p8 == 0 && p9 == 1) + (p9 == 0 && p2 == 1);
        var B  = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
        var m1 = iter == 0 ? (p2 * p4 * p6) : (p2 * p4 * p8);
        var m2 = iter == 0 ? (p4 * p6 * p8) : (p2 * p6 * p8);
  
        if (A == 1 && (B >= 2 && B <= 6) && m1 == 0 && m2 == 0)
          im[i*w+j] |= 2;
      }
    }
    for (var i = 0; i < h*w; i++){
      var marker = im[i]>>1;
      var old = im[i]&1;
      im[i] = old & (!marker);
      if ((!diff) && (im[i] != old)){
        diff = 1;
      }
    }
    return diff;
  }
  
  // check if a region has any white pixel
  function notEmpty(im, W, H, x, y, w, h){
    for (var i = y; i < y+h; i++){
      for (var j = x; j < x+w; j++){
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
  function mergeImpl(c0, c1, i, sx, isv, mode){

    var B0 = (mode >> 1 & 1)>0; // match c0 left
    var B1 = (mode >> 0 & 1)>0; // match c1 left
    var mj = -1;
    var md = 4; // maximum offset to be regarded as continuous
    
    var l1 = c1[i].length-1;
    var p1 = c1[i][B1?0:l1];
    
    if (Math.abs(p1[isv?1:0]-sx)>0){ // not on the seam, skip
      return false;
    }
    
    // find the best match
    for (var j = 0; j < c0.length; j++){
      var l0 = c0[j].length-1;
      
      var p0 = c0[j][B0?0:l0];
      if (Math.abs(p0[isv?1:0]-sx)>1){ // not on the seam, skip
        continue;
      }
      var d = Math.abs(p0[isv?0:1] - p1[isv?0:1]);
      if (d < md){
        mj = j;
        md = d;
      }
    }
    
    if (mj != -1){ // best match is good enough, merge them
      if (B0 && B1){
        c1[i].reverse();
        c0[mj]=c1[i].concat(c0[mj]);
      }else if (!B0 && B1){
        c0[mj]=c0[mj].concat(c1[i]);
      }else if (B0 && !B1){
        c0[mj]=c1[i].concat(c0[mj]);
      }else {
        c1[i].reverse();
        c0[mj]=c0[mj].concat(c1[i]);
      }
      c1.splice(i,1);
      return true;
    }
    return false;
  }
  
  var HORIZONTAL = 1;
  var VERTICAL = 2;
  
  /**merge fragments from two chunks
   * @param c0   fragments from first  chunk
   * @param c1   fragments from second chunk
   * @param sx   (x or y) coordinate of the seam
   * @param dr   merge direction, HORIZONTAL or VERTICAL?
   */
  function mergeFrags(c0, c1, sx, dr){
    for (var i = c1.length-1; i>=0; i--){
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
    c1.map(x=>c0.push(x));
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
  function chunkToFrags(im, W, H, x, y, w, h){
    var frags = [];
    var on = false; // to deal with strokes thicker than 1px
    var li=-1, lj=-1;
    
    // walk around the edge clockwise
    for (var k = 0; k < h+h+w+w-4; k++){
      var i, j;
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
          frags.push([[j,i],[Math.floor(x+w/2),Math.floor(y+h/2)]])
        }
      }else{
        if (on){// right side of stroke, average to get center of stroke
          frags[frags.length-1][0][0] = Math.floor((frags[frags.length-1][0][0]+lj)/2);
          frags[frags.length-1][0][1] = Math.floor((frags[frags.length-1][0][1]+li)/2);
          on = false;
        }
      }
      li = i;
      lj = j;
    }

    if (frags.length == 2){ // probably just a line, connect them
      frags = [[frags[0][0],frags[1][0]]]
    }else if (frags.length > 2){ // it's a crossroad, guess the varersection
      var ms = 0;
      var mi = -1;
      var mj = -1;
      // use convolution to find brightest blob
      for (var i = y+1; i < y+h-1; i++){
        for (var j = x+1; j < x+w-1; j++){
          var s = 
            (im[i*W-W+j-1]) + (im[i*W-W+j]) + (im[i*W-W+j-1+1])+
            (im[i*W+j-1]) +   (im[i*W+j]) +   (im[i*W+j+1])+
            (im[i*W+W+j-1]) + (im[i*W+W+j]) + (im[i*W+W+j+1]);
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
        for (var i = 0; i < frags.length; i++){
          frags[i][1]=[mj,mi];
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
  that.traceSkeleton = function(im, W, H, x, y, w, h, csize, maxIter, rects){

    var frags = [];
    
    if (maxIter == 0){ // gameover
      return frags;
    }
    if (w <= csize && h <= csize){ // recursive bottom

      return chunkToFrags(im,W,H,x,y,w,h);
    }
   
    var ms = W+H; // number of white pixels on the seam, less the better
    var mi = -1; // horizontal seam candidate
    var mj = -1; // vertical   seam candidate
    
    if (h > csize){ // try splitting top and bottom
      for (var i = y+3; i < y+h-3; i++){
        if (im[i*W+x] ||im[(i-1)*W+x] ||im[i*W+x+w-1] ||im[(i-1)*W+x+w-1]){
          continue;
        }
        var s = 0;
        for (var j = x; j < x+w; j++){
          s += im[i*W+j];
          s += im[(i-1)*W+j];
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
      for (var j = x+3; j < x+w-3; j++){
        if (im[W*y+j]||im[W*(y+h)-W+j]||im[W*y+j-1]||im[W*(y+h)-W+j-1]){
          continue;
        }
        var s = 0;
        for (var i = y; i < y+h; i++){
          s += im[i*W+j];
          s += im[i*W+j-1];
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
      var L = [x,y,w,mi-y];    // new chunk bounding boxes
      var R = [x,mi,w,y+h-mi];
      
      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){ // if there are no white pixels, don't waste time
        if(rects!=null)rects.push(L);
        frags = that.traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects); // recurse
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.push(R);
        mergeFrags(frags,that.traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mi,VERTICAL);
      }
    }else if (w > csize && mj != -1){ // split left and right
      var L = [x,y,mj-x,h];
      var R = [mj,y,x+w-mj,h];
      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){
        if(rects!=null)rects.push(L);
        frags = that.traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects);
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.push(R);
        mergeFrags(frags,that.traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mj,HORIZONTAL);
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
  that.trace = function(im,W,H,csize){
    that.thinningZS(im,W,H);
    var rects = []
    var polys = that.traceSkeleton(im,W,H,0,0,W,H,csize,999,rects);

    return {
      rects:rects,
      polylines:polys,
      width:W,
      height:H,
    }
  }

  //compatibility with wasm api
  that.onload = function(f){
    f();
  }
  that.fromBoolArray = function(im,w,h){
    return that.trace(im.map(x=>(x?1:0)),w,h,10);
  }
  that.fromCharString = function(im,W,H){
    return that.trace(im.split('').map(x=>x.charCodeAt(0)),w,h,10);
  }
  that.fromImageData = function(im){
    var w = im.width;
    var h = im.height;
    var data = im.data;
    var m = [];
    for (var i = 0; i < data.length; i+=4){
      if (data[i]){
        m.push(1)
      }else{
        m.push(0)
      }
    }
    return that.trace(m,w,h,10);
  }
  that.fromCanvas = function(im){
    var ctx = im.getContext('2d');
    var imdata = ctx.getImageData(0,0,im.width,im.height);
    return that.fromImageData(imdata);
  }
  that.visualize = function(ret,args){
    var r = ret.rects;
    var p = ret.polylines;

    if (args == undefined){args = {}}
    var s = args.scale == undefined ? 1 : args.scale;
    var sw = args.strokeWidth == undefined ? 1 : args.strokeWidth;
    var dr = args.rects == undefined ? 1 : 0;
    var kpt = args.keypoints = undefined ? 0 : 1;

    var svg = `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="${ret.width*s}" height="${ret.height*s}">`

    if (dr){
      for (var i = 0; i < r.length; i++){
        svg += `<rect fill="none" stroke="gray" x="${r[i][0]*s}" y="${r[i][1]*s}" width="${r[i][2]*s}" height="${r[i][3]*s}" />`
      }
    }
    for (var i = 0; i < p.length; i++){
      svg += `<path fill="none" stroke-width="${sw}" stroke="rgb(${Math.floor(Math.random()*200)},${Math.floor(Math.random()*200)},${Math.floor(Math.random()*200)})" d="M${p[i].map(x=>x[0]*s+","+x[1]*s).join(" L")}"/>`
    }
    if (kpt){
      for (var i = 0; i < p.length; i++){
        for (var j = 0; j < p[i].length; j++){
          svg += `<rect fill="none" stroke="red" x="${p[i][j][0]*s-5}" y="${p[i][j][1]*s-5}" width="10" height="10"/>`
        }
      }
    }

    svg += "</svg>"
    return svg;
  }

}
