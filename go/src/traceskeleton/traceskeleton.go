package traceskeleton

import (
    "fmt"
    "sync"
)

func abs(x int) int {
    if x < 0 {
        return -x
    }
    return x
}

//================================
// ENUMS
//================================

const (
    HORIZONTAL = 1
    VERTICAL   = 2
)

//================================
// DATASTRUCTURES
//================================

type point_t struct {
    x int
    y int
    next *point_t
}
type polyline_t struct {
    head *point_t
    tail *point_t
    prev *polyline_t
    next *polyline_t
    size int
}


//================================
// DATASTRUCTURE IMPLEMENTATION
//================================

func newPolyline() *polyline_t {
    var q *polyline_t = new(polyline_t)
    q.head = nil
    q.tail = nil
    q.prev = nil
    q.next = nil
    q.size = 0
    return q
}
func PrintPolyline(q *polyline_t){
    if (q==nil){
        return
    }
    var jt *point_t = q.head
    for jt != nil {
        fmt.Printf("%d,%d ",jt.x,jt.y)
        jt = jt.next
    }
    fmt.Printf("\n")
}
func PrintPolylines(q *polyline_t){
    if (q==nil){
        return
    }
    var it *polyline_t = q;
    for it != nil {
        var jt *point_t = it.head
        for jt != nil {
            fmt.Printf("%d,%d ",jt.x,jt.y)
            jt = jt.next
        }
        fmt.Printf("\n")
        it = it.next
    }
}
func reversePolyline(q *polyline_t){
    if (q==nil || q.size < 2){
        return
    }
    q.tail.next = q.head
    var it0 *point_t = q.head
    var it1 *point_t = it0.next
    var it2 *point_t = it1.next
    for i:=0; i < q.size-1; i++ {
        it1.next = it0
        it0 = it1
        it1 = it2
        it2 = it2.next
    }
    var qHead *point_t = q.head
    q.head = q.tail
    q.tail = qHead
    q.tail.next = nil
}

func catTailPolyline(q0 *polyline_t, q1 *polyline_t) {
    if (q1==nil){
        return
    }
    if (q0==nil){
        q0 = newPolyline()
    }
    if (q0.head==nil){
        q0.head = q1.head
        q0.tail = q1.tail
        return
    }
    q0.tail.next = q1.head
    q0.tail  = q1.tail
    q0.size += q1.size
    q0.tail.next = nil
}

func catHeadPolyline(q0 *polyline_t, q1 *polyline_t) {
    if (q1==nil){
        return
    }
    if (q0==nil){
        q0 = newPolyline()
    }
    if (q1.head==nil){
        return
    }
    if (q0.head==nil){
        q0.head = q1.head
        q0.tail = q1.tail
        return
    }
    q1.tail.next=q0.head
    q0.head = q1.head
    q0.size += q1.size
    q0.tail.next = nil
}

func addPointToPolyline(q *polyline_t, x int, y int){
    var p *point_t = new(point_t)
    p.x = x
    p.y = y
    p.next = nil
    if (q.head==nil){
        q.head = p
        q.tail = p
    }else{
        q.tail.next = p
        q.tail = p
    }
    q.size++
}

func prependPolyline(q0 *polyline_t, q1 *polyline_t) *polyline_t {
    if (q0==nil){
        return q1
    }
    q1.next = q0
    q0.prev = q1
    return q1
}

//================================
// RASTER SKELETONIZATION
//================================
// Binary image thinning (skeletonization) in-place.
// Implements Zhang-Suen algorithm.
// http://agcggs680.pbworks.com/f/Zhan-SuenAlgorithm.pdf

