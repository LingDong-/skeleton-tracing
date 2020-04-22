mod trace_skeleton; pub use trace_skeleton::*;

fn read_txt_as_image(path:String) -> (Vec<u8>,usize,usize){
    let txt = std::fs::read_to_string(path).expect("Unable to read file");
    let bts = txt.as_bytes();
    let mut im : Vec<u8> = vec![];
    let mut w : usize = 0;
    let mut h : usize = 1;
    for i in 0..bts.len(){
        if bts[i] == 48{
            im.push(0);
            w+=1;
        }else if bts[i] == 49{
            im.push(1);
            w+=1;
        }else if bts[i] == 10{
            h+=1;
            w=0;
        }
    }
    return (im,w,h);
}

fn main(){
    let argv: Vec<_> = std::env::args().collect();
    let (mut im,w,h) = read_txt_as_image(argv[1].clone());
    
    trace_skeleton::thinning_zs(&mut im,w,h);

    // for i in 0..h{for j in 0..w{print!("{}",im[i*w+j]);}println!();}

    let now = std::time::Instant::now();
    let p : Vec<Vec<[usize;2]>> = trace_skeleton::trace_skeleton(&mut im,w,h,0,0,w,h,10,999);
    let elapsed = now.elapsed();
    println!("Elapsed: {:.2?}", elapsed);

    let svg : String = trace_skeleton::polylines_to_svg(&p,w,h);

    std::fs::write("out.svg", svg).expect("Unable to write file");
}