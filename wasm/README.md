# Skeleton Tracing WASM
## by [Lingdong Huang](https://github.com/LingDong-)

## Usage

```html
<script src="https://cdn.jsdelivr.net/npm/skeleton-tracing-wasm/build/trace_skeleton_wasm.js"></script>
```
```js
const TraceSkeleton = require('skeleton-tracing-wasm')

import TraceSkeleton  from 'skeleton-tracing-wasm'
```

You first need to initiate/load the wasm module calling a static method `load()` 

```js
const tracer = await TraceSkeleton.load()
```

then you can use the API methods

```js

const { polylines,rects } = tracer.fromCanvas(HTMLCANVAS)

```

Or instead of async/await you can do

```js

TraceSkeleton.load().then(tracer => {
	// wasm module loaded
	// here is your code 
	const { polylines,rects } = tracer.fromCanvas(HTMLCANVAS)

})

```


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


### More info at

[Github Original Project](https://github.com/LingDong-/skeleton-tracing)

[https://skeleton-tracing.netlify.app/](https://skeleton-tracing.netlify.app/)

**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**