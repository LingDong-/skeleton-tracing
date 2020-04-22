# traceskeleton.swfit

Swift version. Tested with Swift 4 and 5 on macOS 10.14.


## Usage

First compile

```
swiftc -Ounchecked -o trace_skeleton trace_skeleton.swift
```

Then run

```
./trace_skeleton file:/Users/full/path/to/image.png > out.svg
```

- `-O` or `-Ounchecked` should be passed to the compiler to gain a ~200x speedup.
- Fullpath is necessary prefixed with `file:`


**Developed at [Frank-Ratchye STUDIO for Creative Inquiry](https://studioforcreativeinquiry.org) at Carnegie Mellon University.**