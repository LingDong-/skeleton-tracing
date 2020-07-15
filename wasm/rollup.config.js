// rollup.config.js
import ascii from 'rollup-plugin-ascii';
import { terser } from 'rollup-plugin-terser';
import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';
import nodePolyfills from 'rollup-plugin-node-polyfills';

export default [
  {
    input: 'index.js',
    plugins: [
      nodePolyfills(),
      resolve(),
      commonjs(),
      ascii(),
    ],
    output: {
      extend: true,
      file: 'build/trace_skeleton_wasm.js',
      format: 'umd',
      name: 'TraceSkeleton',
    },
  },
  {
    input: 'index.js',
    plugins: [
      nodePolyfills(),
      resolve(),
      commonjs(),
      ascii(),
      terser()
    ],
    output: {
      extend: true,
      file: 'build/trace_skeleton_wasm.min.js',
      format: 'umd',
      name: 'TraceSkeleton',
    },
  },
];
