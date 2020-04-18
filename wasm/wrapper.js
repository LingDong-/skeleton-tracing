/* BEGIN HANDWRITTEN WRAPPER */
var TraceSkeleton = new function (){var that = this;
  that.onload = function(f){
    _TRACESKELETON.then(f);
  }
  that.fromBoolArray = function(im,w,h){
    var str = "";
    for (var i = 0; i < im.length; i++){
      if (im[i]){
        str += "\1";
      }else{
        str += "\0";
      }
    }
    return that.fromCharString(str,w,h);
  }
  that.fromImageData = function(im){
    var w = im.width;
    var h = im.height;
    var data = im.data;
    str = "";
    for (var i = 0; i < data.length; i+=4){
      if (data[i]){
        str += "\1";
      }else{
        str += "\0";
      }
    }
    return that.fromCharString(str,w,h);
  }
  that.fromCanvas = function(im){
    var ctx = im.getContext('2d');
    var imdata = ctx.getImageData(0,0,im.width,im.height);
    return that.fromImageData(imdata);
  }
  that.fromCharString = function(im,w,h){
    var T = new _TRACESKELETON.skeleton_tracer_t();
    var s = T.trace(im,w,h);
    var r = s.split("RECTS:")[1].split("\n").filter(x=>x.length).map(x=>x.split(",").map(x=>parseInt(x)));
    var p = s.split("RECTS:")[0].split("POLYLINES:")[1].split("\n").filter(x=>x.length).map(x=>x.split(" ").filter(x=>x.length).map(x=>x.split(",").map(x=>parseInt(x))));
    var ret = {
      rects:r,
      polylines:p,
      width:w,
      height:h,
    }
    // T.destroy();
    _TRACESKELETON.destroy(T);
    return ret;
  }
  that.visualize = function(ret,args){
    var r = ret.rects;
    var p = ret.polylines;

    if (args == undefined){args = {}}
    var s = args.scale == undefined ? 1 : args.scale;
    var sw = args.strokeWidth == undefined ? 1 : args.strokeWidth;
    var dr = args.rects == undefined ? 1 : 0;
    var kpt = args.keypoints = undefined ? 0 : 1;

    var svg = `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="${ret.width*s}" height="${ret.height*s}">`

    if (dr){
      for (var i = 0; i < r.length; i++){
        svg += `<rect fill="none" stroke="gray" x="${r[i][0]*s}" y="${r[i][1]*s}" width="${r[i][2]*s}" height="${r[i][3]*s}" />`
      }
    }
    for (var i = 0; i < p.length; i++){
      svg += `<path fill="none" stroke-width="${sw}" stroke="rgb(${Math.floor(Math.random()*200)},${Math.floor(Math.random()*200)},${Math.floor(Math.random()*200)})" d="M${p[i].map(x=>x[0]*s+","+x[1]*s).join(" L")}"/>`
    }
    if (kpt){
      for (var i = 0; i < p.length; i++){
        for (var j = 0; j < p[i].length; j++){
          svg += `<rect fill="none" stroke="red" x="${p[i][j][0]*s-5}" y="${p[i][j][1]*s-5}" width="10" height="10"/>`
        }
      }
    }

    svg += "</svg>"
    return svg;
  }
}
/* END HANDWRITTEN WRAPPER */