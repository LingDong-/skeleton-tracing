
// TraceSkeleton.cs
// Trace skeletonization result into polylines
// For Unity3D
//
// Lingdong Huang 2020

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class TraceSkeleton  : MonoBehaviour{  
  
  /** Binary image thinning (skeletonization) in-place.
    * Implements Zhang-Suen algorithm.
    * http://agcggs680.pbworks.com/f/Zhan-Suen_algorithm.pdf
    * @param im   the binary image
    * @param w    width
    * @param h    height
    */
  public static void thinningZS(bool[] im, int w, int h){
    bool[] prev = new bool[w*h];
    bool diff = true;
    do {
      thinningZSIteration(im,w,h,0);
      thinningZSIteration(im,w,h,1);
      diff = false;
      for (int i = 0; i < w*h; i++){
        if (im[i] ^ prev[i]){
          diff = true;
        }
        prev[i] = im[i];
      }
    }while (diff);
  }
  // 1 pass of Zhang-Suen thinning 
  static void thinningZSIteration(bool[] im, int w, int h, int iter) {
    bool[] marker = new bool[w*h];
    for (int i = 1; i < h-1; i++){
      for (int j = 1; j < w-1; j++){
        
        int p2 = im[(i-1)*w+j]  ?1:0;
        int p3 = im[(i-1)*w+j+1]?1:0;
        int p4 = im[(i)*w+j+1]  ?1:0;
        int p5 = im[(i+1)*w+j+1]?1:0;
        int p6 = im[(i+1)*w+j]  ?1:0;
        int p7 = im[(i+1)*w+j-1]?1:0;
        int p8 = im[(i)*w+j-1]  ?1:0;
        int p9 = im[(i-1)*w+j-1]?1:0;
  
        int A  = ((p2 == 0 && p3 == 1)?1:0) + ((p3 == 0 && p4 == 1)?1:0) + 
                 ((p4 == 0 && p5 == 1)?1:0) + ((p5 == 0 && p6 == 1)?1:0) + 
                 ((p6 == 0 && p7 == 1)?1:0) + ((p7 == 0 && p8 == 1)?1:0) +
                 ((p8 == 0 && p9 == 1)?1:0) + ((p9 == 0 && p2 == 1)?1:0);
        int B  = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
        int m1 = iter == 0 ? (p2 * p4 * p6) : (p2 * p4 * p8);
        int m2 = iter == 0 ? (p4 * p6 * p8) : (p2 * p6 * p8);
  
        if (A == 1 && (B >= 2 && B <= 6) && m1 == 0 && m2 == 0)
          marker[i*w+j] = true;
      }
    }
    for (int i = 0; i < h*w; i++){
      im[i] = im[i] & (!marker[i]);
    }
  }
  
  // check if a region has any white pixel
  static bool notEmpty(bool[] im, int W, int H, int x, int y, int w, int h){
    for (int i = y; i < y+h; i++){
      for (int j = x; j < x+w; j++){
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
  static bool mergeImpl(List<List<int[]>> c0, List<List<int[]>> c1, int i, int sx, bool isv, int mode){

    bool B0 = (mode >> 1 & 1)>0; // match c0 left
    bool B1 = (mode >> 0 & 1)>0; // match c1 left
    int mj = -1;
    float md = 4; // maximum offset to be regarded as continuous
    
    int l1 = c1[i].Count-1;
    int[] p1 = c1[i][B1?0:l1];
    
    if (Math.Abs(p1[isv?1:0]-sx)>0){ // not on the seam, skip
      return false;
    }
    
    // find the best match
    for (int j = 0; j < c0.Count; j++){
      int l0 = c0[j].Count-1;
      
      int[] p0 = c0[j][B0?0:l0];
      if (Math.Abs(p0[isv?1:0]-sx)>1){ // not on the seam, skip
        continue;
      }
      float d = Math.Abs(p0[isv?0:1] - p1[isv?0:1]);
      if (d < md){
        mj = j;
        md = d;
      }
    }
    
    if (mj != -1){ // best match is good enough, merge them
      if (B0 && B1){
        c1[i].Reverse();
        c0[mj].InsertRange(0,c1[i]);
      }else if (!B0 && B1){
        c0[mj].AddRange(c1[i]);
      }else if (B0 && !B1){
        c0[mj].InsertRange(0,c1[i]);
      }else {
        c1[i].Reverse();
        c0[mj].AddRange(c1[i]);
      }
      c1.RemoveAt(i);
      return true;
    }
    return false;
  }
  
  static int HORIZONTAL = 1;
  static int VERTICAL = 2;
  
  /**merge fragments from two chunks
   * @param c0   fragments from first  chunk
   * @param c1   fragments from second chunk
   * @param sx   (x or y) coordinate of the seam
   * @param dr   merge direction, HORIZONTAL or VERTICAL?
   */
  static void mergeFrags(List<List<int[]>> c0, List<List<int[]>> c1, int sx, int dr){
    for (int i = c1.Count-1; i>=0; i--){
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
    c0.AddRange(c1);
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
  public static List<List<int[]>> chunkToFrags(bool[] im, int W, int H, int x, int y, int w, int h){
    List<List<int[]>> frags = new List<List<int[]>>();
    bool on = false; // to deal with strokes thicker than 1px
    int li=-1, lj=-1;
    
    // walk around the edge clockwise
    for (int k = 0; k < h+h+w+w-4; k++){
      int i, j;
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
          List<int[]> f = new List<int[]>();
          f.Add(new int[]{j,i});
          f.Add(new int[]{x+w/2,y+h/2});
          frags.Add(f);
        }
      }else{
        if (on){// right side of stroke, average to get center of stroke
          frags[frags.Count-1][0][0]= (frags[frags.Count-1][0][0]+lj)/2;
          frags[frags.Count-1][0][1]= (frags[frags.Count-1][0][1]+li)/2;
          on = false;
        }
      }
      li = i;
      lj = j;
    }
    if (frags.Count == 2){ // probably just a line, connect them
      List<int[]> f = new List<int[]>();
      f.Add(frags[0][0]);
      f.Add(frags[1][0]);
      frags.RemoveAt(0);
      frags.RemoveAt(0);
      frags.Add(f);
    }else if (frags.Count > 2){ // it's a crossroad, guess the intersection
      int ms = 0;
      int mi = -1;
      int mj = -1;
      // use convolution to find brightest blob
      for (int i = y+1; i < y+h-1; i++){
        for (int j = x+1; j < x+w-1; j++){
          int s = 
            (im[i*W-W+j-1]?1:0) + (im[i*W-W+j]?1:0) + (im[i*W-W+j-1+1]?1:0)+
            (im[i*W+j-1]?1:0) +   (im[i*W+j]?1:0) +   (im[i*W+j+1]?1:0)+
            (im[i*W+W+j-1]?1:0) + (im[i*W+W+j]?1:0) + (im[i*W+W+j+1]?1:0);
          if (s > ms){
            mi = i;
            mj = j;
            ms = s;
          }else if (s == ms && Math.Abs(j-(x+w/2))+Math.Abs(i-(y+h/2)) < Math.Abs(mj-(x+w/2))+Math.Abs(mi-(y+h/2))){
            mi = i;
            mj = j;
            ms = s;
          }
        }
      }
      if (mi != -1){
        for (int i = 0; i < frags.Count; i++){
          frags[i][1]= new int[]{mj,mi};
        }
      }
    }
    return frags;
  
  }
  
  /** Trace skeleton from thinning result (shorthand with less arguments)
   * @param im    the bitmap image
   * @param W     width of  image
   * @param H     height of image
   * @param csize chunk size
   * @return      an array of polylines
   */
  public static List<List<int[]>> traceSkeleton(bool[] im, int W, int H, int csize){
    return traceSkeleton(im,W,H,0,0,W,H,csize,W*H,null);
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
  public static List<List<int[]>> traceSkeleton(bool[] im, int W, int H, int x, int y, int w, int h, int csize, int maxIter, List<int[]> rects){
    
    List<List<int[]>> frags = new List<List<int[]>>();
    
    if (maxIter == 0){ // gameover
      return frags;
    }
    if (w <= csize && h <= csize){ // recursive bottom
      frags.AddRange(chunkToFrags(im,W,H,x,y,w,h));
      return frags;
    }
   
    int ms = Int32.MaxValue; // number of white pixels on the seam, less the better
    int mi = -1; // horizontal seam candidate
    int mj = -1; // vertical   seam candidate
    
    if (h > csize){ // try splitting top and bottom
      for (int i = y+3; i < y+h-3; i++){
        if (im[i*W+x] ||im[(i-1)*W+x] ||im[i*W+x+w-1] ||im[(i-1)*W+x+w-1]){
          continue;
        }
        int s = 0;
        for (int j = x; j < x+w; j++){
          s += im[i*W+j]?1:0;
          s += im[(i-1)*W+j]?1:0;
        }
        if (s < ms){
          ms = s; mi = i;
        }else if (s == ms && Math.Abs(i-(y+h/2))<Math.Abs(mi-(y+h/2))){
          // if there is a draw (very common), we want the seam to be near the middle
          // to balance the divide and conquer tree
          ms = s; mi = i;
        }
      }
    }
    
    if (w > csize){ // same as above, try splitting left and right
      for (int j = x+3; j < x+w-3; j++){
        if (im[W*y+j]||im[W*(y+h)-W+j]||im[W*y+j-1]||im[W*(y+h)-W+j-1]){
          continue;
        }
        int s = 0;
        for (int i = y; i < y+h; i++){
          s += im[i*W+j]?1:0;
          s += im[i*W+j-1]?1:0;
        }
        if (s < ms){
          ms = s;
          mi = -1; // horizontal seam is defeated
          mj = j;
        }else if (s == ms && Math.Abs(j-(x+w/2))<Math.Abs(mj-(x+w/2))){
          ms = s;
          mi = -1;
          mj = j;
        }
      }
    }

    List<List<int[]>> nf = new List<List<int[]>>(); // new fragments
    if (h > csize && mi != -1){ // split top and bottom
      int[] L = new int[]{x,y,w,mi-y};    // new chunk bounding boxes
      int[] R = new int[]{x,mi,w,y+h-mi};
      
      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){ // if there are no white pixels, don't waste time
        if(rects!=null)rects.Add(L);
        nf.AddRange(traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects)); // recurse
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.Add(R);
        mergeFrags(nf,traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mi,VERTICAL);
      }
    }else if (w > csize && mj != -1){ // split left and right
      int[] L = new int[]{x,y,mj-x,h};
      int[] R = new int[]{mj,y,x+w-mj,h};
      if (notEmpty(im,W,H,L[0],L[1],L[2],L[3])){
        if(rects!=null)rects.Add(L);
        nf.AddRange(traceSkeleton(im,W,H,L[0],L[1],L[2],L[3],csize,maxIter-1,rects));
      }
      if (notEmpty(im,W,H,R[0],R[1],R[2],R[3])){
        if(rects!=null)rects.Add(R);
        mergeFrags(nf,traceSkeleton(im,W,H,R[0],R[1],R[2],R[3],csize,maxIter-1,rects),mj,HORIZONTAL);
      }
    }
    frags.AddRange(nf);
    if (mi == -1 && mj == -1){ // splitting failed! do the recursive bottom instead
      frags.AddRange(chunkToFrags(im,W,H,x,y,w,h));
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
  public List<List<int[]>> trace(bool[] im, int W, int H, int csize){
    thinningZS(im,W,H);
    return traceSkeleton(im,W,H,csize);
  }

  public Texture2D srcTexture;

  [Range(5,20)]
  public int chunkSize = 10;

  public List<List<int[]>> polylines {get; private set;}

  void Start(){
    int W = srcTexture.width;
    int H = srcTexture.height;
    Color[] pix = srcTexture.GetPixels(0,0,W,H);
    bool[] im = new bool[pix.Length];
    for (int i = 0; i < pix.Length; i++){
      im[i] = pix[i].r>0.5;
    }
    polylines = trace(im,W,H,chunkSize);
    Debug.Log(polylines.Count);
    for (int i = 0; i < polylines.Count; i++){
      GameObject line = new GameObject();
      line.transform.parent = gameObject.transform;
      line.AddComponent<LineRenderer>();
      LineRenderer lr = line.GetComponent<LineRenderer>();
      lr.positionCount = polylines[i].Count;
      for (int j = 0; j < polylines[i].Count; j++){
        Vector3 p = new Vector3(polylines[i][j][0],polylines[i][j][1],0);
        lr.SetPosition(j, p);
        GameObject cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.transform.position = p;
        cube.transform.parent = gameObject.transform;
      }
    }
  }


}
