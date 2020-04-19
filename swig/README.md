# trace_skeleton.py

The python library that calls C APIs directly, wrapped using SWIG.

## Usage

The following functions take in an image representation and return set of polylines (i.e. list of list of tuples).

- `trace_skeleton.from_numpy(arr)` input numpy array
- `trace_skeleton.from_list(arr,w,h)` input flat python list and width and height
- `trace_skeleton.from_list2d(arr)` input python list of list


## Example

```python
import trace_skeleton
import cv2
import random

im = cv2.imread("../test_images/opencv-thinning-src-img.png",0)

_,im = cv2.threshold(im,128,255,cv2.THRESH_BINARY);

polys = trace_skeleton.from_numpy(im);

for l in polys:
	c = (200*random.random(),200*random.random(),200*random.random())
	for i in range(0,len(l)-1):
		cv2.line(im,(l[i][0],l[i][1]),(l[i+1][0],l[i+1][1]),c)

cv2.imshow('',im);cv2.waitKey(0)
```

## Advanced

The aforementioned API's have a tiny linear time overhead for transforming input and output between internal datastructures and python objects. Alternatively, you can use the following: 

```python
from trace_skeleton import *

im = "\0\1\0\0\1\0\0\1\0 ..... " #image stored as a (char*)
w = 128 #dimensions
h = 64

trace(im,w,h)

# iterate over each point in each polyline
# by popping them off the internal datastructure
# len_polyline() gets the length of current polyline
# -1 means no more polylines
while (len_polyline() != -1):
	n = len_polyline();
	for i in range(0,n):
		# pop_point() retrieve and remove the next point
		# on the polyline. It returns the flat index in image
		# mod/div it with width to get (x,y) coordinate
		idx = pop_point()
		x = idx % w;
		y = idx //w;
		print(x,y)
	print("\n")
```

## Build from Source

Run `compile.sh`. You may need to modify the python include path.

**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**

