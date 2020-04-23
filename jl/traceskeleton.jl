using FileIO
using Printf

const HORIZONTAL = 1
const VERTICAL   = 2

function thinning_zs_iteration(bim,iter)
    h,w = size(bim)
    marker = zeros(Bool,h,w)
    for i=2:h-1
        for j=2:w-1
            p2 = bim[i-1,j]   & 1
            p3 = bim[i-1,j+1] & 1
            p4 = bim[i,j+1]   & 1
            p5 = bim[i+1,j+1] & 1
            p6 = bim[i+1,j]   & 1
            p7 = bim[i+1,j-1] & 1
            p8 = bim[i,j-1]   & 1
            p9 = bim[i-1,j-1] & 1
            a = (p2 == 0 && p3 == 1)+ (p3 == 0 && p4 == 1)+
                (p4 == 0 && p5 == 1)+ (p5 == 0 && p6 == 1)+
                (p6 == 0 && p7 == 1)+ (p7 == 0 && p8 == 1)+
                (p8 == 0 && p9 == 1)+ (p9 == 0 && p2 == 1)
            b = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
            m1 = iter==0 ? (p2*p4*p6) : (p2*p4*p8);
            m2 = iter==0 ? (p4*p6*p8) : (p2*p6*p8);
            if a == 1 && (b >= 2 && b <= 6) && m1 == 0 && m2 == 0
                marker[i,j] = true;
            end
        end
    end
    nim = bim .& (.!marker)
    return nim
end

function thinning_zs(bim)
    while true
        oim = copy(bim)
        bim = thinning_zs_iteration(bim,0)
        bim = thinning_zs_iteration(bim,1)
        dif = sum(bim .⊻ oim)
        if dif == 0
            break
        end
    end
    return bim
end

function merge_impl!(c0,c1,i,sx,isv,mode)
    b0 = Bool(mode >> 1 & 1)
    b1 = Bool(mode >> 0 & 1)
    mj = -1
    md = 4
    p1 = c1[i][b1 ? 1 : end]

    if abs(p1[isv ? 2 : 1] - sx) > 0
        return false
    end
    # find the best match
    for j=1:length(c0)
        p0 = c0[j][b0 ? 1 : end]
        if abs(p0[isv ? 2 : 1] - sx) > 1
            continue
        end
        d = abs(p0[isv ? 1 : 2] - p1[isv ? 1 : 2])
        if d < md
            mj = j
            md = d
        end
    end
    if mj != -1
        j = mj
        if b0 && b1
            splice!(c0[j],1:0,reverse(c1[i]))
        elseif !b0 && b1
            append!(c0[j],c1[i])
        elseif b0 && !b1
            splice!(c0[j],1:0,c1[i])
        else
            append!(c0[j],reverse(c1[i]))
        end
        deleteat!(c1,i)
        return true
    end
    return false
end

function translate!(c,sx,dr)
    x,y = sx-1,0
    if dr == VERTICAL
        y,x = sx-1,0
    end
    for i=1:length(c)
        for j=1:length(c[i])
            c[i][j][1]+=x
            c[i][j][2]+=y
        end
    end
end

function merge_frags!(c0,c1,sx,dr)
    translate!(c1,sx,dr)
    if length(c0) == 0
        append!(c0,c1)
        return
    end
    if length(c1) == 0
        return
    end
    l = length(c1)
    for i=l:-1:1
        if dr == HORIZONTAL
            if merge_impl!(c0,c1,i,sx,false,1) continue end
            if merge_impl!(c0,c1,i,sx,false,3) continue end
            if merge_impl!(c0,c1,i,sx,false,0) continue end
            if merge_impl!(c0,c1,i,sx,false,2) continue end
        elseif dr == VERTICAL
            if merge_impl!(c0,c1,i,sx,true ,1) continue end
            if merge_impl!(c0,c1,i,sx,true ,3) continue end
            if merge_impl!(c0,c1,i,sx,true ,0) continue end
            if merge_impl!(c0,c1,i,sx,true ,2) continue end
        end         
    end
    append!(c0,c1)
    return
end

