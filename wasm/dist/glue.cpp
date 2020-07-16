
#include <emscripten.h>

extern "C" {

// Not using size_t for array indices as the values used by the javascript code are signed.

EM_JS(void, array_bounds_check_error, (size_t idx, size_t size), {
  throw 'Array index ' + idx + ' out of bounds: [0,' + size + ')';
});

void array_bounds_check(const int array_size, const int array_idx) {
  if (array_idx < 0 || array_idx >= array_size) {
    array_bounds_check_error(array_idx, array_size);
  }
}

// VoidPtr

void EMSCRIPTEN_KEEPALIVE emscripten_bind_VoidPtr___destroy___0(void** self) {
  delete self;
}

// skeleton_tracer_t

skeleton_tracer_t* EMSCRIPTEN_KEEPALIVE emscripten_bind_skeleton_tracer_t_skeleton_tracer_t_0() {
  return new skeleton_tracer_t();
}

char* EMSCRIPTEN_KEEPALIVE emscripten_bind_skeleton_tracer_t_trace_3(skeleton_tracer_t* self, char* img, int w, int h) {
  return self->trace(img, w, h);
}

void EMSCRIPTEN_KEEPALIVE emscripten_bind_skeleton_tracer_t_destroy_0(skeleton_tracer_t* self) {
  self->destroy();
}

void EMSCRIPTEN_KEEPALIVE emscripten_bind_skeleton_tracer_t___destroy___0(skeleton_tracer_t* self) {
  delete self;
}

}

