;;========================================================;;
;;     SKELETON TRACING WITH HANDWRITTEN WEBASSEMBLY      ;;
;; `traceskeleton.wat` Lingdong Huang 2020   MIT License  ;;
;;========================================================;;
;; A new algorithm for retrieving topological skeleton as ;;
;; a set of polylines from binary images                  ;;
;; https://github.com/LingDong-/skeleton-tracing          ;;
;;--------------------------------------------------------;;

;; ALGORITHM OUTLINE
;; (SEE https://github.com/LingDong-/skeleton-tracing FOR FULL DESCRIPTION)
;; 
;; 1. Given a binary image, first skeletonize it with a traditional raster 
;;    skeletonization algorithm.
;; 2. If the width and height of the image are both smaller than a small, 
;;    pre-determined size, go to step 7.
;; 3. Raster scan the image to find a row or column of pixels with least
;;    resistance for carving ("seams").
;; 4. Split the image by this column or row into 2 submatrices.
;; 5. Check if either of the 2 submatrices is empty (i.e. all 0-pixels). For 
;;    each non-empty submatrix, recursively process it by going to step 2.
;; 6. Merge the result from the 2 submatrices, and return the combined set of 
;;    polylines.
;; 7. Recursive bottom. Walk around the 4 edges of this small matrix in either 
;;    clockwise or ant-clockwise order inspecting the border pixels, in order
;;    to extract all the "outgoing" segments. Connect these segments using
;;    heuristics for 1/2/3+ segments.

;; FILE OUTLINE
;; +-----------------------+
;; | globals               |
;; |-----------------------|
;; | malloc impl.          | (~350 lines)
;; |-----------------------|
;; | raster thinning impl. | (~200 lines)
;; | (Zhang-Suen)          |
;; |-----------------------|
;; | datastructure impl    | (~250 lines)
;; | (linked-list)         |
;; |-----------------------|
;; | main algorithm        | (~700 lines)
;; +-----------------------+

(module

  (global $MAX_ITER   (mut i32) (i32.const 999)) ;; maximum number of iterations
  (global $CHUNK_SIZE (mut i32) (i32.const 10))  ;; the chunk size

  (global $im_ptr (mut i32) (i32.const 0)) ;; pointer to input image in memory
  (global $W (mut i32) (i32.const 0))      ;; width
  (global $H (mut i32) (i32.const 0))      ;; height

  ;; absolute value for i32
  (func $abs_i32 (param $x i32) (result i32)
    (if (i32.lt_s (local.get $x) (i32.const 0))(then
        (i32.sub (i32.const 0) (local.get $x))
        return
    ))
    (local.get $x)
  )

  ;;========================================================;;
  ;;     BASELINE MALLOC WITH HANDWRITTEN WEBASSEMBLY       ;;
  ;;========================================================;;
  ;; 32-bit implicit-free-list first-fit baseline malloc    ;;
  ;;--------------------------------------------------------;;

  ;; IMPLICIT FREE LIST:
  ;; Worse utilization and throughput than explicit/segregated, but easier
  ;; to implement :P
  ;;
  ;; HEAP LO                                                         HEAP HI
  ;; +---------------------+---------------------+...+---------------------+
  ;; | HDR | PAYLOAD | FTR | HDR | PAYLOAD | FTR |...+ HDR | PAYLOAD | FTR |
  ;; +----------^----------+---------------------+...+---------------------+
  ;;            |_ i.e. user data
  ;;           
  ;; LAYOUT OF A BLOCK:
  ;; Since memory is aligned to multiple of 4 bytes, the last two bits of
  ;; payload_size is redundant. Therefore the last bit of header is used to
  ;; store the is_free flag.
  ;; 
  ;; |---- HEADER (4b)----
  ;; |    ,--payload size (x4)--.     ,-is free?
  ;; | 0b . . . . . . . . . . . . 0  0
  ;; |------ PAYLOAD -----
  ;; |
  ;; |  user data (N x 4b)
  ;; |
  ;; |---- FOOTER (4b)---- (duplicate of header)
  ;; |    ,--payload size (x4)--.     ,-is free?
  ;; | 0b . . . . . . . . . . . . 0  0
  ;; |--------------------
  ;;
  ;; FORMULAS:
  ;; (these formulas are used throughout the code, so they're listed here
  ;; instead of explained each time encountered)
  ;;
  ;; payload_size = block_size - (header_size + footer_size) = block_size - 8
  ;; 
  ;; payload_pointer = header_pointer + header_size = header_pointer + 4
  ;;
  ;; footer_pointer = header_pointer + header_size + payload_size
  ;;                = (header_pointer + payload_size) + 4
  ;;
  ;; next_header_pointer = footer_pointer + footer_size = footer_pointer + 4
  ;;
  ;; prev_footer_pointer = header_pointer - footer_size = header_pointer - 4

  (memory $mem 1)                                ;; start with 1 page (64K)
  (global $max_addr (mut i32) (i32.const 65536)) ;; initial heap size (64K)
  (global $malloc_did_init (mut i32) (i32.const 0))     ;; init() called?

  ;; helpers to pack/unpack payload_size/is_free from header/footer
  ;; by masking out bits

  ;; read payload_size from header/footer given pointer to header/footer
  (func $hdr_get_size (param $ptr i32) (result i32)
    (i32.and (i32.load (local.get $ptr)) (i32.const 0xFFFFFFFC))
  )
  ;; read is_free from header/footer
  (func $hdr_get_free (param $ptr i32) (result i32)
    (i32.and (i32.load (local.get $ptr)) (i32.const 0x00000001))
  )
  ;; write payload_size to header/footer
  (func $hdr_set_size (param $ptr i32) (param $n i32) 
    (i32.store (local.get $ptr) (i32.or
      (i32.and (i32.load (local.get $ptr)) (i32.const 0x00000003))
      (local.get $n)
    ))
  )
  ;; write is_free to header/footer
  (func $hdr_set_free (param $ptr i32) (param $n i32)
    (i32.store (local.get $ptr) (i32.or
      (i32.and (i32.load (local.get $ptr)) (i32.const 0xFFFFFFFE))
      (local.get $n)
    ))
  )
  ;; align memory by 4 bytes
  (func $align4 (param $x i32) (result i32)
    (i32.and
      (i32.add (local.get $x) (i32.const 3))
      (i32.const -4)
    )
  )

  ;; initialize heap
  ;; make the whole heap a big free block
  ;; - automatically invoked by first malloc() call
  ;; - can be manually called to nuke the whole heap
  (func $malloc_init
    ;; write payload_size to header and footer
    (call $hdr_set_size (i32.const 0) (i32.sub (global.get $max_addr) (i32.const 8)))
    (call $hdr_set_size (i32.sub (global.get $max_addr) (i32.const 4))
      (i32.sub (global.get $max_addr) (i32.const 8))
    )
    ;; write is_free to header and footer
    (call $hdr_set_free (i32.const 0) (i32.const 1))
    (call $hdr_set_free (i32.sub (global.get $max_addr) (i32.const 4)) (i32.const 1))

    ;; set flag to tell malloc() that we've already called malloc_init()
    (global.set $malloc_did_init (i32.const 1)) 
  )

  ;; extend (grow) the heap (to accomodate more blocks)
  ;; parameter: number of pages (64K) to grow
  ;; - automatically invoked by malloc() when current heap has insufficient free space
  ;; - can be manually called to get more space in advance
  (func $extend (param $n_pages i32)
    (local $n_bytes i32)
    (local $ftr i32)
    (local $prev_ftr i32)
    (local $prev_hdr i32)
    (local $prev_size i32)

    (local.set $prev_ftr (i32.sub (global.get $max_addr) (i32.const 4)) )

    ;; compute number of bytes from page count (1page = 64K = 65536bytes)
    (local.set $n_bytes (i32.mul (local.get $n_pages) (i32.const 65536)))
  
    ;; system call to grow memory (`drop` discards the (useless) return value of memory.grow)
    (drop (memory.grow (local.get $n_pages) ))

    ;; make the newly acquired memory a big free block
    (call $hdr_set_size (global.get $max_addr) (i32.sub (local.get $n_bytes) (i32.const 8)))
    (call $hdr_set_free (global.get $max_addr) (i32.const 1))

    (global.set $max_addr (i32.add (global.get $max_addr) (local.get $n_bytes) ))
    (local.set $ftr (i32.sub (global.get $max_addr) (i32.const 4)))

    (call $hdr_set_size (local.get $ftr)
      (i32.sub (local.get $n_bytes) (i32.const 8))
    )
    (call $hdr_set_free (local.get $ftr) (i32.const 1))

    ;; see if we can join the new block with the last block of the old heap
    (if (i32.eqz (call $hdr_get_free (local.get $prev_ftr)))(then)(else

      ;; the last block is free, join it.
      (local.set $prev_size (call $hdr_get_size (local.get $prev_ftr)))
      (local.set $prev_hdr
        (i32.sub (i32.sub (local.get $prev_ftr) (local.get $prev_size)) (i32.const 4))
      )
      (call $hdr_set_size (local.get $prev_hdr)
        (i32.add (local.get $prev_size) (local.get $n_bytes) )
      )
      (call $hdr_set_size (local.get $ftr)
        (i32.add (local.get $prev_size) (local.get $n_bytes) )
      )
    ))

  )

  ;; find a free block that fit the request number of bytes
  ;; modifies the heap once a candidate is found
  ;; first-fit: not the best policy, but the simplest
  (func $find (param $n_bytes i32) (result i32)
    (local $ptr i32)
    (local $size i32)
    (local $is_free i32)
    (local $pay_ptr i32)
    (local $rest i32)

    ;; loop through all blocks
    (local.set $ptr (i32.const 0))
    loop $search
      ;; we reached the end of heap and haven't found anything, return NULL
      (if (i32.lt_u (local.get $ptr) (global.get $max_addr))(then)(else
        (i32.const 0)
        return
      ))

      ;; read info about current block
      (local.set $size    (call $hdr_get_size (local.get $ptr)))
      (local.set $is_free (call $hdr_get_free (local.get $ptr)))
      (local.set $pay_ptr (i32.add (local.get $ptr) (i32.const 4) ))

      ;; check if the current block is free
      (if (i32.eq (local.get $is_free) (i32.const 1))(then

        ;; it's free, but too small, move on
        (if (i32.gt_u (local.get $n_bytes) (local.get $size))(then
          (local.set $ptr (i32.add (local.get $ptr) (i32.add (local.get $size) (i32.const 8))))
          (br $search)

        ;; it's free, and large enough to be split into two blocks
        )(else(if (i32.lt_u (local.get $n_bytes) (i32.sub (local.get $size) (i32.const 8)))(then
          ;; OLD HEAP
          ;; ...+-------------------------------------------+...
          ;; ...| HDR |              FREE             | FTR |...
          ;; ...+-------------------------------------------+...
          ;; NEW HEAP
          ;; ...+---------------------+---------------------+...
          ;; ...| HDR | ALLOC   | FTR | HDR |  FREE   | FTR |...
          ;; ...+---------------------+---------------------+...

          ;; size of the remaining half
          (local.set $rest (i32.sub (i32.sub (local.get $size) (local.get $n_bytes) ) (i32.const 8)))

          ;; update headers and footers to reflect the change (see FORMULAS)

          (call $hdr_set_size (local.get $ptr) (local.get $n_bytes))
          (call $hdr_set_free (local.get $ptr) (i32.const 0))

          (call $hdr_set_size (i32.add (i32.add (local.get $ptr) (local.get $n_bytes)) (i32.const 4))
            (local.get $n_bytes)
          )
          (call $hdr_set_free (i32.add (i32.add (local.get $ptr) (local.get $n_bytes)) (i32.const 4))
            (i32.const 0)
          )
          (call $hdr_set_size (i32.add (i32.add (local.get $ptr) (local.get $n_bytes)) (i32.const 8))
            (local.get $rest)
          )
          (call $hdr_set_free (i32.add (i32.add (local.get $ptr) (local.get $n_bytes)) (i32.const 8))
            (i32.const 1)
          )
          (call $hdr_set_size (i32.add (i32.add (local.get $ptr) (local.get $size)) (i32.const 4))
            (local.get $rest)
          )

          (local.get $pay_ptr)
          return

        )(else
          ;; the block is free, but not large enough to be split into two blocks 
          ;; we return the whole block as one
          (call $hdr_set_free (local.get $ptr) (i32.const 0))
          (call $hdr_set_free (i32.add (i32.add (local.get $ptr) (local.get $size)) (i32.const 4))
            (i32.const 0)
          )
          (local.get $pay_ptr)
          return
        ))))
      )(else
        ;; the block is not free, we move on to the next block
        (local.set $ptr (i32.add (local.get $ptr) (i32.add (local.get $size) (i32.const 8))))
        (br $search)
      ))
    end

    ;; theoratically we will not reach here
    ;; return NULL
    (i32.const 0)
  )


  ;; malloc - allocate the requested number of bytes on the heap
  ;; returns a pointer to the block of memory allocated
  ;; returns NULL (0) when OOM
  ;; if heap is not large enough, grows it via extend()
  (func $malloc (param $n_bytes i32) (result i32)
    (local $ptr i32)
    (local $n_pages i32)

    ;; call init() if we haven't done so yet
    (if (i32.eqz (global.get $malloc_did_init)) (then
      (call $malloc_init)
    ))

    ;; payload size is aligned to multiple of 4
    (local.set $n_bytes (call $align4 (local.get $n_bytes)))

    ;; attempt allocation
    (local.set $ptr (call $find (local.get $n_bytes)) )

    ;; NULL -> OOM -> extend heap
    (if (i32.eqz (local.get $ptr))(then
      ;; compute # of pages from # of bytes, rounding up
      (local.set $n_pages
        (i32.div_u 
          (i32.add (local.get $n_bytes) (i32.const 65527) )
          (i32.const 65528)
        )
      )
      (call $extend (local.get $n_pages))

      ;; try again
      (local.set $ptr (call $find (local.get $n_bytes)) )
    ))
    (local.get $ptr)
  )

  ;; free - free an allocated block given a pointer to it
  (func $free (param $ptr i32)
    (local $hdr i32)
    (local $ftr i32)
    (local $size i32)
    (local $prev_hdr i32)
    (local $prev_ftr i32)
    (local $prev_size i32)
    (local $prev_free i32)
    (local $next_hdr i32)
    (local $next_ftr i32)
    (local $next_size i32)
    (local $next_free i32)
    
    ;; step I: mark the block as free

    (local.set $hdr (i32.sub (local.get $ptr) (i32.const 4)))
    (local.set $size (call $hdr_get_size (local.get $hdr)))
    (local.set $ftr (i32.add (i32.add (local.get $hdr) (local.get $size)) (i32.const 4)))

    (call $hdr_set_free (local.get $hdr) (i32.const 1))
    (call $hdr_set_free (local.get $ftr) (i32.const 1))

    ;; step II: try coalasce

    ;; coalasce with previous block

    ;; check that we're not already the first block
    (if (i32.eqz (local.get $hdr)) (then)(else

      ;; read info about previous block
      (local.set $prev_ftr (i32.sub (local.get $hdr) (i32.const 4)))
      (local.set $prev_size (call $hdr_get_size (local.get $prev_ftr)))
      (local.set $prev_hdr 
        (i32.sub (i32.sub (local.get $prev_ftr) (local.get $prev_size)) (i32.const 4))
      )

      ;; check if previous block is free -> merge them
      (if (i32.eqz (call $hdr_get_free (local.get $prev_ftr))) (then) (else
        (local.set $size (i32.add (i32.add (local.get $size) (local.get $prev_size)) (i32.const 8)))
        (call $hdr_set_size (local.get $prev_hdr) (local.get $size))
        (call $hdr_set_size (local.get $ftr) (local.get $size))

        ;; set current header pointer to previous header
        (local.set $hdr (local.get $prev_hdr))
      ))
    ))

    ;; coalasce with next block
  
    (local.set $next_hdr (i32.add (local.get $ftr) (i32.const 4)))

    ;; check that we're not already the last block
    (if (i32.eq (local.get $next_hdr) (global.get $max_addr)) (then)(else
      
      ;; read info about next block
      (local.set $next_size (call $hdr_get_size (local.get $next_hdr)))
      (local.set $next_ftr 
        (i32.add (i32.add (local.get $next_hdr) (local.get $next_size)) (i32.const 4))
      )

      ;; check if next block is free -> merge them
      (if (i32.eqz (call $hdr_get_free (local.get $next_hdr))) (then) (else
        (local.set $size (i32.add (i32.add (local.get $size) (local.get $next_size)) (i32.const 8)))
        (call $hdr_set_size (local.get $hdr) (local.get $size))
        (call $hdr_set_size (local.get $next_ftr) (local.get $size))
      ))

    ))

  )

  ;;========================================================;;
  ;;     SKELETONIZATION WITH HANDWRITTEN WEBASSEMBLY       ;;
  ;;========================================================;;
  ;; Binary image thinning (skeletonization) in-place.      ;;
  ;; Implements Zhang-Suen algorithm.                       ;;
  ;; http://agcggs680.pbworks.com/f/Zhan-Suen_algorithm.pdf ;;
  ;;--------------------------------------------------------;;

  ;; pixels are stored as 8-bit row-major array in memory
  ;; reading a pixel: mem[i=y*w+x]
  (func $im_get (param $x i32) (param $y i32) (result i32)
    (i32.load8_u (i32.add (global.get $im_ptr) (i32.add
      (i32.mul (global.get $W) (local.get $y))
      (local.get $x)
    )))
  )

  ;; writing a pixel: mem[i=y*w+x]=v
  (func $im_set (param $x i32) (param $y i32) (param $v i32)
    (i32.store8 (i32.add (global.get $im_ptr) (i32.add
      (i32.mul (global.get $W) (local.get $y))
      (local.get $x)
    )) (local.get $v))
  )

  ;; one iteration of the thinning algorithm
  ;; w: width, h: height, iter: 0=even-subiteration, 1=odd-subiteration
  ;; returns 0 if no further thinning possible (finished), 1 otherwise
  (func $thinning_zs_iteration (param $iter i32) (result i32)
    ;; local variable declarations
    ;; iterators
    (local $i  i32) (local $j  i32)
    ;; pixel Moore neighborhood
    (local $p2 i32) (local $p3 i32) (local $p4 i32) (local $p5 i32) 
    (local $p6 i32) (local $p7 i32) (local $p8 i32) (local $p9 i32)
    ;; temporary computation results
    (local $A  i32) (local $B  i32)
    (local $m1 i32) (local $m2 i32)
    ;; bools for updating image and determining stop condition
    (local $diff  i32)
    (local $mark  i32)
    (local $neu   i32)
    (local $old   i32)

    (local.set $diff (i32.const 0))
    
    ;; raster scan the image (loop over every pixel)

    ;; for (i = 1; i < h-1; i++)
    (local.set $i (i32.const 1))
    loop $loop_i

      ;; for (j = 1; j < w-1; j++)
      (local.set $j (i32.const 1))
      loop $loop_j
      
        ;; pixel's Moore (8-connected) neighborhood:

        ;; p9 p2 p3
        ;; p8    p4
        ;; p7 p6 p5

        (local.set $p2 (i32.and (call $im_get 
                   (local.get $j)
          (i32.sub (local.get $i) (i32.const 1))
        ) (i32.const 1) ))
        
        (local.set $p3 (i32.and (call $im_get 
          (i32.add (local.get $j) (i32.const 1))
          (i32.sub (local.get $i) (i32.const 1))
        ) (i32.const 1) ))

        (local.set $p4 (i32.and (call $im_get 
          (i32.add (local.get $j) (i32.const 1))
                   (local.get $i)
        ) (i32.const 1) ))

        (local.set $p5 (i32.and (call $im_get 
          (i32.add (local.get $j) (i32.const 1))
          (i32.add (local.get $i) (i32.const 1))
        ) (i32.const 1) ))

        (local.set $p6 (i32.and (call $im_get 
                   (local.get $j)
          (i32.add (local.get $i) (i32.const 1))
        ) (i32.const 1) ))

        (local.set $p7 (i32.and (call $im_get 
          (i32.sub (local.get $j) (i32.const 1))
          (i32.add (local.get $i) (i32.const 1))
        ) (i32.const 1) ))

        (local.set $p8 (i32.and (call $im_get 
          (i32.sub (local.get $j) (i32.const 1))
                   (local.get $i)
        ) (i32.const 1) ))

        (local.set $p9 (i32.and (call $im_get 
          (i32.sub (local.get $j) (i32.const 1))
          (i32.sub (local.get $i) (i32.const 1))
        ) (i32.const 1) ))

        ;; A is the number of 01 patterns in the ordered set p2,p3,p4,...p8,p9
        (local.set $A (i32.add (i32.add( i32.add (i32.add( i32.add( i32.add( i32.add
          (i32.and (i32.eqz (local.get $p2)) (i32.eq (local.get $p3) (i32.const 1)))
          (i32.and (i32.eqz (local.get $p3)) (i32.eq (local.get $p4) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p4)) (i32.eq (local.get $p5) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p5)) (i32.eq (local.get $p6) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p6)) (i32.eq (local.get $p7) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p7)) (i32.eq (local.get $p8) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p8)) (i32.eq (local.get $p9) (i32.const 1))))
          (i32.and (i32.eqz (local.get $p9)) (i32.eq (local.get $p2) (i32.const 1))))
        )
        ;; B = p2 + p3 + p4 + ... + p8 + p9
        (local.set $B (i32.add (i32.add( i32.add
          (i32.add (local.get $p2) (local.get $p3))
          (i32.add (local.get $p4) (local.get $p5)))
          (i32.add (local.get $p6) (local.get $p7)))
          (i32.add (local.get $p8) (local.get $p9)))
        )

        (if (i32.eqz (local.get $iter)) (then
          ;; first subiteration,  m1 = p2*p4*p6, m2 = p4*p6*p8
          (local.set $m1 (i32.mul(i32.mul (local.get $p2) (local.get $p4)) (local.get $p6)))
          (local.set $m2 (i32.mul(i32.mul (local.get $p4) (local.get $p6)) (local.get $p8)))
        )(else
          ;; second subiteration, m1 = p2*p4*p8, m2 = p2*p6*p8
          (local.set $m1 (i32.mul(i32.mul (local.get $p2) (local.get $p4)) (local.get $p8)))
          (local.set $m2 (i32.mul(i32.mul (local.get $p2) (local.get $p6)) (local.get $p8)))
        ))

        ;; the contour point is deleted if it satisfies the following conditions:
        ;; A == 1 && 2 <= B <= 6 && m1 == 0 && m2 == 0
        (if (i32.and(i32.and(i32.and(i32.and
          (i32.eq   (local.get $A) (i32.const  1))
          (i32.lt_u (i32.const  1) (local.get $B)))
          (i32.lt_u (local.get $B) (i32.const  7)))
          (i32.eqz  (local.get $m1)))
          (i32.eqz  (local.get $m2)))
        (then
          ;; we cannot erase the pixel directly because computation for neighboring pixels
          ;; depends on the current state of this pixel. And instead of using 2 matrices,
          ;; we do a |= 2 to set the second LSB to denote a to-be-erased pixel
          (call $im_set (local.get $j) (local.get $i)
            (i32.or
              (call $im_get (local.get $j) (local.get $i))
              (i32.const 2)
            )
          )
        )(else))
        
        ;; increment loopers
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $loop_j (i32.lt_u (local.get $j) (i32.sub (global.get $W) (i32.const 1))) )
      end
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $loop_i (i32.lt_u (local.get $i) (i32.sub (global.get $H) (i32.const 1))))
    end

    ;; for (i = 1; i < h; i++)
    (local.set $i (i32.const 0))
    loop $loop_i2

      ;; for (j = 0; j < w; j++)
      (local.set $j (i32.const 0))
      loop $loop_j2
        ;; bit-twiddling to retrive the new image stored in the second LSB
        ;; and check if the image has changed
        ;; mark = mem[i,j] >> 1
        ;; old  = mem[i,j] &  1
        ;; mem[i,j] = old & (!marker)
        (local.set $neu (call $im_get (local.get $j) (local.get $i)))
        (local.set $mark (i32.shr_u (local.get $neu) (i32.const 1)))
        (local.set $old  (i32.and   (local.get $neu) (i32.const 1)))
        (local.set $neu  (i32.and   (local.get $old) (i32.eqz (local.get $mark))))

        (call $im_set (local.get $j) (local.get $i) (local.get $neu))

        ;; image has changed, tell caller function that we will need more iterations
        (if (i32.ne (local.get $neu) (local.get $old)) (then
          (local.set $diff (i32.const 1))
        ))

        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $loop_j2 (i32.lt_u (local.get $j) (global.get $W)))
      end
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $loop_i2 (i32.lt_u (local.get $i) (global.get $H)))
    end

    ;; return
    (local.get $diff)
  )

  ;; main thinning routine
  ;; run thinning iteration until done
  ;; w: width, h:height
  (func $thinning_zs
    (local $diff i32)
    (local.set $diff (i32.const 1))
    loop $l0
      ;; even subiteration
      (local.set $diff (i32.and 
        (local.get $diff) 
        (call $thinning_zs_iteration (i32.const 0))
      ))
      ;; odd subiteration
      (local.set $diff (i32.and 
        (local.get $diff) 
        (call $thinning_zs_iteration (i32.const 1))
      ))
      ;; no change -> done!
      (br_if $l0 (i32.eq (local.get $diff) (i32.const 1)))
    end
  )

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;                                  ;;
  ;;                                  ;;
  ;;   DATASTRUCTURE IMPLEMENTATION   ;;
  ;;                                  ;;
  ;;                                  ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;; pl_*    polyline/polylines
  ;; pt_*    point/points

  ;; linked lists are used for fast insert/delete/concat
  ;; (which are very frequent in this algirthm, while
  ;; random access is never encountered in the algorithm)

  ;; -----------------------------------

  ;; struct readers and writers
  ;; WebAssembly does not have support for structs,
  ;; so the following getters and setters help read
  ;; data of correct sizes at correct offsets

  ;; POLYLINE(S)
  ;;
  ;; struct pl{
  ;;    pt* head; // (i32) first point      in polyline
  ;;    pt* tail; // (i32) last  point      in polyline
  ;;    pl* next; // (i32) next                polyline
  ;;    pl* prev; // (i32) previous            polyline
  ;;    int size; // (i32) number of points in polyline
  ;; }
  (func $pl_get_head (param $q i32) (result i32)
    (i32.load (local.get $q))
  )
  (func $pl_set_head (param $q i32) (param $v i32)
    (i32.store (local.get $q) (local.get $v))
  )
  (func $pl_get_tail (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 4)))
  )
  (func $pl_set_tail (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 4)) (local.get $v))
  )
  (func $pl_get_next (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 8)))
  )
  (func $pl_set_next (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 8)) (local.get $v))
  )
  (func $pl_get_prev (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 12)))
  )
  (func $pl_set_prev (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 12)) (local.get $v))
  )
  (func $pl_get_size (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 16)))
  )
  (func $pl_set_size (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 16)) (local.get $v))
  )

  ;; POINT(S)
  ;;
  ;; struct pl{
  ;;    int x;    // (i32) y coordinate
  ;;    int y;    // (i32) x coordinate
  ;;    pt* next; // (i32) next point
  ;; }
  (func $pt_get_x (param $q i32) (result i32)
    (i32.load (local.get $q))
  )
  (func $pt_set_x (param $q i32) (param $v i32)
    (i32.store (local.get $q) (local.get $v))
  )
  (func $pt_get_y (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 4)))
  )
  (func $pt_set_y (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 4)) (local.get $v))
  )
  (func $pt_get_next (param $q i32) (result i32)
    (i32.load (i32.add (local.get $q) (i32.const 8)))
  )
  (func $pt_set_next (param $q i32) (param $v i32)
    (i32.store (i32.add (local.get $q) (i32.const 8)) (local.get $v))
  )

  ;; create a new polyline
  ;; returns a pointer
  (func $pl_new (result i32)
    (local $q i32)
    (local.set $q (call $malloc (i32.const 20)))
    (call $pl_set_head (local.get $q) (i32.const 0))
    (call $pl_set_tail (local.get $q) (i32.const 0))
    (call $pl_set_prev (local.get $q) (i32.const 0))
    (call $pl_set_next (local.get $q) (i32.const 0))
    (call $pl_set_size (local.get $q) (i32.const 0))
    (local.get $q)
  )

  ;; reverse a polyline (in-place, one pass)
  (func $pl_rev (param $q i32)
    (local $size i32)
    (local $it0 i32)
    (local $it1 i32)
    (local $it2 i32)
    (local $i i32)
    (local $q_head i32)

    (if (i32.eqz (local.get $q)) (then
      return
    ))
    (local.set $size (call $pl_get_size (local.get $q)))
    (if (i32.lt_u (local.get $size) (i32.const 2)) (then
      return
    ))
    (call $pl_set_next (call $pl_get_tail (local.get $q)) (call $pl_get_head (local.get $q)) )

    (local.set $it0 (call $pl_get_head (local.get $q)))
    (local.set $it1 (call $pt_get_next (local.get $it0)))
    (local.set $it2 (call $pt_get_next (local.get $it1)))

    (local.set $i (i32.const 0))
    loop $pl_rev_loop0
      (call $pt_set_next (local.get $it1) (local.get $it0))
      (local.set $it0 (local.get $it1))
      (local.set $it1 (local.get $it2))
      (local.set $it2 (call $pt_get_next (local.get $it2)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $pl_rev_loop0 (i32.lt_u (local.get $i) (i32.sub (local.get $size) (i32.const 1))))
    end

    (local.set $q_head (call $pl_get_head (local.get $q)))
    (call $pl_set_head (local.get $q) (call $pl_get_tail (local.get $q)))
    (call $pl_set_tail (local.get $q) (local.get $q_head))
    (call $pl_set_next (call $pl_get_tail (local.get $q)) (i32.const 0))
  )

  ;; add a point to polyline (at the end)
  (func $pl_add_pt (param $q i32) (param $x i32) (param $y i32)
    (local $p i32)
    (local.set $p (call $malloc (i32.const 12)))
    (call $pt_set_x (local.get $p) (local.get $x))
    (call $pt_set_y (local.get $p) (local.get $y))
    (call $pt_set_next (local.get $p) (i32.const 0))
    (if (i32.eqz (call $pl_get_head (local.get $q)))(then
      (call $pl_set_head (local.get $q) (local.get $p))
    )(else
      (call $pl_set_next (call $pl_get_tail (local.get $q)) (local.get $p))
    ))
    (call $pl_set_tail (local.get $q) (local.get $p))
    (call $pl_set_size (local.get $q) (i32.add (call $pl_get_size (local.get $q)) (i32.const 1)))
  )

  ;; combine two polylines into one by concating the second to the end of the first
  (func $pl_cat_tail (param $q0 i32) (param $q1 i32) (result i32)
    (if (i32.eqz (local.get $q1))(then
      (local.get $q0)
      return
    ))
    (if (i32.eqz (local.get $q0))(then
      (local.set $q0 (call $pl_new))
    ))
    (if (i32.eqz (call $pl_get_head (local.get $q1)))(then
      (local.get $q0)
      return
    ))
    (if (i32.eqz (call $pl_get_head (local.get $q0)))(then
      (call $pl_set_head (local.get $q0) (call $pl_get_head (local.get $q1)))
      (call $pl_set_tail (local.get $q0) (call $pl_get_tail (local.get $q1)))
      (local.get $q0)
      return
    ))
    (call $pt_set_next (call $pl_get_tail (local.get $q0)) (call $pl_get_head (local.get $q1)))
    (call $pl_set_tail (local.get $q0) (call $pl_get_tail (local.get $q1)))
    (call $pl_set_size (local.get $q0) (i32.add 
      (call $pl_get_size (local.get $q0))
      (call $pl_get_size (local.get $q1))
    ))
    (call $pt_set_next (call $pl_get_tail (local.get $q0)) (i32.const 0))
    (local.get $q0)
    return
  )

  ;; combine two polylines into one by concating the first to the end of the second
  (func $pl_cat_head (param $q0 i32) (param $q1 i32) (result i32)
    (if (i32.eqz (local.get $q1))(then
      (local.get $q0)
      return
    ))
    (if (i32.eqz (local.get $q0))(then
      (local.set $q0 (call $pl_new))
    ))
    (if (i32.eqz (call $pl_get_head (local.get $q1)))(then
      (local.get $q0)
      return
    ))
    (if (i32.eqz (call $pl_get_head (local.get $q0)))(then
      (call $pl_set_head (local.get $q0) (call $pl_get_head (local.get $q1)))
      (call $pl_set_tail (local.get $q0) (call $pl_get_tail (local.get $q1)))
      (local.get $q0)
      return
    ))
    (call $pt_set_next (call $pl_get_tail (local.get $q1)) (call $pl_get_head (local.get $q0)))
    (call $pl_set_head (local.get $q0) (call $pl_get_head (local.get $q1)))
    (call $pl_set_size (local.get $q0) (i32.add 
      (call $pl_get_size (local.get $q0))
      (call $pl_get_size (local.get $q1))
    ))
    (call $pt_set_next (call $pl_get_tail (local.get $q0)) (i32.const 0))
    (local.get $q0)
    return
  )

  ;; add a polyline to a list of polylines by prepending it to the front
  (func $pl_prepend (param $q0 i32) (param $q1 i32) (result i32)
    (if (i32.eqz (local.get $q0))(then
      (local.get $q1)
      return
    ))
    (call $pl_set_next (local.get $q1) (local.get $q0))
    (call $pl_set_prev (local.get $q0) (local.get $q1))
    (local.get $q1)
    return
  )

  ;; destroy a list of polylines, freeing allocated memory
  (func $pls_destroy (param $q i32)
    (local $it i32)
    (local $jt i32)
    (local $kt i32)
    (local $lt i32)
    (if (i32.eqz (local.get $q))(then
      return
    ))
    (local.set $it (local.get $q))
    loop $pls_destroy_loop0
      
      (if (i32.eqz (local.get $it))(then)(else
        (local.set $lt (call $pl_get_next (local.get $it)))
        (local.set $jt (call $pl_get_head (local.get $it)))
        loop $pls_destroy_loop1
          (if (i32.eqz (local.get $jt))(then)(else
            (local.set $kt (call $pt_get_next (local.get $jt)))
            (call $free (local.get $jt))
            (local.set $jt (local.get $kt))
            (br $pls_destroy_loop1)
          ))
        end
        (call $free (local.get $it))
        (local.set $it (local.get $lt))
        (br $pls_destroy_loop0)
      ))
    end
  )


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;                                  ;;
  ;;                                  ;;
  ;;          MAIN ALOGIRHTM          ;;
  ;;                                  ;;
  ;;                                  ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;; check if a region has any white pixel
  (func $not_empty (param $x i32) (param $y i32) (param $w i32) (param $h i32) (result i32)
    (local $i i32)
    (local $j i32)
    (local.set $i (local.get $y))
    loop $not_empty_l0
      (local.set $j (local.get $x))
      loop $not_empty_l1
        (if (call $im_get (local.get $j) (local.get $i))(then
          (i32.const 1)
          return
        ))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $not_empty_l1 (i32.lt_u (local.get $j) (i32.add (local.get $x) (local.get $w)) )) 
      end
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $not_empty_l0 (i32.lt_u (local.get $i) (i32.add (local.get $y) (local.get $h)) )) 
    end
    (i32.const 0)
  )

  ;; merge ith fragment of second chunk to first chunk
  ;; @param c0   fragments from  first  chunk
  ;; @param c1i  ith fragment of second chunk
  ;; @param sx   (x or y) coordinate of the seam
  ;; @param isv  is vertical, not horizontal?
  ;; @param mode 2-bit flag, 
  ;;             MSB = is matching the left (not right) end of the fragment from first  chunk
  ;;             LSB = is matching the right (not left) end of the fragment from second chunk
  ;; @return     matching successful?             
  ;; 
  (func $merge_impl (param $c0 i32) (param $c1i i32) (param $sx i32) 
                    (param $isv i32) (param $mode i32) (result i32)
    (local $b0    i32)
    (local $b1    i32)
    (local $c0j   i32)
    (local $md    i32)
    (local $p0    i32)
    (local $p1    i32)
    (local $it    i32)
    (local $xory0 i32)
    (local $xory1 i32)
    (local $xory2 i32)
    (local $d     i32)

  ;; For each polyline from one submatrix whose either endpoint coincide with 
  ;; the splitting row or column, find another polyline in the other submatrix 
  ;; whose endpoint meets it. If the matrix was split horizontally, then the 
  ;; x-coordinate of the endpoints should differ by exactly 1, and y-coordinate
  ;; can differ between 0 to about 4 (depending on the steepness of the stroke 
  ;; potrayed), The reverse goes for vertical splitting.

    (local.set $b0 (i32.and (i32.shr_u (local.get $mode) (i32.const 1)) (i32.const 1) ))
    (local.set $b1 (i32.and (local.get $mode) (i32.const 1) ))
    (local.set $c0j (i32.const 0))
    (local.set $md (i32.const 4)) ;; maximum offset to be regarded as continuous

    (if (local.get $b1) (then
      (local.set $p1 (call $pl_get_head (local.get $c1i)))
    )(else
      (local.set $p1 (call $pl_get_tail (local.get $c1i)))
    ))

    (if (local.get $isv)(then
      (local.set $xory0 (call $pt_get_y (local.get $p1)))
    )(else
      (local.set $xory0 (call $pt_get_x (local.get $p1)))
    ))

    (if (i32.gt_s 
      (call $abs_i32 (i32.sub (local.get $xory0) (local.get $sx)))
      (i32.const 0)
    )(then ;; not on the seam, skip
      (i32.const 0)
      return
    ))
    
    ;; find the best match
    (local.set $it (local.get $c0))
    loop $merge_impl_l0 (if (local.get $it)(then
      (if (local.get $b0)(then
        (local.set $p0 (call $pl_get_head (local.get $it)))
      )(else
        (local.set $p0 (call $pl_get_tail (local.get $it)))
      ))
      
      (if (local.get $isv)(then
        (local.set $xory0 (call $pt_get_y (local.get $p0)))
        (local.set $xory1 (call $pt_get_x (local.get $p0)))
        (local.set $xory2 (call $pt_get_x (local.get $p1)))
      )(else
        (local.set $xory0 (call $pt_get_x (local.get $p0)))
        (local.set $xory1 (call $pt_get_y (local.get $p0)))
        (local.set $xory2 (call $pt_get_y (local.get $p1)))
      ))

      (if (i32.gt_s 
        (call $abs_i32 (i32.sub (local.get $xory0) (local.get $sx)))
        (i32.const 1)
      )(then ;; not on the seam, skip
        (local.set $it (call $pl_get_next (local.get $it)))
        (br $merge_impl_l0)
      ))

      (local.set $d (call $abs_i32
        (i32.sub (local.get $xory1) (local.get $xory2))
      ))
      (if (i32.lt_u (local.get $d) (local.get $md) )(then
        (local.set $c0j (local.get $it))
        (local.set $md (local.get $d))
      ))
      (local.set $it (call $pl_get_next (local.get $it)))
      (br $merge_impl_l0)
    )) end

  
    (if (local.get $c0j)(then ;; best match is good enough, merge them
      (if (local.get $b1) (then
        (if (local.get $b0) (then
          (call $pl_rev (local.get $c1i))
          (local.set $c0j (call $pl_cat_head (local.get $c0j) (local.get $c1i)))

        )(else
          (local.set $c0j (call $pl_cat_tail (local.get $c0j) (local.get $c1i)))

        ))
      )(else
        (if (local.get $b0) (then
          (local.set $c0j (call $pl_cat_head (local.get $c0j) (local.get $c1i)))
          
        )(else
          (call $pl_rev (local.get $c1i))
          (local.set $c0j (call $pl_cat_tail (local.get $c0j) (local.get $c1i)))


        ))
      ))
      (i32.const 1)
      return
    ))
    (i32.const 0)
  )

  ;; merge fragments from two chunks
  ;; @param c0   fragments from first  chunk
  ;; @param c1   fragments from second chunk
  ;; @param sx   (x or y) coordinate of the seam
  ;; @param dr   merge direction, HORIZONTAL(0) or VERTICAL(1)?
  ;; 
  (func $merge_frags (param $c0 i32) (param $c1 i32) (param $sx i32) (param $dr i32) (result i32)
    (local $it  i32)
    (local $tmp i32)
    (local $goto i32)


    (if (i32.eqz (local.get $c0))(then
      (local.get $c1)
      return
    ))
    (if (i32.eqz (local.get $c1))(then
      (local.get $c0)
      return
    ))

    (local.set $it (local.get $c1))
    (local.set $goto (i32.const 0))
    


    loop $mf_rem (if (local.get $goto) (then

      (if (i32.eqz (call $pl_get_prev (local.get $it))) (then
        (local.set $c1 (call $pl_get_next (local.get $it)))
        (if (local.get $c1) (then
          (call $pl_set_prev (local.get $c1) (i32.const 0))
        ))
      )(else
        (call $pl_set_next 
          (call $pl_get_prev (local.get $it)) 
          (call $pl_get_next (local.get $it)) 
        )
        (if (call $pl_get_next (local.get $it)) (then
          (call $pl_set_prev
            (call $pl_get_next (local.get $it)) 
            (call $pl_get_prev (local.get $it)) 
          )
        ))
      
      ))
      (call $free (local.get $it))
    ))loop $mf_next

      (if (local.get $goto)(then
        (local.set $it (local.get $tmp))
      ))

      

      (if (local.get $it) (then

        (local.set $goto (i32.const 1))

        (local.set $tmp (call $pl_get_next (local.get $it)))

        (if (call $merge_impl 
          (local.get $c0) (local.get $it) (local.get $sx) (local.get $dr) (i32.const 1) 
        )(then
          (br $mf_rem)
        ))
        
        (if (call $merge_impl 
          (local.get $c0) (local.get $it) (local.get $sx) (local.get $dr) (i32.const 3) 
        )(then
          (br $mf_rem)
        ))
        
        (if (call $merge_impl 
          (local.get $c0) (local.get $it) (local.get $sx) (local.get $dr) (i32.const 0) 
        )(then
          (br $mf_rem)
        ))
        
        (if (call $merge_impl 
          (local.get $c0) (local.get $it) (local.get $sx) (local.get $dr) (i32.const 2) 
        )(then
          (br $mf_rem)
        ))

        (br $mf_next)
      ))
    end
    end

    (local.set $it (local.get $c1))
    loop $mf_l2 (if (local.get $it) (then
      (local.set $tmp (call $pl_get_next (local.get $it)))
      (call $pl_set_prev (local.get $it) (i32.const 0))
      (call $pl_set_next (local.get $it) (i32.const 0))
      (local.set $c0 (call $pl_prepend (local.get $c0) (local.get $it)))
      (local.set $it (local.get $tmp))
      (br $mf_l2)
    ))end
    (local.get $c0)
  )

  ;; recursive bottom: turn chunk into polyline fragments;
  ;; look around on 4 edges of the chunk, and identify the "outgoing" pixels;
  ;; add segments connecting these pixels to center of chunk;
  ;; apply heuristics to adjust center of chunk
  ;; 
  ;; @param x    left of   chunk
  ;; @param y    top of    chunk
  ;; @param w    width of  chunk
  ;; @param h    height of chunk
  ;; @return     the polyline fragments
  ;; 
  (func $chunk_to_frags (param $x i32) (param $y i32) (param $w i32) (param $h i32) (result i32)
    (local $frags i32)
    (local $on i32)
    (local $li i32)
    (local $lj i32)
    (local $k i32)
    (local $i i32)
    (local $j i32)
    (local $i0 i32)
    (local $j0 i32)
    (local $i1 i32)
    (local $j1 i32)
    (local $f i32)
    (local $pt i32)
    (local $ms i32)
    (local $mi i32)
    (local $mj i32)
    (local $cx i32)
    (local $cy i32)
    (local $s i32)
    (local $fsize i32)
    (local $perim i32)
    (local $it i32)

    ;; - Initially set a flag to false, and whenever a 1-pixel is encountered 
    ;;   whilst the flag is false, set the flag to true, and push the coordinate 
    ;;   of the 1-pixel to a stack.
    ;; - Whenever a 0-pixel is encountered whilst the flag is true, pop the last 
    ;;   coordinate from the stack, and push the midpoint between it and the 
    ;;   current coordinate. Then set the flag to false.
    ;; - After all border pixels are visited, the stack now holds coordinates for 
    ;;   all the "outgoing" (or "incoming") pixels from this small image section. 
    ;;   By connecting these coordinates with the center coordinate of the image 
    ;;   section, an estimated vectorized representation of the skeleton in this 
    ;;   area if formed by these line segments. We further improve the estimate 
    ;;   using the following heuristics:
    ;;   - If there are exactly 2 outgoing pixels. It is likely that the area holds 
    ;;     a straight line. We return a single segment connecting these 2 pixels.
    ;;   - If there are 3 or more outgoing pixels, it is likely that the area holds 
    ;;     an intersection, or "crossroad". We do a convolution on the matrix to 
    ;;     find the 3x3 submatrix that contains the most 1-pixels. Set the center 
    ;;     of all the segments to the center of the 3x3 submatrix and return.
    ;;   - If there are only 1 outgoing pixels, return the segment that connects 
    ;;     it and the center of the image section.

    (local.set $frags (i32.const 0))
    (local.set $fsize (i32.const 0))
    (local.set $on (i32.const 0))   ;; flag (to deal with strokes thicker than 1px)
    (local.set $li (i32.const -1))
    (local.set $lj (i32.const -1))

    ;; center x,y
    (local.set $cx (i32.add (local.get $x) (i32.div_u (local.get $w) (i32.const 2))))
    (local.set $cy (i32.add (local.get $y) (i32.div_u (local.get $h) (i32.const 2))))

    (local.set $k (i32.const 0))
    (local.set $perim (i32.sub (i32.add 
      (i32.add (local.get $w) (local.get $w))
      (i32.add (local.get $h) (local.get $h))
    ) (i32.const 4)))

    ;; // walk around the edge clockwise
    loop $ctf_l0
      (if (i32.lt_u (local.get $k) (local.get $w))(then
        (local.set $i (local.get $y))
        (local.set $j (i32.add (local.get $x) (local.get $k)))

      )(else(if (i32.lt_u 
        (local.get $k) 
        (i32.sub (i32.add (local.get $w) (local.get $h)) (i32.const 1))
      )(then
        (local.set $i (i32.add 
          (i32.sub (i32.add (local.get $y) (local.get $k)) (local.get $w) )
          (i32.const 1)
        ))
        (local.set $j (i32.sub (i32.add (local.get $x) (local.get $w)) (i32.const 1)))
      )(else(if (i32.lt_u
        (local.get $k)
        (i32.sub (i32.add (i32.add (local.get $w) (local.get $h)) (local.get $w)) (i32.const 2))
      )(then
        (local.set $i (i32.sub (i32.add (local.get $y) (local.get $h)) (i32.const 1)))
        (local.set $j (i32.sub 
          (i32.add (local.get $x) (local.get $w))
          (i32.add (i32.sub
            (i32.sub (local.get $k) (local.get $w))
            (local.get $h)
          ) (i32.const 3))
        ))
      )(else
        (local.set $i (i32.sub 
          (i32.add (local.get $y) (local.get $h))
          (i32.add (i32.sub
            (i32.sub
              (i32.sub (local.get $k) (local.get $w))
              (local.get $h)
            )
            (local.get $w)
          ) (i32.const 4))
        ))
        (local.set $j (local.get $x))
      ))))))

      (if (call $im_get (local.get $j) (local.get $i)) (then ;; found an outgoing pixel
        (if (i32.eqz (local.get $on))(then                   ;; left side of stroke
          (local.set $on (i32.const 1))
          (local.set $f (call $pl_new))
          (call $pl_add_pt (local.get $f) (local.get $j) (local.get $i))
          (call $pl_add_pt (local.get $f) (local.get $cx) (local.get $cy))
          (local.set $frags (call $pl_prepend (local.get $frags) (local.get $f)))
          (local.set $fsize (i32.add (local.get $fsize) (i32.const 1)))
        ))
      )(else
        (if (local.get $on) (then  ;; right side of stroke, average to get center of stroke
          (local.set $pt (call $pl_get_head (local.get $frags)))
          (call $pt_set_x (local.get $pt) 
            (i32.div_u (i32.add (call $pt_get_x (local.get $pt)) (local.get $lj)) (i32.const 2))
          )
          (call $pt_set_y (local.get $pt)
            (i32.div_u (i32.add (call $pt_get_y (local.get $pt)) (local.get $li)) (i32.const 2))
          )
          (local.set $on (i32.const 0))
        ))
      ))
      (local.set $li (local.get $i))
      (local.set $lj (local.get $j))

      (local.set $k (i32.add (local.get $k) (i32.const 1)))
      (br_if $ctf_l0 (i32.lt_u (local.get $k) (local.get $perim)))
    end


    (if (i32.eq (local.get $fsize) (i32.const 2))(then ;; probably just a line, connect them
      (local.set $f (call $pl_new))
      (call $pl_add_pt (local.get $f) 
        (call $pt_get_x (call $pl_get_head (local.get $frags)))
        (call $pt_get_y (call $pl_get_head (local.get $frags)))
      )
      (call $pl_add_pt (local.get $f) 
        (call $pt_get_x (call $pl_get_head (call $pl_get_next (local.get $frags))))
        (call $pt_get_y (call $pl_get_head (call $pl_get_next (local.get $frags))))
      )
      (call $pls_destroy (local.get $frags))
      (local.set $frags (local.get $f))

    )(else (if (i32.gt_u (local.get $fsize) (i32.const 2)) (then 
      ;; it's a crossroad, guess the intersection

      (local.set $ms (i32.const 0))
      (local.set $mi (i32.const -1))
      (local.set $mj (i32.const -1))

      ;; use convolution to find brightest blob
      (local.set $i (i32.add (local.get $y) (i32.const 1)))
      loop $ctf_li
        (local.set $j (i32.add (local.get $x) (i32.const 1)))
        loop $ctf_lj
          (local.set $i0 (i32.sub (local.get $i) (i32.const 1)))
          (local.set $i1 (i32.add (local.get $i) (i32.const 1)))
          (local.set $j0 (i32.sub (local.get $j) (i32.const 1)))
          (local.set $j1 (i32.add (local.get $j) (i32.const 1)))
          (local.set $s (i32.add (call $im_get (local.get $j) (local.get $i)) (i32.add
            (i32.add 
              (i32.add
                (call $im_get (local.get $j0) (local.get $i0))
                (call $im_get (local.get $j1) (local.get $i0))
              )
              (i32.add
                (call $im_get (local.get $j0) (local.get $i1))
                (call $im_get (local.get $j1) (local.get $i1))
              )
            )(i32.add
              (i32.add
                (call $im_get (local.get $j0) (local.get $i))
                (call $im_get (local.get $j1) (local.get $i))
              )
              (i32.add
                (call $im_get (local.get $j) (local.get $i0))
                (call $im_get (local.get $j) (local.get $i1))
              )
            )
          )))

          (if (i32.gt_u (local.get $s) (local.get $ms) )(then
            (local.set $mi (local.get $i))
            (local.set $mj (local.get $j))
            (local.set $ms (local.get $s))
          )(else(if (i32.eq (local.get $s) (local.get $ms)) (then
            (if (i32.lt_u
              (i32.add
                (call $abs_i32 (i32.sub (local.get $j) (local.get $cx)))
                (call $abs_i32 (i32.sub (local.get $i) (local.get $cy)))
              )
              (i32.add
                (call $abs_i32 (i32.sub (local.get $mj) (local.get $cx)))
                (call $abs_i32 (i32.sub (local.get $mi) (local.get $cy)))
              )
            )(then
              (local.set $mi (local.get $i))
              (local.set $mj (local.get $j))
              (local.set $ms (local.get $s))
            ))          
          ))))

          (local.set $j (i32.add (local.get $j) (i32.const 1)))
          (br_if $ctf_lj (i32.lt_u (local.get $j) 
            (i32.sub (i32.add (local.get $x) (local.get $w)) (i32.const 1))
          ))
        end
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br_if $ctf_li (i32.lt_u (local.get $i) 
          (i32.sub (i32.add (local.get $y) (local.get $h)) (i32.const 1))
        ))
      end

      (if (i32.eq (local.get $mi) (i32.const -1))(then)(else
        (local.set $it (local.get $frags))
        loop $ctf_l3 (if (local.get $it)(then
          (call $pt_set_x (call $pl_get_tail (local.get $it)) (local.get $mj) )
          (call $pt_set_y (call $pl_get_tail (local.get $it)) (local.get $mi) )
          (local.set $it (call $pl_get_next (local.get $it)))

          (br $ctf_l3)
        ))end
      ))

    ))))
    
    (local.get $frags)
  
  )

  ;; Trace skeleton from thinning result.
  ;; Algorithm:
  ;; 1. if chunk size is small enough, reach recursive bottom and turn it into segments
  ;; 2. attempt to split the chunk into 2 smaller chunks, either horizontall or vertically;
  ;;    find the best "seam" to carve along, and avoid possible degenerate cases
  ;; 3. recurse on each chunk, and merge their segments
  ;;
  ;; @param x       left of   chunk
  ;; @param y       top of    chunk
  ;; @param w       width of  chunk
  ;; @param h       height of chunk
  ;; @param iter    number of iteration left
  ;; @return        pointer to polylines
  ;;
  (func $trace_skeleton_impl (param $x i32) (param $y i32) (param $w i32) (param $h i32) (param $iter i32) (result i32)
    
    (local $frags i32) ;; pointer holding all polylines

    ;; calculation of column/row of least resistance
    (local $s i32)  ;; current score
    (local $ms i32) ;; minimal score
    (local $mi i32) ;; minimal row
    (local $mj i32) ;; minimal column

    ;; iterators
    (local $i i32)
    (local $j i32)

    ;; center of chunk
    (local $cx i32)
    (local $cy i32)

    ;; bounding boxes
    (local $L0 i32) ;; left
    (local $L1 i32)
    (local $L2 i32)
    (local $L3 i32)
    (local $R0 i32) ;; right
    (local $R1 i32)
    (local $R2 i32)
    (local $R3 i32)

    ;; seam info
    (local $sx i32) ;; seam position
    (local $dr i32) ;; seam direction


    (local.set $frags (i32.const 0))
    (if (i32.lt_s (local.get $iter) (i32.const 1))(then ;; gameover
      (local.get $frags)
      return
    ))
    (if (i32.or
      (i32.gt_u (local.get $w) (global.get $CHUNK_SIZE))
      (i32.gt_u (local.get $h) (global.get $CHUNK_SIZE))
    )(then)(else ;; recursive bottom
    (local.get $frags)
      (call $chunk_to_frags (local.get $x) (local.get $y) (local.get $w) (local.get $h))
      return
    ))

    (local.set $cx (i32.add (local.get $x) (i32.div_u (local.get $w) (i32.const 2))))
    (local.set $cy (i32.add (local.get $y) (i32.div_u (local.get $h) (i32.const 2))))

    ;; number of white pixels on the seam, less the better:
    (local.set $ms (i32.add (global.get $W) (global.get $H) ))
    (local.set $mi (i32.const -1)) ;; horizontal seam candidate
    (local.set $mj (i32.const -1)) ;; vertical   seam candidate

    ;; try splitting top and bottom
    (if (i32.gt_u (local.get $h) (global.get $CHUNK_SIZE) ) (then
      (local.set $i (i32.add (local.get $y) (i32.const 3)))
      loop $ts_loop_hi
        
        (if (i32.or 
            (i32.or
              (call $im_get (local.get $x) (local.get $i) )
              (call $im_get (local.get $x) (i32.sub (local.get $i) (i32.const 1)) )
            )(i32.or
              (call $im_get 
                (i32.sub (i32.add (local.get $x) (local.get $w)) (i32.const 1))
                (local.get $i)
              )(call $im_get
                (i32.sub (i32.add (local.get $x) (local.get $w)) (i32.const 1))
                (i32.sub (local.get $i) (i32.const 1))              
              )
            )
        )(then)(else
          (local.set $s (i32.const 0))
          (local.set $j (local.get $x))
          loop $ts_loop_hj
            (local.set $s (i32.add (local.get $s) (call $im_get (local.get $j) (local.get $i))))
            (local.set $s (i32.add (local.get $s) 
              (call $im_get (local.get $j) (i32.sub (local.get $i) (i32.const 1)))
            ))
            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br_if $ts_loop_hj (i32.lt_u (local.get $j) (i32.add (local.get $x) (local.get $w))))
          end

          (if (i32.lt_u (local.get $s) (local.get $ms)) (then
            (local.set $ms (local.get $s))
            (local.set $mi (local.get $i))
          )(else (if (i32.eq (local.get $s) (local.get $ms)) (then
            ;; if there is a draw (very common), we want the seam to be near the middle
            ;; to balance the divide and conquer tree
            (if (i32.lt_u
              (call $abs_i32 (i32.sub (local.get $i)  (local.get $cy) ))
              (call $abs_i32 (i32.sub (local.get $mi) (local.get $cy) ))
            )(then
              (local.set $ms (local.get $s))
              (local.set $mi (local.get $i))            
            ))

          ))))
        ))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br_if $ts_loop_hi (i32.lt_u (local.get $i) 
          (i32.sub (i32.add (local.get $y) (local.get $h)) (i32.const 3))
        ))
      end
    ))

    ;; same as above, try splitting left and right
    (if (i32.gt_u (local.get $w) (global.get $CHUNK_SIZE) ) (then
      (local.set $j (i32.add (local.get $x) (i32.const 3)))
      loop $ts_loop_wj
        (if (i32.or 
            (i32.or
              (call $im_get (local.get $j) (local.get $y) )
              (call $im_get (local.get $j) (i32.sub (i32.add (local.get $y) (local.get $h)) (i32.const 1)) )
            )(i32.or
              (call $im_get 
                (i32.sub (local.get $j) (i32.const 1))
                (local.get $y)
              )(call $im_get
                (i32.sub (local.get $j) (i32.const 1))
                (i32.sub (i32.add (local.get $y) (local.get $h)) (i32.const 1))      
              )
            )
        )(then)(else
          (local.set $s (i32.const 0))
          (local.set $i (local.get $y))
          loop $ts_loop_wi
            (local.set $s (i32.add (local.get $s) (call $im_get (local.get $j) (local.get $i))))
            (local.set $s (i32.add (local.get $s) 
              (call $im_get (i32.sub (local.get $j) (i32.const 1)) (local.get $i))
            ))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br_if $ts_loop_wi (i32.lt_u (local.get $i) (i32.add (local.get $y) (local.get $h))))
          end
          (if (i32.lt_u (local.get $s) (local.get $ms)) (then
            (local.set $ms (local.get $s))
            (local.set $mi (i32.const -1)) ;; horizontal seam is defeated
            (local.set $mj (local.get $j))
          )(else (if (i32.eq (local.get $s) (local.get $ms)) (then
            
            (if (i32.lt_u
              (call $abs_i32 (i32.sub (local.get $j)  (local.get $cx) ))
              (call $abs_i32 (i32.sub (local.get $mj) (local.get $cx) ))
            )(then
              (local.set $ms (local.get $s))
              (local.set $mi (i32.const -1))
              (local.set $mj (local.get $j))       
            ))

          ))))
        ))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br_if $ts_loop_wj (i32.lt_u (local.get $j) 
          (i32.sub (i32.add (local.get $x) (local.get $w)) (i32.const 3))
        ))
      end
    ))

    (local.set $L0 (i32.const -1))
    (local.set $R0 (i32.const -1))
    (local.set $dr (i32.const -1))

    (if (i32.and
      (i32.gt_u (local.get $h) (global.get $CHUNK_SIZE))
      (i32.gt_s (local.get $mi) (i32.const -1)) 
    )(then ;; split top and bottom
      (local.set $L0 (local.get $x))
      (local.set $L1 (local.get $y))
      (local.set $L2 (local.get $w))
      (local.set $L3 (i32.sub (local.get $mi) (local.get $y)))
      (local.set $R0 (local.get $x))
      (local.set $R1 (local.get $mi))
      (local.set $R2 (local.get $w))
      (local.set $R3 (i32.sub (i32.add (local.get $y) (local.get $h)) (local.get $mi)))

      (local.set $dr (i32.const 1))
      (local.set $sx (local.get $mi))

    )(else(if (i32.and
      (i32.gt_u (local.get $w) (global.get $CHUNK_SIZE))
      (i32.gt_s (local.get $mj) (i32.const -1)) 
    )(then ;; split left and right
      (local.set $L0 (local.get $x))
      (local.set $L1 (local.get $y))
      (local.set $L2 (i32.sub (local.get $mj) (local.get $x)))
      (local.set $L3 (local.get $h))
      (local.set $R0 (local.get $mj))
      (local.set $R1 (local.get $y))
      (local.set $R2 (i32.sub (i32.add (local.get $x) (local.get $w)) (local.get $mj)))    
      (local.set $R3 (local.get $h))

      (local.set $dr (i32.const 0))
      (local.set $sx (local.get $mj))
    ))))


    (if (i32.gt_s (local.get $dr) (i32.const -1))(then

      ;; if there are no white pixels, don't waste time
      (if (call $not_empty (local.get $L0) (local.get $L1) (local.get $L2) (local.get $L3)  )(then

        (local.set $frags (call $trace_skeleton_impl 
          (local.get $L0) (local.get $L1) (local.get $L2) (local.get $L3) 
          (i32.sub (local.get $iter) (i32.const 1))
        ))
      ))

      (if (call $not_empty (local.get $R0) (local.get $R1) (local.get $R2) (local.get $R3)  )(then

        (local.set $frags (call $merge_frags (local.get $frags) 
          (call $trace_skeleton_impl 
            (local.get $R0) (local.get $R1) (local.get $R2) (local.get $R3) 
            (i32.sub (local.get $iter) (i32.const 1))
          )
          (local.get $sx)
          (local.get $dr)
        ))
      ))

    ))

    (if (i32.and 
      (i32.eq (local.get $mi) (i32.const -1))
      (i32.eq (local.get $mj) (i32.const -1))
    )(then ;; splitting failed! do the recursive bottom instead

      (call $chunk_to_frags (local.get $x) (local.get $y) (local.get $w) (local.get $h))
      return
    ))

    (local.get $frags)
  )

  ;; user-facing main function that calls the reursive implementation
  ;; returns: pointer to polylines
  (func $trace_skeleton (result i32)
    (call $trace_skeleton_impl (i32.const 0) (i32.const 0) (global.get $W) (global.get $H) (global.get $MAX_ITER))
  )

  ;; setup (call before trace_skeleton() and im_set())
  ;; w: width, h: height
  (func $setup (param $w i32) (param $h i32)
    (global.set $W (local.get $w))
    (global.set $H (local.get $h))
    (global.set $im_ptr (call $malloc (i32.mul (global.get $W) (global.get $H))))
  )

  ;; exported API's

  ;; global parameters
  (export "MAX_ITER"       (global $MAX_ITER))
  (export "CHUNK_SIZE"     (global $CHUNK_SIZE))

  ;; input image I/O
  (export "im_set"         (func   $im_set))
  (export "im_get"         (func   $im_get))

  ;; datastructure I/O

  ;; polylines
  (export "pl_new"         (func   $pl_new))
  (export "pl_get_head"    (func   $pl_get_head))
  (export "pl_get_tail"    (func   $pl_get_tail))
  (export "pl_get_next"    (func   $pl_get_next))
  (export "pl_get_prev"    (func   $pl_get_prev))
  (export "pl_get_size"    (func   $pl_get_size))
  (export "pl_set_head"    (func   $pl_set_head))
  (export "pl_set_tail"    (func   $pl_set_tail))
  (export "pl_set_next"    (func   $pl_set_next))
  (export "pl_set_prev"    (func   $pl_set_prev))
  (export "pl_set_size"    (func   $pl_set_size))
  (export "pl_add_pt"      (func   $pl_add_pt))
  (export "pls_destroy"    (func   $pls_destroy))

  ;; points
  (export "pt_get_x"       (func   $pt_get_x))
  (export "pt_get_y"       (func   $pt_get_y))
  (export "pt_get_next"    (func   $pt_get_next))

  ;; main functions
  (export "setup"          (func   $setup))
  (export "thinning_zs"    (func   $thinning_zs))
  (export "trace_skeleton" (func   $trace_skeleton))

  ;; heap
  (export "mem"            (memory $mem    ))

)
;; MIT License
;; 
;; Copyright (c) 2020 Lingdong Huang
;; 
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;; 
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.