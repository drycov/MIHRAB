#!/usr/bin/env python3
"""Render the existing MIHRAB brand master into opaque PWA PNGs; stdlib only."""
import math
import re
import struct
import sys
import zlib
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "branding/mihrab-icon.svg"
NS = "{http://www.w3.org/2000/svg}"


def polygons(path):
    # Current brand master uses absolute M/L/C/Z only. Fail on new syntax
    # instead of silently producing a different logo.
    tokens = iter(re.findall(r"[A-Za-z]|[-+]?(?:\d*\.\d+|\d+)", path))
    points = []
    for cmd in tokens:
        if cmd in ("M", "L"):
            points.append((float(next(tokens)), float(next(tokens))))
        elif cmd == "C":
            a = points[-1]
            b, c, d = [(float(next(tokens)), float(next(tokens))) for _ in range(3)]
            for i in range(1, 33):
                t = i / 32
                u = 1 - t
                points.append(tuple(u**3*a[j]+3*u*u*t*b[j]+3*u*t*t*c[j]+t**3*d[j] for j in range(2)))
        elif cmd == "Z":
            if len(points) < 3:
                raise ValueError("Invalid brand path")
            yield points
            points = []
        else:
            raise ValueError("Unsupported brand path command: " + cmd)
    if points:
        raise ValueError("Unclosed brand path")


def rgb(value):
    if not re.fullmatch(r"#[0-9a-fA-F]{6}", value):
        raise ValueError("Expected opaque RGB brand color")
    return tuple(bytes.fromhex(value[1:]))


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)


def render(size, scale, output, shapes, background, foreground):
    # Supersampled scanline rasterization, even-odd for each closed path.
    # Scale=1 for maskable: original Android foreground stays inside the
    # central 80%-diameter safe circle. Standard icons use master scale 1.18.
    ss = 4
    n = size * ss
    mask = bytearray(n*n)
    for polygon in shapes:
        pts = [((54+(x-54)*scale)*n/108, (54+(y-54)*scale)*n/108) for x,y in polygon]
        edges = list(zip(pts, pts[1:]+pts[:1]))
        for y in range(max(0,math.floor(min(p[1] for p in pts))),min(n,math.ceil(max(p[1] for p in pts)))):
            sy=y+0.5
            hits=sorted(x1+(sy-y1)*(x2-x1)/(y2-y1) for (x1,y1),(x2,y2) in edges if min(y1,y2)<=sy<max(y1,y2))
            for lo,hi in zip(hits[::2],hits[1::2]):
                start=max(0,math.ceil(lo-.5))
                end=min(n,math.ceil(hi-.5))
                if end>start:
                    mask[y*n+start:y*n+end]=b"\x01"*(end-start)
    raw=bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            coverage=sum(sum(mask[(y*ss+dy)*n+x*ss:(y*ss+dy)*n+x*ss+ss]) for dy in range(ss))
            raw.extend((bg*(ss*ss-coverage)+fg*coverage+ss*ss//2)//(ss*ss) for bg,fg in zip(background,foreground))
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_bytes(b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,2,0,0,0))+chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b""))


def main():
    dest=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/"web"
    svg=ET.parse(SVG).getroot()
    if svg.attrib.get("viewBox")!="0 0 108 108":
        raise ValueError("Unexpected brand viewport")
    group=svg.find(NS+"g")
    if group.attrib.get("transform")!="translate(54 54) scale(1.18) translate(-54 -54)":
        raise ValueError("Unexpected brand transform")
    shapes=[poly for p in group.findall(NS+"path") for poly in polygons(p.attrib["d"])]
    bg=rgb(svg.find(NS+"rect").attrib["fill"])
    fg=rgb(group.attrib["fill"])
    for size in (192,512):
        render(size,1.18,dest/"icons"/f"Icon-{size}.png",shapes,bg,fg)
        render(size,1.0,dest/"icons"/f"Icon-maskable-{size}.png",shapes,bg,fg)
    render(32,1.18,dest/"favicon.png",shapes,bg,fg)
    print("Generated five MIHRAB brand icons in",dest)


if __name__=="__main__":
    main()
