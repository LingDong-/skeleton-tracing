# trace_skeleton.rs

Rust version.


## Usage

```rust
mod trace_skeleton; pub use trace_skeleton::*;

let mut im : Vec<u8> = vec![0,1,0,1,0,...]; // image
let w = 100; // width
let h = 100; // height

//raster thinning
trace_skeleton::thinnning_zs(&mut im, w, h);

//trace skeleton to polylines
let p : Vec<Vec<[usize;2]>> = trace_skeleton::trace_skeleton(&mut im,w,h,0,0,w,h,10,999);

//render as svg string
let svg : String = trace_skeleton::polylines_to_svg(&p,w,h);

```


## Compile

First compile

```
rustc -O example.rs
```

Then run

```
./example img.txt
```

Output will be written to `out.svg`

- `-O` should be passed to the compiler to gain a ~100x speedup.
- `img.txt` is an text file filled with "0" and "1" representing a bitmap image.


**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**