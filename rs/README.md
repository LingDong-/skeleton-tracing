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


## Testing the example

The example uses the rust image crate.

```bash
cargo new example
cp example.rs example/src/main.rs
cp trace_skeleton.rs example/src/trace_skeleton.rs
echo "image=\"0.23.4\"" >> example/Cargo.toml
cd example
cargo build --release
```

Run it

```
./target/release/example path/to/image.png
```

Output will be written to `out.svg`

**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**