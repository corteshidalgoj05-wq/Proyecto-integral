#!/usr/bin/env python3
"""Genera data/curva_binaria_P4.pbm (P4) con una región negra bajo una curva suave."""

from __future__ import annotations

import math
from pathlib import Path

W, H = 640, 320


def f(x: int) -> int:
    """Altura discreta conocida: lóbulo senoidal, siempre < H."""
    t = x / (W - 1)
    return int(round(H * (0.12 + 0.78 * math.sin(math.pi * t) ** 2)))


def pack_row(bits: list[int]) -> bytes:
    out = bytearray()
    acc = 0
    n = 0
    for b in bits:
        acc = (acc << 1) | (1 if b else 0)
        n += 1
        if n == 8:
            out.append(acc)
            acc = 0
            n = 0
    if n:
        acc <<= 8 - n
        out.append(acc)
    return bytes(out)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    dest = root / "data" / "curva_binaria_P4.pbm"
    dest.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    heights = [f(x) for x in range(W)]
    for y in range(H):
        # y = 0 es arriba: negro si la fila está dentro de la altura desde abajo
        bits = []
        for x in range(W):
            from_bottom = H - 1 - y
            bits.append(1 if from_bottom < heights[x] else 0)
        rows.append(pack_row(bits))

    header = f"P4\n# region bajo curva senoidal\n{W} {H}\n".encode("ascii")
    dest.write_bytes(header + b"".join(rows))
    area = sum(heights)
    print(f"Escrito {dest}  {W}x{H}  area={area} px²")
    print("muestras:")
    for i in range(12):
        x = (i * (W - 1)) // 11
        print(f"  x = {x}  ->  f(x) = {heights[x]}")


if __name__ == "__main__":
    main()
