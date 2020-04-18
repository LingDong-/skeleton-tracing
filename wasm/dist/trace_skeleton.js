
var _TRACESKELETON = (new function() {
  var _scriptDir = typeof document !== 'undefined' && document.currentScript ? document.currentScript.src : undefined;
  if (typeof __filename !== 'undefined') _scriptDir = _scriptDir || __filename;
  return (
function(_TRACESKELETON) {
  _TRACESKELETON = _TRACESKELETON || {};


var b;b||(b=typeof _TRACESKELETON !== 'undefined' ? _TRACESKELETON : {});var l={},n;for(n in b)b.hasOwnProperty(n)&&(l[n]=b[n]);var p=!1,q=!1,r=!1,t=!1;p="object"===typeof window;q="function"===typeof importScripts;r="object"===typeof process&&"object"===typeof process.versions&&"string"===typeof process.versions.node;t=!p&&!r&&!q;var u="",v,w,x,y;
if(r)u=q?require("path").dirname(u)+"/":__dirname+"/",v=function(a,c){x||(x=require("fs"));y||(y=require("path"));a=y.normalize(a);return x.readFileSync(a,c?null:"utf8")},w=function(a){a=v(a,!0);a.buffer||(a=new Uint8Array(a));assert(a.buffer);return a},1<process.argv.length&&process.argv[1].replace(/\\/g,"/"),process.argv.slice(2),process.on("uncaughtException",function(a){throw a;}),process.on("unhandledRejection",z),b.inspect=function(){return"[Emscripten Module object]"};else if(t)"undefined"!=
typeof read&&(v=function(a){return read(a)}),w=function(a){if("function"===typeof readbuffer)return new Uint8Array(readbuffer(a));a=read(a,"binary");assert("object"===typeof a);return a},"undefined"!==typeof print&&("undefined"===typeof console&&(console={}),console.log=print,console.warn=console.error="undefined"!==typeof printErr?printErr:print);else if(p||q)q?u=self.location.href:document.currentScript&&(u=document.currentScript.src),_scriptDir&&(u=_scriptDir),0!==u.indexOf("blob:")?u=u.substr(0,
u.lastIndexOf("/")+1):u="",v=function(a){var c=new XMLHttpRequest;c.open("GET",a,!1);c.send(null);return c.responseText},q&&(w=function(a){var c=new XMLHttpRequest;c.open("GET",a,!1);c.responseType="arraybuffer";c.send(null);return new Uint8Array(c.response)});var aa=b.print||console.log.bind(console),A=b.printErr||console.warn.bind(console);for(n in l)l.hasOwnProperty(n)&&(b[n]=l[n]);l=null;var B;b.wasmBinary&&(B=b.wasmBinary);var noExitRuntime;b.noExitRuntime&&(noExitRuntime=b.noExitRuntime);
"object"!==typeof WebAssembly&&A("no native wasm support detected");var C,ba=new WebAssembly.Table({initial:4,maximum:4,element:"anyfunc"}),ca=!1;function assert(a,c){a||z("Assertion failed: "+c)}var da="undefined"!==typeof TextDecoder?new TextDecoder("utf8"):void 0;
function ea(a,c,f){var g=c+f;for(f=c;a[f]&&!(f>=g);)++f;if(16<f-c&&a.subarray&&da)return da.decode(a.subarray(c,f));for(g="";c<f;){var d=a[c++];if(d&128){var e=a[c++]&63;if(192==(d&224))g+=String.fromCharCode((d&31)<<6|e);else{var h=a[c++]&63;d=224==(d&240)?(d&15)<<12|e<<6|h:(d&7)<<18|e<<12|h<<6|a[c++]&63;65536>d?g+=String.fromCharCode(d):(d-=65536,g+=String.fromCharCode(55296|d>>10,56320|d&1023))}}else g+=String.fromCharCode(d)}return g}"undefined"!==typeof TextDecoder&&new TextDecoder("utf-16le");
var D,E,F,G;function fa(a){D=a;b.HEAP8=E=new Int8Array(a);b.HEAP16=new Int16Array(a);b.HEAP32=G=new Int32Array(a);b.HEAPU8=F=new Uint8Array(a);b.HEAPU16=new Uint16Array(a);b.HEAPU32=new Uint32Array(a);b.HEAPF32=new Float32Array(a);b.HEAPF64=new Float64Array(a)}var ha=b.INITIAL_MEMORY||16777216;b.wasmMemory?C=b.wasmMemory:C=new WebAssembly.Memory({initial:ha/65536,maximum:32768});C&&(D=C.buffer);ha=D.byteLength;fa(D);G[968]=5246912;
function I(a){for(;0<a.length;){var c=a.shift();if("function"==typeof c)c(b);else{var f=c.v;"number"===typeof f?void 0===c.u?b.dynCall_v(f):b.dynCall_vi(f,c.u):f(void 0===c.u?null:c.u)}}}var ia=[],ja=[],ka=[],la=[];function ma(){var a=b.preRun.shift();ia.unshift(a)}var J=0,K=null,L=null;b.preloadedImages={};b.preloadedAudios={};function z(a){if(b.onAbort)b.onAbort(a);aa(a);A(a);ca=!0;throw new WebAssembly.RuntimeError("abort("+a+"). Build with -s ASSERTIONS=1 for more info.");}
function na(){var a=M;return String.prototype.startsWith?a.startsWith("data:application/octet-stream;base64,"):0===a.indexOf("data:application/octet-stream;base64,")}var M="trace_skeleton.wasm";if(!na()){var oa=M;M=b.locateFile?b.locateFile(oa,u):u+oa}function pa(){try{if(B)return new Uint8Array(B);if(w)return w(M);throw"both async and sync fetching of the wasm failed";}catch(a){z(a)}}
function qa(){return B||!p&&!q||"function"!==typeof fetch?new Promise(function(a){a(pa())}):fetch(M,{credentials:"same-origin"}).then(function(a){if(!a.ok)throw"failed to load wasm binary file at '"+M+"'";return a.arrayBuffer()}).catch(function(){return pa()})}ja.push({v:function(){ra()}});
var sa=[null,[],[]],ta={d:function(){z()},b:function(a,c,f){F.copyWithin(a,c,c+f)},c:function(a){var c=F.length;if(2147483648<a)return!1;for(var f=1;4>=f;f*=2){var g=c*(1+.2/f);g=Math.min(g,a+100663296);g=Math.max(16777216,a,g);0<g%65536&&(g+=65536-g%65536);a:{try{C.grow(Math.min(2147483648,g)-D.byteLength+65535>>>16);fa(C.buffer);var d=1;break a}catch(e){}d=void 0}if(d)return!0}return!1},a:function(a,c,f,g){for(var d=0,e=0;e<f;e++){for(var h=G[c+8*e>>2],m=G[c+(8*e+4)>>2],k=0;k<m;k++){var H=F[h+k],
W=sa[a];0===H||10===H?((1===a?aa:A)(ea(W,0)),W.length=0):W.push(H)}d+=m}G[g>>2]=d;return 0},memory:C,table:ba},ua=function(){function a(d){b.asm=d.exports;J--;b.monitorRunDependencies&&b.monitorRunDependencies(J);0==J&&(null!==K&&(clearInterval(K),K=null),L&&(d=L,L=null,d()))}function c(d){a(d.instance)}function f(d){return qa().then(function(e){return WebAssembly.instantiate(e,g)}).then(d,function(e){A("failed to asynchronously prepare wasm: "+e);z(e)})}var g={a:ta};J++;b.monitorRunDependencies&&
b.monitorRunDependencies(J);if(b.instantiateWasm)try{return b.instantiateWasm(g,a)}catch(d){return A("Module.instantiateWasm callback failed with error: "+d),!1}(function(){if(B||"function"!==typeof WebAssembly.instantiateStreaming||na()||"function"!==typeof fetch)return f(c);fetch(M,{credentials:"same-origin"}).then(function(d){return WebAssembly.instantiateStreaming(d,g).then(c,function(e){A("wasm streaming compile failed: "+e);A("falling back to ArrayBuffer instantiation");f(c)})})})();return{}}();
b.asm=ua;
var ra=b.___wasm_call_ctors=function(){return(ra=b.___wasm_call_ctors=b.asm.e).apply(null,arguments)},va=b._emscripten_bind_VoidPtr___destroy___0=function(){return(va=b._emscripten_bind_VoidPtr___destroy___0=b.asm.f).apply(null,arguments)},wa=b._emscripten_bind_skeleton_tracer_t_skeleton_tracer_t_0=function(){return(wa=b._emscripten_bind_skeleton_tracer_t_skeleton_tracer_t_0=b.asm.g).apply(null,arguments)},xa=b._emscripten_bind_skeleton_tracer_t_trace_3=function(){return(xa=b._emscripten_bind_skeleton_tracer_t_trace_3=b.asm.h).apply(null,
arguments)};b._free=function(){return(b._free=b.asm.i).apply(null,arguments)};b._malloc=function(){return(b._malloc=b.asm.j).apply(null,arguments)};var ya=b._emscripten_bind_skeleton_tracer_t_destroy_0=function(){return(ya=b._emscripten_bind_skeleton_tracer_t_destroy_0=b.asm.k).apply(null,arguments)},za=b._emscripten_bind_skeleton_tracer_t___destroy___0=function(){return(za=b._emscripten_bind_skeleton_tracer_t___destroy___0=b.asm.l).apply(null,arguments)};b.asm=ua;var N;
b.then=function(a){if(N)a(b);else{var c=b.onRuntimeInitialized;b.onRuntimeInitialized=function(){c&&c();a(b)}}return b};L=function Aa(){N||O();N||(L=Aa)};
function O(){function a(){if(!N&&(N=!0,b.calledRun=!0,!ca)){I(ja);I(ka);if(b.onRuntimeInitialized)b.onRuntimeInitialized();if(b.postRun)for("function"==typeof b.postRun&&(b.postRun=[b.postRun]);b.postRun.length;){var c=b.postRun.shift();la.unshift(c)}I(la)}}if(!(0<J)){if(b.preRun)for("function"==typeof b.preRun&&(b.preRun=[b.preRun]);b.preRun.length;)ma();I(ia);0<J||(b.setStatus?(b.setStatus("Running..."),setTimeout(function(){setTimeout(function(){b.setStatus("")},1);a()},1)):a())}}b.run=O;
if(b.preInit)for("function"==typeof b.preInit&&(b.preInit=[b.preInit]);0<b.preInit.length;)b.preInit.pop()();noExitRuntime=!0;O();function P(){}P.prototype=Object.create(P.prototype);P.prototype.constructor=P;P.prototype.o=P;P.s={};b.WrapperObject=P;function Q(a){return(a||P).s}b.getCache=Q;function R(a,c){var f=Q(c),g=f[a];if(g)return g;g=Object.create((c||P).prototype);g.m=a;return f[a]=g}b.wrapPointer=R;b.castObject=function(a,c){return R(a.m,c)};b.NULL=R(0);
b.destroy=function(a){if(!a.__destroy__)throw"Error: Cannot destroy object. (Did you create it yourself?)";a.__destroy__();delete Q(a.o)[a.m]};b.compare=function(a,c){return a.m===c.m};b.getPointer=function(a){return a.m};b.getClass=function(a){return a.o};var S=0,T=0,U=0,V=[],X=0;function Y(){throw"cannot construct a VoidPtr, no constructor in IDL";}Y.prototype=Object.create(P.prototype);Y.prototype.constructor=Y;Y.prototype.o=Y;Y.s={};b.VoidPtr=Y;Y.prototype.__destroy__=function(){va(this.m)};
function Z(){this.m=wa();Q(Z)[this.m]=this}Z.prototype=Object.create(P.prototype);Z.prototype.constructor=Z;Z.prototype.o=Z;Z.s={};b.skeleton_tracer_t=Z;
Z.prototype.trace=function(a,c,f){var g=this.m;if(X){for(var d=0;d<V.length;d++)b._free(V[d]);V.length=0;b._free(S);S=0;T+=X;X=0}S||(T+=128,S=b._malloc(T),assert(S));U=0;if(a&&"object"===typeof a)a=a.m;else if(d=a,"string"===typeof d){for(var e=a=0;e<d.length;++e){var h=d.charCodeAt(e);55296<=h&&57343>=h&&(h=65536+((h&1023)<<10)|d.charCodeAt(++e)&1023);127>=h?++a:a=2047>=h?a+2:65535>=h?a+3:a+4}a=Array(a+1);h=a.length;e=0;if(0<h){h=e+h-1;for(var m=0;m<d.length;++m){var k=d.charCodeAt(m);if(55296<=
k&&57343>=k){var H=d.charCodeAt(++m);k=65536+((k&1023)<<10)|H&1023}if(127>=k){if(e>=h)break;a[e++]=k}else{if(2047>=k){if(e+1>=h)break;a[e++]=192|k>>6}else{if(65535>=k){if(e+2>=h)break;a[e++]=224|k>>12}else{if(e+3>=h)break;a[e++]=240|k>>18;a[e++]=128|k>>12&63}a[e++]=128|k>>6&63}a[e++]=128|k&63}}a[e]=0}d=E;assert(S);d=a.length*d.BYTES_PER_ELEMENT;d=d+7&-8;U+d>=T?(assert(0<d),X+=d,e=b._malloc(d),V.push(e)):(e=S+U,U+=d);d=e;h=E;e=d>>>0;switch(h.BYTES_PER_ELEMENT){case 2:e>>>=1;break;case 4:e>>>=2;break;
case 8:e>>>=3}for(m=0;m<a.length;m++)h[e+m]=a[m];a=d}else a=d;c&&"object"===typeof c&&(c=c.m);f&&"object"===typeof f&&(f=f.m);return(c=xa(g,a,c,f))?ea(F,c,void 0):""};Z.prototype.destroy=function(){ya(this.m)};Z.prototype.__destroy__=function(){za(this.m)};


  return _TRACESKELETON
}
);
})();
if (typeof exports === 'object' && typeof module === 'object')
      module.exports = _TRACESKELETON;
    else if (typeof define === 'function' && define['amd'])
      define([], function() { return _TRACESKELETON; });
    else if (typeof exports === 'object')
      exports["_TRACESKELETON"] = _TRACESKELETON;
    
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