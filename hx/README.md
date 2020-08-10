# TraceSkeleton.hx

Haxe version of the library.

Includes an OpenFl example.

```haxe
var im:Vector<Bool> = new Vector(W*H);

// < fill with image data here...

TraceSkeleton.thinningZS(im,W,H);

var rects:Array<Vector<Int>> = [];

var polylines:Array<Array<Vector<Int>>> = TraceSkeleton.traceSkeleton(
	im,  // input image
	W,H, // dimension
	0,0,W,H, // region of interest
	8, // chunk size
	999, // max iter
	rects // for visualizing inner working of algorithm, pass null if not needed
);
	
	
// alternative simplified interface that includes both thinning and tracing:
// var polylines = TraceSkeleton.trace(im,W,H,8);

```