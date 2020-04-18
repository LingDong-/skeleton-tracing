# trace_skeleton.cpp

C++ library, basis for emscripten and OpenFrameworks versions.

Usage:

```c++
#include "trace_skeleton.cpp"

skeleton_tracer_t* T = new skeleton_tracer_t();
T->W = 64; // width of image
T->H = 64; // height of image

// allocate the input image  
T->im = (unsigned char*)malloc(sizeof(unsigned char)*T->W*T->H);

// draw something interesting on the input image here...

T->thinning_zs(); // perform raster thinning

// prepare arguments to pass into the tracer
skeleton_tracer_t::arg_t* arg = (skeleton_tracer_t::arg_t*)malloc(sizeof(skeleton_tracer_t::arg_t));
arg->x = 0;
arg->y = 0;
arg->w = T->W;
arg->h = T->H;
arg->iter = 0;

// run the algorithm
skeleton_tracer_t::polyline_t* p = (skeleton_tracer_t::polyline_t*)T->trace_skeleton((void*)arg);

// print out points in every polyline
skeleton_tracer_t::polyline_t* it = p; //iterator
while(it){
  skeleton_tracer_t::point_t* jt = it->head;
  while(jt){
    printf("%d,%d ",jt->x,jt->y);
    jt = jt->next;
  }
  printf("\n");
  it = it->next;
}

// clean up
free(arg);
free(T->im);
T->destroy_polylines(p);
T->destroy_rects();

delete T;
return 0;
```

**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**