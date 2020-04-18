# trace_skeleton.js

The JavaScript libary compiled from C++ with emscripten, accelerated with WebAssembly.

## Usage

```html
<script src="trace_skeleton.js"></script>
```

Make sure `trace_skeleton.wasm` is also in the same folder.


The below API's take an image representation and returns an object holding the polylines as well as rects processed by the algorithm (the latter is mainly for visualization)

```js
{
	"polylines": [[[x,y],[x,y]],[[x,y],[x,y],[x,y],...],...],
	"rects":     [[x,y,w,h],[x,y,w,h],...]
}
```


### `TraceSkeleton.fromCanvas(canv)` 

Takes in an HTML Canvas object and returns the skeleton as polyilnes as well as the rects.

### `TraceSkeleton.fromImageData(imgData)` 

Takes JavaScript ImageData object (e.g. `document.createElement("canvas").getContext('2d').getImageData(0,0,100,100)`)

### `TraceSkeleton.fromBoolArray(arr,w,h)` 

Takes array of booleans (or truthy and falsy values), e.g. `[0,1,0,1,1,1,0,0,...]` or `[0,255,255,0,...]` or `[true,false,true,false,...]` or even `[undefined, "ok", null, "yes", ...]`

### `TraceSkeleton.fromCharString(str,w,h)` 

Takes in a `(char*)` such as `"\0\1\0\0\1\1\0...."`. This is the fastest (though probably most obscure) API because it does not need to translate the input to C constructs.


### `TraceSkeleton.visualize(result, {scale, strokeWidth, rects, keypoints})`

Conveniently visualize the result from the previous functions, returns a string holding an SVG (scalable vector graphics).

Options:

- `scale`: factor to scale the drawing
- `rects`: draw the rects?
- `keypoints`: draw the keypoints on the polylines?
- `strokeWidth`: weight of the polyline strokes.

See `/index.html` for more detailed usage example, with animation, interactivity, webcam, etc.


**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**