func thinningZSIteration(im []uint8, w int, h int, iter int) bool{
    diff := false
    for i := 1; i < h-1; i++ {
        for j := 1; j < w-1; j++ {
            p2 := im[(i-1)*w+j]   & 1;
            p3 := im[(i-1)*w+j+1] & 1;
            p4 := im[(i)*w+j+1]   & 1;
            p5 := im[(i+1)*w+j+1] & 1;
            p6 := im[(i+1)*w+j]   & 1;
            p7 := im[(i+1)*w+j-1] & 1;
            p8 := im[(i)*w+j-1]   & 1;
            p9 := im[(i-1)*w+j-1] & 1;
            A  := 0
            if (p2 == 0 && p3 == 1) { A++ }
            if (p3 == 0 && p4 == 1) { A++ }
            if (p4 == 0 && p5 == 1) { A++ }
            if (p5 == 0 && p6 == 1) { A++ }
            if (p6 == 0 && p7 == 1) { A++ }
            if (p7 == 0 && p8 == 1) { A++ }
            if (p8 == 0 && p9 == 1) { A++ }
            if (p9 == 0 && p2 == 1) { A++ }
            B := p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
            var m1 uint8= 0
            var m2 uint8= 0
            if iter == 0 {
                m1 = p2 * p4 * p6
                m2 = p4 * p6 * p8
            }else{
                m1 = p2 * p4 * p8
                m2 = p2 * p6 * p8
            }
            if (A == 1 && (B >= 2 && B <= 6) && m1 == 0 && m2 == 0){
              im[i*w+j] |= 2;
            }
        }
    }
    for i := 0; i < h*w; i++ {
        var marker bool  = (im[i] >> 1) != 0
        var old    uint8 = (im[i] &  1)
        if (old != 0 && (!marker)){
            im[i] = 1
        }else{
            im[i] = 0
        }
        if ((!diff) && (im[i] != old)){
            diff = true 
        }
    }
    return diff
}

func ThinningZS(im []uint8, w int, h int) {
  var diff bool = true;
  for {
    diff = diff && thinningZSIteration(im,w,h,0);
    diff = diff && thinningZSIteration(im,w,h,1);
    if !diff {
        break;
    }
  }
}

//================================
// MAIN ALGORITHM
//================================

