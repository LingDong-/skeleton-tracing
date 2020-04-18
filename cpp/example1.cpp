#include <iostream>
#include "trace_skeleton.cpp"

int main(){
  int W = 64;
  int H = 64;
  skeleton_tracer_t* T = new skeleton_tracer_t();
  char* im = (char*)malloc(sizeof(char)*W*H);
  for (int i = 0; i < W*H; i++){
    im[i] = (i/10)%2;
  }
  std::cout << T->trace(im,W,H) << std::endl;
  T->destroy();
  delete T;
  return 0;
}