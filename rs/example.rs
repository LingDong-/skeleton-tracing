/*

[dependencies]
image = "0.23.4"

*/

extern crate image;

mod trace_skeleton; pub use trace_skeleton::*;

fn read_image(path:String) -> (Vec<u8>,usize,usize){
    let img = image::open(path).unwrap().to_luma();
    let (w,h) = img.dimensions();
    let mut im = img.into_raw();
    for i in 0..h*w{
        if im[i as usize]>128 {
            im[i as usize] = 1
        }else{
            im[i as usize] = 0
        }
    }
    return (im,w as usize,h as usize);
}

fn main(){
    let argv: Vec<_> = std::env::args().collect();

    let (mut im,w,h) = read_image(argv[1].clone());
    
    trace_skeleton::thinning_zs(&mut im,w,h);

    // for i in 0..h{for j in 0..w{print!("{}",im[i*w+j]);}println!();}

    let now = std::time::Instant::now();
    let p : Vec<Vec<[usize;2]>> = trace_skeleton::trace_skeleton(&mut im,w,h,0,0,w,h,10,999);
    let elapsed = now.elapsed();
    println!("Elapsed: {:.2?}", elapsed);

    let svg : String = trace_skeleton::polylines_to_svg(&p,w,h);

    std::fs::write("out.svg", svg).expect("Unable to write file");
}