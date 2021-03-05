# trace_skeleton.py

The super slow, pure python implementation, just for reference.

**See `../swig` for the fast version that directly calls C APIs from python!**


## Usage

Uses numpy. This example uses opencv to read/display images, but the library itself does not depend on opencv.

It also tries to use skimage's faster raster thinning by default, and falls back to homemade implementation if skimage is not installed.

```python
from trace_skeleton import *
import cv2
import random
  
im0 = cv2.imread("../test_images/opencv-thinning-src-img.png")
im = (im0[:,:,0]>128).astype(np.uint8)

im = thinning(im)

rects = []
polys = traceSkeleton(im,0,0,im.shape[1],im.shape[0],10,999,rects)

for l in polys:
  c = (200*random.random(),200*random.random(),200*random.random())
  for i in range(0,len(l)-1):
    cv2.line(im0,(l[i][0],l[i][1]),(l[i+1][0],l[i+1][1]),c)

cv2.imshow('',im0);cv2.waitKey(0)

```


**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**