// check if a region has any white pixel
func notEmpty(im []uint8, W int, H int, x int, y int, w int, h int) bool {
  for i := y; i < y+h; i++ {
    for j := x; j < x+w; j++ {
      if (im[i*W+j]!=0){
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
func mergeImpl(c0 *polyline_t, c1i *polyline_t, sx int, isv bool, mode int) bool {
    var b0 bool = (mode >> 1 & 1)>0; // match c0 left
    var b1 bool = (mode >> 0 & 1)>0; // match c1 left
    var c0j *polyline_t = nil
    var md int = 4
    var p1 *point_t = c1i.tail
    if (b1){
        p1 = c1i.head
    }
    var xx int=p1.x;if(isv){xx = p1.y};if(abs(xx-sx)>0){ // not on the seam, skip
        return false;
    }
    // find the best match
    var it *polyline_t = c0
    for it!=nil {
        var p0 *point_t = it.tail; if (b0){p0=it.head}
        var aa int=p0.x;if(isv){aa=p0.y};if(abs(aa-sx)>1){
            it = it.next
            continue
        }
        var bb int=p0.y;if(isv){bb=p0.x}
        var cc int=p1.y;if(isv){cc=p1.x}
        var d  int= abs(bb-cc)
        if (d < md){
            c0j = it
            md = d
        }
        it = it.next
    }
    if (c0j!=nil){// best match is good enough, merge them
        if (b0 && b1){
          reversePolyline(c1i);
          catHeadPolyline(c0j,c1i);
        }else if (!b0 && b1){
          catTailPolyline(c0j,c1i);
        }else if (b0 && !b1){
          catHeadPolyline(c0j,c1i);
        }else {
          reversePolyline(c1i);
          catTailPolyline(c0j,c1i);
        }
        return true; 
    }
    return false
}

/**merge fragments from two chunks
 * @param c0   fragments from first  chunk
 * @param c1   fragments from second chunk
 * @param sx   (x or y) coordinate of the seam
 * @param dr   merge direction, HORIZONTAL or VERTICAL?
 */
func mergeFrags(c0 *polyline_t, c1 *polyline_t, sx int, dr int) *polyline_t{
  if (c0==nil){
    return c1;
  }
  if (c1==nil){
    return c0;
  }
  var it *polyline_t = c1;
  for it!=nil {
    var tmp *polyline_t = it.next;
    if (dr == HORIZONTAL){
      if (mergeImpl(c0,it,sx,false,1)){goto rem}
      if (mergeImpl(c0,it,sx,false,3)){goto rem}
      if (mergeImpl(c0,it,sx,false,0)){goto rem}
      if (mergeImpl(c0,it,sx,false,2)){goto rem}
    }else{
      if (mergeImpl(c0,it,sx,true,1)){goto rem}
      if (mergeImpl(c0,it,sx,true,3)){goto rem}
      if (mergeImpl(c0,it,sx,true,0)){goto rem}
      if (mergeImpl(c0,it,sx,true,2)){goto rem}      
    }
    goto next;
    rem:
    if (it.prev == nil){
      c1 = it.next;
      if (it.next != nil){
        it.next.prev = nil;
      }
    }else{
      it.prev.next = it.next;
      if (it.next != nil){
        it.next.prev = it.prev;
      }
    }
    next:
    it = tmp;
  }
  it = c1;
  for it != nil{
    var tmp *polyline_t= it.next;
    it.prev = nil;
    it.next = nil;
    c0 = prependPolyline(c0,it);
    it = tmp;
  }
  return c0;
}
/**recursive bottom: turn chunk into polyline fragments;
 * look around on 4 edges of the chunk, and identify the "outgoing" pixels;
 * add segments connecting these pixels to center of chunk;
 * apply heuristics to adjust center of chunk
 *
 * @param x    left of   chunk
 * @param y    top of    chunk
 * @param w    width of  chunk
 * @param h    height of chunk
 * @return     the polyline fragments
 */
func chunkToFrags(im []uint8, W int, H int, x int, y int, w int, h int) *polyline_t {
    var frags *polyline_t = nil
    var fsize int = 0
    var on bool = false // to deal with strokes thicker than 1px
    var li int = -1
    var lj int = -1
    // walk around the edge clockwise
    for k := 0; k < h+h+w+w-4; k++ {
        var i, j int
        if (k < w){
          i = y + 0; j = x + k;
        }else if (k < w+h-1){
          i = y+k-w+1; j = x+w-1;
        }else if (k < w+h+w-2){
          i = y+h-1; j = x+w-(k-w-h+3); 
        }else{
          i = y+h-(k-w-h-w+4); j = x+0;
        }
        if (im[i*W+j] != 0){
            if (!on){
                on = true
                var f *polyline_t = newPolyline()
                addPointToPolyline(f,j,i)
                addPointToPolyline(f,x+w/2,y+h/2)
                frags = prependPolyline(frags,f)
                fsize ++
            }
        }else{
            if (on){// right side of stroke, average to get center of stroke
                frags.head.x = (frags.head.x+lj)/2
                frags.head.y = (frags.head.y+li)/2
                on = false
            }
        }
        li = i
        lj = j
    }
    if (fsize == 2){
        var f *polyline_t = newPolyline()
        addPointToPolyline(f,frags.head.x,frags.head.y)
        addPointToPolyline(f,frags.next.head.x,frags.next.head.y)
        frags = f
    }else if (fsize > 2){
        var ms int = 0
        var mi int = -1
        var mj int = -1
        // use convolution to find brightest blob
        for i:=y+1; i < y+h-1; i++{
            for j:=x+1; j < x+w-1; j++{
                var s int=int((im[i*W-W+j-1]) + (im[i*W-W+j]) + (im[i*W-W+j-1+1])+
                              (im[i*W+j-1]  ) +   (im[i*W+j]) +   (im[i*W+j+1]  )+
                              (im[i*W+W+j-1]) + (im[i*W+W+j]) + (im[i*W+W+j+1]  ));
                if (s > ms){
                    mi = i
                    mj = j
                    ms = s
                }else if (s == ms && abs(j-(x+w/2))+abs(i-(y+h/2)) < abs(mj-(x+w/2))+abs(mi-(y+h/2))){
                    mi = i
                    mj = j
                    ms = s
                }
            }
        }
        if (mi != -1){
            var it *polyline_t = frags
            for it!=nil{
                it.tail.x = mj
                it.tail.y = mi
                it = it.next
            }
        }
    }
    return frags
}

/**Trace skeleton from thinning result.
 * Algorithm:
 * 1. if chunk size is small enough, reach recursive bottom and turn it into segments
 * 2. attempt to split the chunk into 2 smaller chunks, either horizontall or vertically;
 *    find the best "seam" to carve along, and avoid possible degenerate cases
 * 3. recurse on each chunk, and merge their segments
 *
 * @param x       left of   chunk
 * @param y       top of    chunk
 * @param w       width of  chunk
 * @param h       height of chunk
 * @param iter    current iteration
 * @return        an array of polylines
*/
func TraceSkeleton(im []uint8, W int, H int, x int, y int, w int, h int, chunkSize int, maxIter int) (*polyline_t){
    var frags *polyline_t = nil

    if (maxIter <= 0){ // gameover
        return frags
    }
    if (w <= chunkSize && h <= chunkSize){
        frags = chunkToFrags(im,W,H,x,y,w,h)
        return frags
    }
    var ms int = W+H // number of white pixels on the seam, less the better
    var mi int = -1
    var mj int = -1
    if (h > chunkSize){
        for i:=y+3; i<y+h-3; i++{
          if (im[i*W+x]!=0 ||im[(i-1)*W+x]!=0 ||im[i*W+x+w-1]!=0 ||im[(i-1)*W+x+w-1]!=0){
            continue;
          }
          var s int = 0;
          for j := x; j < x+w; j++ {
            s += int(im[i*W+j]);
            s += int(im[(i-1)*W+j]);
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
    if (w > chunkSize){
        for j := x+3; j < x+w-3; j++ {
          if (im[W*y+j]!=0 ||im[W*(y+h)-W+j]!=0 ||im[W*y+j-1]!=0 ||im[W*(y+h)-W+j-1]!=0){
            continue;
          }
          var s int = 0;
          for  i := y; i < y+h; i++ {
            s += int(im[i*W+j]);
            s += int(im[i*W+j-1]);
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
    var L0 int =-1; var L1, L2, L3 int;
    var R0 int =-1; var R1, R2, R3 int;
    var dr int = 0;
    var sx int;
    if (h > chunkSize && mi != -1){ // split top and bottom
      L0 = x; L1 = y;  L2 = w; L3 = mi-y;
      R0 = x; R1 = mi; R2 = w; R3 = y+h-mi;
      dr = VERTICAL;
      sx = mi;
    }else if (w > chunkSize && mj != -1){ // split left and right
      L0 = x; L1 = y; L2 = mj-x; L3 = h;
      R0 = mj;R1 = y; R2 =x+w-mj;R3 = h;
      dr = HORIZONTAL;
      sx = mj;
    }
    var aL bool = false;
    var aR bool = false;
    if (dr!=0 && notEmpty(im,W,H,L0,L1,L2,L3)){ // if there are no white pixels, don't waste time
        aL = true;
    }
    if (dr!=0 && notEmpty(im,W,H,R0,R1,R2,R3)){
        aR = true;
    }
    if (aL && aR){
        messages := make(chan int)
        var wg sync.WaitGroup
        wg.Add(2)
        var pL, pR *polyline_t;
        go func() {
            defer wg.Done()
            pL = TraceSkeleton(im,W,H,L0,L1,L2,L3,chunkSize,maxIter-1)
            messages<-1
        }()
        go func() {
            defer wg.Done()
            pR = TraceSkeleton(im,W,H,R0,R1,R2,R3,chunkSize,maxIter-1)
            messages<-2

        }()
        go func() {
            wg.Wait()
            close(messages)
        }()
        <-messages
        <-messages
        frags = mergeFrags(pL,pR,sx,dr)

        // no goroutines
        // frags = mergeFrags(
        //     traceSkeleton(im,W,H,L0,L1,L2,L3,chunkSize,maxIter-1),
        //     traceSkeleton(im,W,H,R0,R1,R2,R3,chunkSize,maxIter-1),
        // sx,dr)
    }else if (aL){
        frags = TraceSkeleton(im,W,H,L0,L1,L2,L3,chunkSize,maxIter-1)
    }else if (aR){
        frags = TraceSkeleton(im,W,H,R0,R1,R2,R3,chunkSize,maxIter-1)
    }
    if (mi == -1 && mj == -1){// splitting failed! do the recursive bottom instead
        frags = chunkToFrags(im,W,H,x,y,w,h)
    }
    return frags
}



func PolylinesToSvg(q *polyline_t, w int, h int) string {
    var svg string = fmt.Sprintf("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" fill=\"none\" stroke=\"black\" stroke-width=\"1\">",w,h)
    if (q==nil){
        return svg+"</svg>"
    }
    var it *polyline_t = q;
    for it != nil {
        var jt *point_t = it.head
        svg += "<path d=\"M"
        for jt != nil {
            svg += fmt.Sprintf("%d,%d",jt.x,jt.y)
            jt = jt.next
            if (jt != nil){
                svg += " L"
            }
        }
        svg += "\"/>"
        it = it.next
    }
    return svg+"</svg>"
}


