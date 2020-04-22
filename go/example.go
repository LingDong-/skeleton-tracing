package main

import "traceskeleton"

import (
    "image/png"
    "os"
    "log"
    "time"
    "fmt"
    "io/ioutil"
)

// read png image using stdlib
func readImage(path string) ([]uint8, int, int){
    reader, err := os.Open(path)
    if err != nil {
        log.Fatal(err)
    }
    defer reader.Close()
    m, err := png.Decode(reader)
    if err != nil {
        log.Fatal(err)
    }
    bounds := m.Bounds()
    var w = bounds.Max.X - bounds.Min.X;
    var h = bounds.Max.Y - bounds.Min.Y;
    var im = make([]uint8, w*h)
    for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
        for x := bounds.Min.X; x < bounds.Max.X; x++ {
            r, _, _, _ := m.At(x, y).RGBA()
            if r >= 32768 {
                im[w*y+x] = 1
            }else{
                im[w*y+x] = 0
            }
        }
    }
    return im,w,h
}

func main() {
    var im, w, h = readImage(os.Args[1]);

    traceskeleton.ThinningZS(im,w,h); // do raster thinning first

    start := time.Now()
    var p = traceskeleton.TraceSkeleton(im,w,h,0,0,w,h,10,999); // trace to polylines
	fmt.Println(time.Since(start))

    // save the result as scalable vector graphics
    ioutil.WriteFile("out.svg", []byte(traceskeleton.PolylinesToSvg(p,w,h)), 0644);
}