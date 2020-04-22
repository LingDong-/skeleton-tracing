#!/usr/bin/swift
import AppKit

let HORIZONTAL : Int = 1
let VERTICAL   : Int = 2


//================================
// RASTER SKELETONIZATION
//================================
// Binary image thinning (skeletonization) in-place.
// Implements Zhang-Suen algorithm.
// http://agcggs680.pbworks.com/f/Zhan-SuenAlgorithm.pdf

func thinningZSIteration(im : inout [UInt8], W : Int, H : Int, iter : Int) -> Bool{
    var diff : Bool = false;
    for i in 1..<H-1 {
        for j in 1..<W-1 {
            let p2 = im[(i-1)*W+j]   & 1;
            let p3 = im[(i-1)*W+j+1] & 1;
            let p4 = im[(i)*W+j+1]   & 1;
            let p5 = im[(i+1)*W+j+1] & 1;
            let p6 = im[(i+1)*W+j]   & 1;
            let p7 = im[(i+1)*W+j-1] & 1;
            let p8 = im[(i)*W+j-1]   & 1;
            let p9 = im[(i-1)*W+j-1] & 1;
            var A = 0;
            if (p2 == 0 && p3 == 1) {A+=1;}; if (p3 == 0 && p4 == 1){A+=1;};
            if (p4 == 0 && p5 == 1) {A+=1;}; if (p5 == 0 && p6 == 1){A+=1;};
            if (p6 == 0 && p7 == 1) {A+=1;}; if (p7 == 0 && p8 == 1){A+=1;};
            if (p8 == 0 && p9 == 1) {A+=1;}; if (p9 == 0 && p2 == 1){A+=1;};
            let B  = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
            let m1 = iter == 0 ? (p2 * p4 * p6) : (p2 * p4 * p8);
            let m2 = iter == 0 ? (p4 * p6 * p8) : (p2 * p6 * p8);
            if (A == 1 && (B >= 2 && B <= 6) && m1 == 0 && m2 == 0){
              im[i*W+j] |= 2;
            }
        }
    }
    for i in 0..<H*W {
        let marker = (im[i]>>1) != 0;
        let old = im[i]&1;
        if (old != 0 && (!marker)){
            im[i] = 1
        }else{
            im[i] = 0
        }
        if ((!diff) && (im[i] != old)){
            diff = true;
        }
    }
    return diff;
}

func thinningZS(im: inout [UInt8], W : Int, H : Int){
    var diff : Bool = true;
    while (true) {
        diff = diff && thinningZSIteration(im:&im,W:W,H:H,iter:0);
        diff = diff && thinningZSIteration(im:&im,W:W,H:H,iter:1);
        if (!diff){
            break;
        }
    }
}

//================================
// MAIN ALGORITHM
//================================

// check if a region has any white pixel
func notEmpty(im : inout [UInt8], W : Int, H : Int, x : Int, y : Int, w : Int, h : Int) -> Bool {
  for i in y..<y+h {
    for j in x..<x+w {
      if (im[i*W+j] != 0){
        return true;
      }
    }
  }
  return false;
}


/**merge ith fragment of second chunk to first chunk
 * @param c0   fragments from  first  chunk
 * @param c1i  ith fragment of second chunk
 * @param sx   (x or y) coordinate of the seam
 * @param isv  is vertical, not horizontal?
 * @param mode 2-bit flag, 
 *             MSB = is matching the left (not right) end of the fragment from first  chunk
 *             LSB = is matching the right (not left) end of the fragment from second chunk
 * @return     matching successful?             
 */
func mergeImpl(c0 : inout [[[Int]]], c1 : inout [[[Int]]], i : Int, sx : Int, isv : Bool, mode : Int) -> Bool {
    let b0 : Bool = (mode >> 1 & 1)>0; // match c0 left
    let b1 : Bool = (mode >> 0 & 1)>0; // match c1 left
    var mj = -1;
    var md = 4;
    let p1 = c1[i][b1 ? 0 : c1[i].count-1]
    if (abs(p1[isv ? 1 : 0]-sx)>0){
        return false;
    }
    for j in 0..<c0.count {
        let p0 = c0[j][b0 ? 0 : c0[j].count-1]
        if (abs(p0[isv ? 1 : 0]-sx)>1){
            continue;
        }
        let d = abs(p0[isv ? 0 : 1]-p1[isv ? 0 : 1])
        if (d < md){
            mj = j
            md = d
        }
    }
    if (mj != -1){
        if (b0 && b1){
            c1[i].reverse()
            c0[mj] = c1[i] + c0[mj]
        }else if (!b0 && b1){
            c0[mj]+=c1[i]
        }else if (b0 && !b1){
            c0[mj] = c1[i] + c0[mj]
        }else{
            c1[i].reverse()
            c0[mj] += c1[i]
        }
        c1.remove(at:i);
        return true;
    }
    return false;
}
/**merge fragments from two chunks
 * @param c0   fragments from first  chunk
 * @param c1   fragments from second chunk
 * @param sx   (x or y) coordinate of the seam
 * @param dr   merge direction, HORIZONTAL or VERTICAL?
 */
