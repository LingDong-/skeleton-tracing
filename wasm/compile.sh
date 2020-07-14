# STEP 0: change EMPATH below
# STEP 1: cd ./wasm/dist
# STEP 2: sh ../compile.sh

EMPATH=../../../emsdk/upstream/emscripten
echo "generating glue..."
python $EMPATH/tools/webidl_binder.py ../trace_skeleton.idl glue
echo "compiling..."
$EMPATH/emcc ../glue_wrapper.cpp --post-js glue.js  -std=c++11 -s EXPORT_NAME="_TRACESKELETON" --closure 1 -s MODULARIZE=1 -s ALLOW_MEMORY_GROWTH=1 -s WASM=1 -O3 -o trace_skeleton.js
# echo "converting to static module..."
# sed -i '' 's/var _TRACESKELETON = (function() {/var _TRACESKELETON = (new function() {/' trace_skeleton.js
# echo "concating custom wrapper..."
# cat ../wrapper.js >> trace_skeleton.js