function chunk_to_frags(bim)
    h,w = size(bim)
    frags = []
    on = false
    li = -1
    lj = -1
    for k=1:h+h+w+w-4
        i = 0
        j = 0
        if k <= w
            i = 1; j = k
        elseif k <= w+h-1
            i = k-w+1; j = w
        elseif k <= w+h+w-2
            i = h; j = w-(k-w-h+1)
        else
            i = h-(k-w-h-w+2); j = 1
        end
    
        if bim[i,j] != 0
            if !on
                on = true
                push!(frags,[[j,i],[w÷2,h÷2]])
            end
        else
            if on # right side of stroke, average to get center of stroke
                on = false
                frags[end][1][1] = (frags[end][1][1]+lj)÷2
                frags[end][1][2] = (frags[end][1][2]+li)÷2
            end
        end
        li = i
        lj = j
    end
    if length(frags) == 2
        frags = [[frags[1][1],frags[2][1]]]
    elseif length(frags) > 2
        ms = 0
        mi = -1
        mj = -1
        # use convolution to find brightest blob
        for i=2:h-1
            for j=2:w-1
                s = 
                   (bim[i-1,j-1]) + (bim[i-1,j]) +(bim[i-1,j+1])+
                   (bim[i,j-1]  ) +   (bim[i,j]) +    (bim[i,j+1])+
                   (bim[i+1,j-1]) + (bim[i+1,j]) +  (bim[i+1,j+1]);
                if s > ms
                    mi = i
                    mj = j
                    ms = s
                elseif s == ms && abs(j-(w÷2))+abs(i-(h÷2)) < abs(mj-(w÷2))+abs(mi-(h÷2))
                    mi = i
                    mj = j
                    ms = s
                end
            end
        end
        if mi != -1
            for i=1:length(frags)
                frags[i][2] = [mj,mi]
            end 
        end
    end
    return frags
end

function trace_skeleton(bim,csize,maxiter)

    h,w = size(bim)
    if maxiter <= 0
        return []
    end
    if w <= csize && h <= csize
        return chunk_to_frags(bim)
    end
    ms = w+h
    mi = -1
    mj = -1
    if h > csize
        for i=4:h-3
            if bim[i,1]>0 || bim[i-1,1]>0 || bim[i,w]>0 || bim[i-1,w]>0
                continue
            end
            s = 0
            for j=1:w
                s+=bim[i,j]
                s+=bim[i-1,j]
            end
            if s < ms
                ms = s; mi = i
            elseif s == ms && abs(i-h÷2)<abs(mi-h÷2)
                # if there is a draw (very common), we want the seam to be near the middle
                # to balance the divide and conquer tree
                ms = s; mi = i
            end
        end
    end
    if w > csize
        for j=4:w-3
            if bim[1,j]>0 || bim[h,j]>0 || bim[1,j-1]>0 || bim[h,j-1]>0
                continue
            end
            s = 0
            for i=1:h
                s+=bim[i,j]
                s+=bim[i,j-1]
            end
            if s < ms
                ms = s;
                mi = -1
                mj = j
            elseif s == ms && abs(j-w÷2)<abs(mj-w÷2)
                ms = s
                mi = -1
                mj = j
            end
        end
    end
    dr = 0
    sx = 0
    L = []
    R = []

    if h > csize && mi != -1
        L = view(bim, 1:mi-1,:)
        R = view(bim, mi:h,  :)
        dr = VERTICAL;
        sx = mi
    elseif w > csize && mj != -1
        L = view(bim, :, 1:mj-1)
        R = view(bim, :, mj:w)
        dr = HORIZONTAL
        sx = mj
    end
    frags = []
    if dr != 0 && sum(L)>0
        frags = trace_skeleton(L,csize,maxiter-1)
    end
    if dr != 0 && sum(R)>0
        merge_frags!(frags,trace_skeleton(R,csize,maxiter-1),sx,dr)
    end
    if mi == -1 && mj == -1
        return chunk_to_frags(bim)
    end
    return frags
end

function polylines_to_svg(q,w,h)
    svg = @sprintf("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" fill=\"none\" stroke=\"black\" stroke-width=\"1\">",w,h)
    for i=1:length(q)
        svg *= "<path d=\""
        for j=1:length(q[i])
            svg *= @sprintf("%s%d,%d ",(j==1 ? "M" : "L"),q[i][j][1],q[i][j][2])
        end
        svg *= "\"/>"
    end
    svg *= "</svg>"
    return svg
end

img = load(ARGS[1])
bim = convert(Array{UInt8}, reshape([round(img[i,j].r) for j=1:size(img)[2] for i=1:size(img)[1]], size(img)))

print("<!-- ")
@time bim = thinning_zs(bim)
H,W = size(bim)
@time q = trace_skeleton(bim,10,999)
print(" -->")
print(polylines_to_svg(q,W,H))

# using ColorTypes
# img = convert(Array{ColorTypes.Gray{Bool}}, convert(Array{Bool},bim))
# save("out.jpg",img)


