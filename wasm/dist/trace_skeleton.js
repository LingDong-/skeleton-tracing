
var _TRACESKELETON = (new function() {
  var _scriptDir = typeof document !== 'undefined' && document.currentScript ? document.currentScript.src : undefined;
  if (typeof __filename !== 'undefined') _scriptDir = _scriptDir || __filename;
  return (
function(_TRACESKELETON) {
  _TRACESKELETON = _TRACESKELETON || {};


var b;b||(b=typeof _TRACESKELETON !== 'undefined' ? _TRACESKELETON : {});var l={},m;for(m in b)b.hasOwnProperty(m)&&(l[m]=b[m]);var n=!1,q=!1,r=!1,t=!1;n="object"===typeof window;q="function"===typeof importScripts;r="object"===typeof process&&"object"===typeof process.versions&&"string"===typeof process.versions.node;t=!n&&!r&&!q;var u="",v,w,x,y;
if(r)u=q?require("path").dirname(u)+"/":__dirname+"/",v=function(a,c){x||(x=require("fs"));y||(y=require("path"));a=y.normalize(a);return x.readFileSync(a,c?null:"utf8")},w=function(a){a=v(a,!0);a.buffer||(a=new Uint8Array(a));assert(a.buffer);return a},1<process.argv.length&&process.argv[1].replace(/\\/g,"/"),process.argv.slice(2),process.on("uncaughtException",function(a){throw a;}),process.on("unhandledRejection",z),b.inspect=function(){return"[Emscripten Module object]"};else if(t)"undefined"!=
typeof read&&(v=function(a){return read(a)}),w=function(a){if("function"===typeof readbuffer)return new Uint8Array(readbuffer(a));a=read(a,"binary");assert("object"===typeof a);return a},"undefined"!==typeof print&&("undefined"===typeof console&&(console={}),console.log=print,console.warn=console.error="undefined"!==typeof printErr?printErr:print);else if(n||q)q?u=self.location.href:document.currentScript&&(u=document.currentScript.src),_scriptDir&&(u=_scriptDir),0!==u.indexOf("blob:")?u=u.substr(0,
u.lastIndexOf("/")+1):u="",v=function(a){var c=new XMLHttpRequest;c.open("GET",a,!1);c.send(null);return c.responseText},q&&(w=function(a){var c=new XMLHttpRequest;c.open("GET",a,!1);c.responseType="arraybuffer";c.send(null);return new Uint8Array(c.response)});var aa=b.print||console.log.bind(console),A=b.printErr||console.warn.bind(console);for(m in l)l.hasOwnProperty(m)&&(b[m]=l[m]);l=null;var B;b.wasmBinary&&(B=b.wasmBinary);var noExitRuntime;b.noExitRuntime&&(noExitRuntime=b.noExitRuntime);
"object"!==typeof WebAssembly&&A("no native wasm support detected");var C,ba=new WebAssembly.Table({initial:1,maximum:1,element:"anyfunc"}),D=!1;function assert(a,c){a||z("Assertion failed: "+c)}var E="undefined"!==typeof TextDecoder?new TextDecoder("utf8"):void 0;"undefined"!==typeof TextDecoder&&new TextDecoder("utf-16le");var F,G,H,I;
function ca(a){F=a;b.HEAP8=G=new Int8Array(a);b.HEAP16=new Int16Array(a);b.HEAP32=I=new Int32Array(a);b.HEAPU8=H=new Uint8Array(a);b.HEAPU16=new Uint16Array(a);b.HEAPU32=new Uint32Array(a);b.HEAPF32=new Float32Array(a);b.HEAPF64=new Float64Array(a)}var da=b.INITIAL_MEMORY||16777216;b.wasmMemory?C=b.wasmMemory:C=new WebAssembly.Memory({initial:da/65536,maximum:32768});C&&(F=C.buffer);da=F.byteLength;ca(F);I[472]=5244928;
function J(a){for(;0<a.length;){var c=a.shift();if("function"==typeof c)c(b);else{var f=c.u;"number"===typeof f?void 0===c.s?b.dynCall_v(f):b.dynCall_vi(f,c.s):f(void 0===c.s?null:c.s)}}}var ea=[],fa=[],ha=[],ia=[];function ja(){var a=b.preRun.shift();ea.unshift(a)}var K=0,L=null,M=null;b.preloadedImages={};b.preloadedAudios={};function z(a){if(b.onAbort)b.onAbort(a);aa(a);A(a);D=!0;throw new WebAssembly.RuntimeError("abort("+a+"). Build with -s ASSERTIONS=1 for more info.");}
function ka(){var a=N;return String.prototype.startsWith?a.startsWith("data:application/octet-stream;base64,"):0===a.indexOf("data:application/octet-stream;base64,")}var N="trace_skeleton.wasm";if(!ka()){var la=N;N=b.locateFile?b.locateFile(la,u):u+la}function ma(){try{if(B)return new Uint8Array(B);if(w)return w(N);throw"both async and sync fetching of the wasm failed";}catch(a){z(a)}}
function na(){return B||!n&&!q||"function"!==typeof fetch?new Promise(function(a){a(ma())}):fetch(N,{credentials:"same-origin"}).then(function(a){if(!a.ok)throw"failed to load wasm binary file at '"+N+"'";return a.arrayBuffer()}).catch(function(){return ma()})}fa.push({u:function(){oa()}});
var pa={c:function(){z()},a:function(a,c,f){H.copyWithin(a,c,c+f)},b:function(a){var c=H.length;if(2147483648<a)return!1;for(var f=1;4>=f;f*=2){var g=c*(1+.2/f);g=Math.min(g,a+100663296);g=Math.max(16777216,a,g);0<g%65536&&(g+=65536-g%65536);a:{try{C.grow(Math.min(2147483648,g)-F.byteLength+65535>>>16);ca(C.buffer);var d=1;break a}catch(e){}d=void 0}if(d)return!0}return!1},memory:C,table:ba},qa=function(){function a(d){b.asm=d.exports;K--;b.monitorRunDependencies&&b.monitorRunDependencies(K);0==K&&
(null!==L&&(clearInterval(L),L=null),M&&(d=M,M=null,d()))}function c(d){a(d.instance)}function f(d){return na().then(function(e){return WebAssembly.instantiate(e,g)}).then(d,function(e){A("failed to asynchronously prepare wasm: "+e);z(e)})}var g={a:pa};K++;b.monitorRunDependencies&&b.monitorRunDependencies(K);if(b.instantiateWasm)try{return b.instantiateWasm(g,a)}catch(d){return A("Module.instantiateWasm callback failed with error: "+d),!1}(function(){if(B||"function"!==typeof WebAssembly.instantiateStreaming||
ka()||"function"!==typeof fetch)return f(c);fetch(N,{credentials:"same-origin"}).then(function(d){return WebAssembly.instantiateStreaming(d,g).then(c,function(e){A("wasm streaming compile failed: "+e);A("falling back to ArrayBuffer instantiation");f(c)})})})();return{}}();b.asm=qa;
var oa=b.___wasm_call_ctors=function(){return(oa=b.___wasm_call_ctors=b.asm.d).apply(null,arguments)},ra=b._emscripten_bind_VoidPtr___destroy___0=function(){return(ra=b._emscripten_bind_VoidPtr___destroy___0=b.asm.e).apply(null,arguments)},sa=b._emscripten_bind_skeleton_tracer_t_skeleton_tracer_t_0=function(){return(sa=b._emscripten_bind_skeleton_tracer_t_skeleton_tracer_t_0=b.asm.f).apply(null,arguments)},ta=b._emscripten_bind_skeleton_tracer_t_trace_3=function(){return(ta=b._emscripten_bind_skeleton_tracer_t_trace_3=
b.asm.g).apply(null,arguments)};b._free=function(){return(b._free=b.asm.h).apply(null,arguments)};b._malloc=function(){return(b._malloc=b.asm.i).apply(null,arguments)};var ua=b._emscripten_bind_skeleton_tracer_t_destroy_0=function(){return(ua=b._emscripten_bind_skeleton_tracer_t_destroy_0=b.asm.j).apply(null,arguments)},va=b._emscripten_bind_skeleton_tracer_t___destroy___0=function(){return(va=b._emscripten_bind_skeleton_tracer_t___destroy___0=b.asm.k).apply(null,arguments)};b.asm=qa;var O;
b.then=function(a){if(O)a(b);else{var c=b.onRuntimeInitialized;b.onRuntimeInitialized=function(){c&&c();a(b)}}return b};M=function wa(){O||P();O||(M=wa)};
function P(){function a(){if(!O&&(O=!0,b.calledRun=!0,!D)){J(fa);J(ha);if(b.onRuntimeInitialized)b.onRuntimeInitialized();if(b.postRun)for("function"==typeof b.postRun&&(b.postRun=[b.postRun]);b.postRun.length;){var c=b.postRun.shift();ia.unshift(c)}J(ia)}}if(!(0<K)){if(b.preRun)for("function"==typeof b.preRun&&(b.preRun=[b.preRun]);b.preRun.length;)ja();J(ea);0<K||(b.setStatus?(b.setStatus("Running..."),setTimeout(function(){setTimeout(function(){b.setStatus("")},1);a()},1)):a())}}b.run=P;
if(b.preInit)for("function"==typeof b.preInit&&(b.preInit=[b.preInit]);0<b.preInit.length;)b.preInit.pop()();noExitRuntime=!0;P();function Q(){}Q.prototype=Object.create(Q.prototype);Q.prototype.constructor=Q;Q.prototype.m=Q;Q.o={};b.WrapperObject=Q;function R(a){return(a||Q).o}b.getCache=R;function S(a,c){var f=R(c),g=f[a];if(g)return g;g=Object.create((c||Q).prototype);g.l=a;return f[a]=g}b.wrapPointer=S;b.castObject=function(a,c){return S(a.l,c)};b.NULL=S(0);
b.destroy=function(a){if(!a.__destroy__)throw"Error: Cannot destroy object. (Did you create it yourself?)";a.__destroy__();delete R(a.m)[a.l]};b.compare=function(a,c){return a.l===c.l};b.getPointer=function(a){return a.l};b.getClass=function(a){return a.m};var T=0,U=0,V=0,W=[],X=0;function Y(){throw"cannot construct a VoidPtr, no constructor in IDL";}Y.prototype=Object.create(Q.prototype);Y.prototype.constructor=Y;Y.prototype.m=Y;Y.o={};b.VoidPtr=Y;Y.prototype.__destroy__=function(){ra(this.l)};
function Z(){this.l=sa();R(Z)[this.l]=this}Z.prototype=Object.create(Q.prototype);Z.prototype.constructor=Z;Z.prototype.m=Z;Z.o={};b.skeleton_tracer_t=Z;
Z.prototype.trace=function(a,c,f){var g=this.l;if(X){for(var d=0;d<W.length;d++)b._free(W[d]);W.length=0;b._free(T);T=0;U+=X;X=0}T||(U+=128,T=b._malloc(U),assert(T));V=0;if(a&&"object"===typeof a)a=a.l;else if(d=a,"string"===typeof d){for(var e=a=0;e<d.length;++e){var h=d.charCodeAt(e);55296<=h&&57343>=h&&(h=65536+((h&1023)<<10)|d.charCodeAt(++e)&1023);127>=h?++a:a=2047>=h?a+2:65535>=h?a+3:a+4}a=Array(a+1);h=a.length;e=0;if(0<h){h=e+h-1;for(var p=0;p<d.length;++p){var k=d.charCodeAt(p);if(55296<=
k&&57343>=k){var xa=d.charCodeAt(++p);k=65536+((k&1023)<<10)|xa&1023}if(127>=k){if(e>=h)break;a[e++]=k}else{if(2047>=k){if(e+1>=h)break;a[e++]=192|k>>6}else{if(65535>=k){if(e+2>=h)break;a[e++]=224|k>>12}else{if(e+3>=h)break;a[e++]=240|k>>18;a[e++]=128|k>>12&63}a[e++]=128|k>>6&63}a[e++]=128|k&63}}a[e]=0}d=G;assert(T);d=a.length*d.BYTES_PER_ELEMENT;d=d+7&-8;V+d>=U?(assert(0<d),X+=d,e=b._malloc(d),W.push(e)):(e=T+V,V+=d);d=e;h=G;e=d>>>0;switch(h.BYTES_PER_ELEMENT){case 2:e>>>=1;break;case 4:e>>>=2;break;
case 8:e>>>=3}for(p=0;p<a.length;p++)h[e+p]=a[p];a=d}else a=d;c&&"object"===typeof c&&(c=c.l);f&&"object"===typeof f&&(f=f.l);if(c=ta(g,a,c,f)){f=H;a=c+NaN;for(g=c;f[g]&&!(g>=a);)++g;if(16<g-c&&f.subarray&&E)c=E.decode(f.subarray(c,g));else{for(a="";c<g;)d=f[c++],d&128?(e=f[c++]&63,192==(d&224)?a+=String.fromCharCode((d&31)<<6|e):(h=f[c++]&63,d=224==(d&240)?(d&15)<<12|e<<6|h:(d&7)<<18|e<<12|h<<6|f[c++]&63,65536>d?a+=String.fromCharCode(d):(d-=65536,a+=String.fromCharCode(55296|d>>10,56320|d&1023)))):
a+=String.fromCharCode(d);c=a}}else c="";return c};Z.prototype.destroy=function(){ua(this.l)};Z.prototype.__destroy__=function(){va(this.l)};


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
          svg += `<rect fill="none" stroke="red" x="${p[i][j][0]*s-1}" y="${p[i][j][1]*s-1}" width="2" height="2"/>`
        }
      }
    }

    svg += "</svg>"
    return svg;
  }
}
/* END HANDWRITTEN WRAPPER */