#!/usr/bin/env python3
"""Rain Dodge's 120x120 icon (AppIcon60x60@2x.png): night blue, three drops, a gold paddle. Stdlib only."""
import struct, sys, zlib

N = 120


def pixel(x, y):
    for cx, cy, r in ((34, 34, 11), (78, 22, 8), (62, 62, 13)):
        if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
            return (115, 190, 255)
    if 22 <= x < 98 and 92 <= y < 104:
        return (255, 204, 64)
    return (13, 18, 33)


def png(path):
    rows = b''.join(b'\0' + bytes(c for x in range(N) for c in pixel(x, y)) for y in range(N))
    chunk = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    data = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', N, N, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))
    with open(path, 'wb') as f:
        f.write(data)


if __name__ == '__main__':
    png(sys.argv[1])
