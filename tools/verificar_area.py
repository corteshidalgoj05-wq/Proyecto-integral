"""Verifica área y f(x) leyendo el P4 (misma semántica que Haskell/Prolog)."""
from pathlib import Path

def parse_p4(data: bytes):
    if not data.startswith(b"P4"):
        raise ValueError("no P4")
    i = 2
    def skip():
        nonlocal i
        while i < len(data):
            if data[i:i+1] == b"#":
                nl = data.find(b"\n", i)
                i = len(data) if nl < 0 else nl + 1
            elif data[i] in (9, 10, 13, 32):
                i += 1
            else:
                return
    def read_int():
        nonlocal i
        skip()
        j = i
        while i < len(data) and 48 <= data[i] <= 57:
            i += 1
        return int(data[j:i])
    w = read_int()
    h = read_int()
    if i < len(data) and data[i] in (9, 10, 13, 32, 35):
        if data[i] == 35:
            skip()
        else:
            i += 1
    raster = data[i:]
    bpr = (w + 7) // 8
    return w, h, bpr, raster

def black(w, h, bpr, raster, x, y):
    if not (0 <= x < w and 0 <= y < h):
        return False
    byte = raster[y * bpr + x // 8]
    bit = 7 - (x % 8)
    return (byte & (1 << bit)) != 0

def f(w, h, bpr, raster, x):
    n = 0
    for y in range(h - 1, -1, -1):
        if black(w, h, bpr, raster, x, y):
            n += 1
        else:
            break
    return n

p = Path(__file__).resolve().parents[1] / "data" / "curva_binaria_P4.pbm"
w, h, bpr, raster = parse_p4(p.read_bytes())
M = [f(w, h, bpr, raster, x) for x in range(w)]
print(f"{w}x{h} area={sum(M)}")
for i in range(12):
    x = (i * (w - 1)) // 11
    print(f"x = {x} -> f(x) = {M[x]}")
