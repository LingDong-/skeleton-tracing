import _TRACESKELETON from './dist/trace_skeleton.js';

class TraceSkeleton {
  constructor(tracer) {
    if (typeof tracer === 'undefined') {
      throw new Error('Cannot be called directly');
    }
    this.tracer = tracer;
  }
  static load() {
    return _TRACESKELETON().then((d) => {
      return new TraceSkeleton(d);
    });
  }

  fromBoolArray(im, w, h) {
    var str = '';
    for (var i = 0; i < im.length; i++) {
      if (im[i]) {
        str += String.fromCharCode(1);
      } else {
        str += String.fromCharCode(0);
      }
    }
    return this.fromCharString(str, w, h);
  }
  fromImageData(im) {
    var w = im.width;
    var h = im.height;
    var data = im.data;
    var str = '';
    for (var i = 0; i < data.length; i += 4) {
      if (data[i]) {
        str += String.fromCharCode(1);
      } else {
        str += String.fromCharCode(0);
      }
    }
    return this.fromCharString(str, w, h);
  }
  fromCanvas(im) {
    var ctx = im.getContext('2d');
    var imdata = ctx.getImageData(0, 0, im.width, im.height);
    return this.fromImageData(imdata);
  }
  fromCharString(im, w, h) {
    var T = new this.tracer.skeleton_tracer_t();
    var s = T.trace(im, w, h);
    var r = s
      .split('RECTS:')[1]
      .split('\n')
      .filter((x) => x.length)
      .map((x) => x.split(',').map((x) => parseInt(x)));
    var p = s
      .split('RECTS:')[0]
      .split('POLYLINES:')[1]
      .split('\n')
      .filter((x) => x.length)
      .map((x) =>
        x
          .split(' ')
          .filter((x) => x.length)
          .map((x) => x.split(',').map((x) => parseInt(x)))
      );
    var ret = {
      rects: r,
      polylines: p,
      width: w,
      height: h,
    };
    this.tracer.destroy(T);
    return ret;
  }
  visualize(ret, args) {
    var r = ret.rects;
    var p = ret.polylines;

    if (args == undefined) {
      args = {};
    }
    var s = args.scale == undefined ? 1 : args.scale;
    var sw = args.strokeWidth == undefined ? 1 : args.strokeWidth;
    var dr = args.rects == undefined ? 1 : 0;
    var kpt = (args.keypoints = undefined ? 0 : 1);

    var svg = `<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="${
      ret.width * s
    }" height="${ret.height * s}">`;

    if (dr) {
      for (var i = 0; i < r.length; i++) {
        svg += `<rect fill="none" stroke="gray" x="${r[i][0] * s}" y="${
          r[i][1] * s
        }" width="${r[i][2] * s}" height="${r[i][3] * s}" />`;
      }
    }
    for (var i = 0; i < p.length; i++) {
      svg += `<path fill="none" stroke-width="${sw}" stroke="rgb(${Math.floor(
        Math.random() * 200
      )},${Math.floor(Math.random() * 200)},${Math.floor(
        Math.random() * 200
      )})" d="M${p[i].map((x) => x[0] * s + ',' + x[1] * s).join(' L')}"/>`;
    }
    if (kpt) {
      for (var i = 0; i < p.length; i++) {
        for (var j = 0; j < p[i].length; j++) {
          svg += `<rect fill="none" stroke="red" x="${p[i][j][0] * s - 1}" y="${
            p[i][j][1] * s - 1
          }" width="2" height="2"/>`;
        }
      }
    }

    svg += '</svg>';
    return svg;
  }
}
export default TraceSkeleton;
