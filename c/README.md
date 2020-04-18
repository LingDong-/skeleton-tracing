```
####################################################################
# trace_skeleton.c
# Lingdong Huang 2020
####################################################################

Dependencies:
    X11, libpng

Compile:
    gcc trace_skeleton.c -lX11 -lpng -lm -lpthread -std=c99

Additional flags for macOS:
    -I /opt/X11/include -L/opt/X11/lib -lX11 

Usage:
./a.out path/to/image.png > output.txt

See PARAMS section in code for more settings.


Developed at Frank-Ratchye STUDIO for Creative Inquiry at Carnegie 
Mellon University.
```


