#!/usr/bin/env python3
# Adds LC_LOAD_DYLIB to a thin arm64 Mach-O, using the free space after the load commands.
import struct, sys
path, dylib = sys.argv[1], sys.argv[2]
d = bytearray(open(path,'rb').read())
assert struct.unpack_from('<I',d,0)[0]==0xfeedfacf, 'not thin 64-bit Mach-O'
ncmds, sizeofcmds = struct.unpack_from('<II',d,16)
off=32; first=None
for _ in range(ncmds):
    cmd,sz=struct.unpack_from('<II',d,off)
    if cmd==0xc and dylib.encode() in d[off+24:off+sz]: print('already injected'); sys.exit(0)
    if cmd==0x19:
        n=struct.unpack_from('<I',d,off+64)[0]; so=off+72
        for _ in range(n):
            fo=struct.unpack_from('<I',d,so+48)[0]
            if fo and (first is None or fo<first): first=fo
            so+=80
    off+=sz
name=dylib.encode()+b'\0'; size=(24+len(name)+7)&~7
end=32+sizeofcmds
assert end+size<=first, 'no room in header'
d[end:end+size]=struct.pack('<IIIIII',0xc,size,24,2,0x10000,0x10000)+name.ljust(size-24,b'\0')
struct.pack_into('<II',d,16,ncmds+1,sizeofcmds+size)
open(path,'wb').write(d); print('injected',dylib)