func mergeFrags(c0 : inout [[[Int]]], c1 : inout [[[Int]]], sx : Int, dr : Int){
    for i in (0..<c1.count).reversed() {
        if (dr == HORIZONTAL){
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:false,mode:1)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:false,mode:3)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:false,mode:0)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:false,mode:2)){continue;}
        }else{
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:true, mode:1)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:true, mode:3)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:true, mode:0)){continue;}
            if (mergeImpl(c0:&c0,c1:&c1,i:i,sx:sx,isv:true, mode:2)){continue;}
        }
    }
    c0 += c1;
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
 func chunkToFrags(im : inout [UInt8], W : Int, H : Int, x : Int, y : Int, w : Int, h : Int) -> [[[Int]]] {

    var frags : [[[Int]]] = [];
    var on : Bool = false;
    var li : Int = -1;
    var lj : Int = -1;

    for k in 0..<h+h+w+w-4 {
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
        if (im[i*W+j] > 0){ // found an outgoing pixel
            if (!on){       // left side of stroke
                on = true;
                frags.append([[j,i],[x+w/2,y+h/2]])
            }
        }else{
            if (on){ // right side of stroke, average to get center of stroke
                frags[frags.count-1][0][0] = (frags[frags.count-1][0][0]+lj)/2
                frags[frags.count-1][0][1] = (frags[frags.count-1][0][1]+li)/2
                on = false
            }
        }
        li = i;
        lj = j;
    }

    if (frags.count == 2){  // probably just a line, connect them
        frags = [[frags[0][0], frags[1][0]]]

    }else if (frags.count > 2){ // it's a crossroad, guess the intersection

        var ms : Int = 0;
        var mi : Int = -1;
        var mj : Int = -1;
        // use convolution to find brightest blob
        for i in y+1..<y+h-1 {
            for j in x+1..<x+w-1 {
                var s : Int = 0
                s += Int(im[i*W-W+j-1])  
                s += Int(im[i*W-W+j])    
                s += Int(im[i*W-W+j-1+1])
                s += Int(im[i*W+j-1])     
                s += Int(im[i*W+j])      
                s += Int(im[i*W+j+1])    
                s += Int(im[i*W+W+j-1])  
                s += Int(im[i*W+W+j])    
                s += Int(im[i*W+W+j+1]) 
                if (s > ms){
                    mi = i;
                    mj = j;
                    ms = s;
                }else if (s == ms && abs(j-(x+w/2))+abs(i-(y+h/2)) < abs(mj-(x+w/2))+abs(mi-(y+h/2))){
                    mi = i;
                    mj = j;
                    ms = s;
                }
            }
        }
        if (mi != -1){
            for i in 0..<frags.count {
                frags[i][1] = [mj,mi];
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
func traceSkeleton(im : inout [UInt8], W : Int, H : Int, x : Int, y : Int, w : Int, h : Int, csize : Int, maxIter : Int) -> [[[Int]]]{

    if (maxIter == 0){
        return [[[]]]
    }

    if (w <= csize && h <= csize){
        return chunkToFrags(im:&im,W:W,H:H,x:x,y:y,w:w,h:h)
    }

    var ms : Int = W+H; // number of white pixels on the seam, less the better
    var mi : Int = -1;
    var mj : Int = -1;
    if (h > csize){ // try splitting top and bottom
        for i in y+3..<y+h-3 {
            if (im[i*W+x]>0 || im[(i-1)*W+x]>0 || im[i*W+x+w-1]>0 || im[(i-1)*W+x+w-1]>0){
                continue;
            }
            var s : Int = 0;
            for j in x..<x+w {
                s += Int(im[i*W+j]);
                s += Int(im[(i-1)*W+j]);
            }
            if (s < ms){
                ms = s; mi = i;
            }else if (s == ms && abs(i-(y+h/2))<abs(mi-(y+h/2))){
                // if there is a draw (very common), we want the seam to be near the middle
                // to balance the divide and conquer tree
                ms = s; mi = i;
            }
        }
    }

    if (w > csize){ // same as above, try splitting left and right
        for j in x+3..<x+w-3 {
            if (im[W*y+j]>0 || im[W*(y+h)-W+j]>0 || im[W*y+j-1]>0 || im[W*(y+h)-W+j-1]>0){
                continue;
            }
            var s : Int = 0;
            for i in y..<y+h {
                s += Int(im[i*W+j])
                s += Int(im[i*W+j-1])
            }
            if (s < ms){
                ms = s;
                mi = -1; // horizontal seam is defeated
                mj = j;
            }else if (s == ms && abs(j-(x+w/2))<abs(mj-(x+w/2))){
                ms = s;
                mi = -1;
                mj = j;
            }
        }
    }

    var L0 = -1; var L1 = -1; var L2 = -1; var L3 = -1;
    var R0 = -1; var R1 = -1; var R2 = -1; var R3 = -1;
    var dr : Int = 0;
    var sx : Int = 0;

    if (h > csize && mi != -1){ // split top and bottom
        L0 = x; L1 = y;  L2 = w; L3 = mi-y;
        R0 = x; R1 = mi; R2 = w; R3 = y+h-mi;
        dr = VERTICAL;
        sx = mi;
    }else if (w > csize && mj != -1){
        L0 = x; L1 = y; L2 = mj-x;  L3 = h;
        R0 = mj;R1 = y; R2 = x+w-mj;R3 = h;
        dr = HORIZONTAL;
        sx = mj;
    }

    var aL = false;
    var aR = false;
    if (dr != 0 && notEmpty(im:&im,W:W,H:H,x:L0,y:L1,w:L2,h:L3)){
        aL = true;
    }
    if (dr != 0 && notEmpty(im:&im,W:W,H:H,x:R0,y:R1,w:R2,h:R3)){
        aR = true;
    }

    if (aL && aR){
        var frags = traceSkeleton(im:&im,W:W,H:H,x:L0,y:L1,w:L2,h:L3,csize:csize,maxIter:maxIter-1)
        var f = traceSkeleton(im:&im,W:W,H:H,x:R0,y:R1,w:R2,h:R3,csize:csize,maxIter:maxIter-1)
        mergeFrags(c0:&frags, c1:&f, sx:sx, dr:dr)
        return frags
    }else if (aL){
        return traceSkeleton(im:&im,W:W,H:H,x:L0,y:L1,w:L2,h:L3,csize:csize,maxIter:maxIter-1)
    }else if (aR){
        return traceSkeleton(im:&im,W:W,H:H,x:R0,y:R1,w:R2,h:R3,csize:csize,maxIter:maxIter-1)
    }

    if (mi == -1 && mj == -1){
        return chunkToFrags(im:&im,W:W,H:H,x:x,y:y,w:w,h:h)
    }

    return [[[]]]
}

func readImage(url : String) -> ([UInt8],Int,Int) {
    let img = NSImage(byReferencing: URL(string: url)!)
    let bmp = img.representations[0] as! NSBitmapImageRep
    var data: UnsafeMutablePointer<UInt8> = bmp.bitmapData!
    var g : UInt8
    var pixels: [UInt8] = []
    for _ in 0..<bmp.pixelsHigh {
        for _ in 0..<bmp.pixelsWide {
            data = data.advanced(by: 1)
            g = data.pointee
            data = data.advanced(by: 1)
            data = data.advanced(by: 1)
            data = data.advanced(by: 1)
            if (g > 127){
                pixels.append(1);
            }else{
                pixels.append(0);
            }
        }
    }
    return (pixels, bmp.pixelsWide, bmp.pixelsHigh)
}

func polylineToSvg(q : [[[Int]]], w : Int, h : Int) -> String{
    var svg : String = String(format:"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" fill=\"none\" stroke=\"black\" stroke-width=\"1\">",w,h)
    for i in 0..<q.count{
        svg += "<path d=\"";
        for j in 0..<q[i].count{
            let s = String(format:"%@%d,%d ", (j==0 ? "M" : "L"), q[i][j][0],q[i][j][1])
            svg += s;
        }
        svg += "\"/>";
    }
    svg += "</svg>"
    return svg
}


var (im,W,H) = readImage(url: CommandLine.arguments[1])

let start1 = NSDate()
thinningZS(im:&im,W:W,H:H);
print("<!-- \(-start1.timeIntervalSinceNow) -->\n")

let start2 = NSDate()
let p = traceSkeleton(im:&im,W:W,H:H,x:0,y:0,w:W,h:H,csize:10,maxIter:999)
print("<!-- \(-start2.timeIntervalSinceNow) -->\n")

print(polylineToSvg(q:p,w:W,h:H))

