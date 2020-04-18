import trace_skeleton
import cv2
import random

im = cv2.imread("../test_images/opencv-thinning-src-img.png",0)

_,im = cv2.threshold(im,128,255,cv2.THRESH_BINARY);
# cv2.imshow("",im);cv2.waitKey(0)

polys = trace_skeleton.from_numpy(im);

for l in polys:
	c = (200*random.random(),200*random.random(),200*random.random())
	for i in range(0,len(l)-1):
		cv2.line(im,(l[i][0],l[i][1]),(l[i+1][0],l[i+1][1]),c)

cv2.imshow('',im);cv2.waitKey(0)