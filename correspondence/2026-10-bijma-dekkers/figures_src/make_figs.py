"""Figures for the briefing to Peter Bijma and Jack Dekkers, in the house style
of docs/selaction_*.svg (Arial, navy text, teal = sires, blue = dams).

    python3 make_figs.py ..
    cd .. && for f in fig_*.svg; do rsvg-convert -f pdf -o ${f%.svg}.pdf $f; done
"""
import sys

OUT = sys.argv[1]
STYLE = """<defs><style>
text{font-family:Arial,Helvetica,sans-serif;fill:#14243b;font-size:14px}
.head{font-size:17px;font-weight:700}
.small{font-size:13px;fill:#476276}
.tiny{font-size:12px;fill:#476276}
.s{fill:#e5f0ed;stroke:#2d756b;stroke-width:1.5}
.d{fill:#e9eef5;stroke:#4f719b;stroke-width:1.5}
.sdot{fill:#2d756b}
.ddot{fill:#4f719b}
.pdot{fill:#b07a12}
.out{fill:#f7f8fa;stroke:#8294a5;stroke-width:1.4}
.line{stroke:#8294a5;stroke-width:1.6;fill:none}
.pline{stroke:#b07a12;stroke-width:2;fill:none;stroke-dasharray:6 4}
.axis{stroke:#647e90;stroke-width:1.3;fill:none}
.grid{stroke:#e3e8ee;stroke-width:1}
.arrow{stroke:#647e90;stroke-width:2;fill:none;marker-end:url(#a)}
</style><marker id="a" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0L8 4L0 8Z" fill="#647e90"/></marker></defs>"""


def svg(w, h, label, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" role="img" aria-label="{label}">\n'
            f'  {STYLE}\n  <rect width="{w}" height="{h}" fill="white"/>\n{body}</svg>\n')


def sub(base, s):
    return f'{base}<tspan baseline-shift="sub" font-size="10">{s}</tspan>'


# 1. genetic lag of older age classes ------------------------------------------
def lag(dHs, dHd):
    """dHs, dHd: annual path responses of sires and dams (unhalved), economic units."""
    dG = 0.5 * (dHs + dHd)
    X0, X1, Y0, Y1 = 110, 560, 70, 330          # plot box
    ymin, ymax = -2.2 * max(dHs, dHd), 10.0

    def X(c):                                    # age class 1..3 -> x
        return X0 + (c - 0.6) / 2.8 * (X1 - X0)

    def Y(v):
        return Y1 - (v - ymin) / (ymax - ymin) * (Y1 - Y0)
    b = '  <text class="head" x="25" y="31">Mean of the candidates in each age class, relative to the youngest class</text>\n'
    for v in range(0, int(ymin) - 1, -20):
        b += f'  <path class="grid" d="M{X0} {Y(v):.1f}H{X1}"/><text class="tiny" x="{X0 - 10}" y="{Y(v) + 4:.1f}" text-anchor="end">{v}</text>\n'
    b += f'  <path class="axis" d="M{X0} {Y0}V{Y1}H{X1}"/>\n'
    for c in (1, 2, 3):
        b += f'  <text class="small" x="{X(c):.1f}" y="{Y1 + 20}" text-anchor="middle">age class {c}</text>\n'
    b += f'  <text class="small" x="{(X0 + X1) / 2:.1f}" y="{Y1 + 42}" text-anchor="middle">(born 0, 1, 2 cohort intervals before the youngest)</text>\n'
    b += (f'  <text class="small" transform="translate(40 {(Y0 + Y1) / 2:.0f}) rotate(-90)" text-anchor="middle">'
          'mean index / breeding goal (economic units)</text>\n')
    # population trend line
    b += f'  <path class="pline" d="M{X(1):.1f} {Y(0):.1f}L{X(3):.1f} {Y(-2 * dG):.1f}"/>\n'
    for c in (1, 2, 3):
        o = -(c - 1)
        b += f'  <circle class="sdot" cx="{X(c) - 14:.1f}" cy="{Y(o * dHs):.1f}" r="6"/>\n'
        b += f'  <circle class="ddot" cx="{X(c) + 14:.1f}" cy="{Y(o * dHd):.1f}" r="6"/>\n'
        b += f'  <circle class="pdot" cx="{X(c):.1f}" cy="{Y(o * dG):.1f}" r="5"/>\n'
    # legend
    lx, ly = 600, 90
    b += f'  <circle class="sdot" cx="{lx}" cy="{ly}" r="6"/><text x="{lx + 14}" y="{ly + 5}">sire classes, as coded</text>\n'
    b += f'  <text class="tiny" x="{lx + 14}" y="{ly + 22}">sire-path annual response = {dHs:.1f} per class</text>\n'
    b += f'  <circle class="ddot" cx="{lx}" cy="{ly + 50}" r="6"/><text x="{lx + 14}" y="{ly + 55}">dam classes, as coded</text>\n'
    b += f'  <text class="tiny" x="{lx + 14}" y="{ly + 72}">dam-path annual response = {dHd:.1f} per class</text>\n'
    b += f'  <circle class="pdot" cx="{lx}" cy="{ly + 100}" r="5"/><text x="{lx + 14}" y="{ly + 105}">population trend (both sexes)</text>\n'
    b += f'  <text class="tiny" x="{lx + 14}" y="{ly + 122}">ΔG per year = ½(ΔH_s + ΔH_d) = {dG:.1f}</text>\n'
    b += (f'  <text class="tiny" x="{lx}" y="{ly + 165}">Numbers: the ovlpgrp regression example.</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 182}">Candidates of both sexes born in the same</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 199}">year descend from the same parents, so</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 216}">their expected means should coincide.</text>\n')
    return svg(920, 400, 'Genetic lag of older age classes: as coded per sex path, and the population trend', b)


# 2. generation interval ----------------------------------------------------------
def interval():
    b = '  <text class="head" x="25" y="31">Generation interval from the selected numbers (dams of the ovlpgrp example)</text>\n'
    n = [194.504, 5.496]
    w = [x / sum(n) for x in n]
    X0, Y1, H = 80, 250, 170
    for k, (nk, wk) in enumerate(zip(n, w)):
        x = X0 + 30 + k * 150
        h = wk * H
        b += f'  <rect class="d" x="{x}" y="{Y1 - h:.1f}" width="90" height="{h:.1f}"/>\n'
        b += f'  <text class="small" x="{x + 45}" y="{Y1 + 20}" text-anchor="middle">age class {k + 1}</text>\n'
        b += f'  <text x="{x + 45}" y="{Y1 - h - 8:.1f}" text-anchor="middle">n = {nk:.1f}, w = {wk:.4f}</text>\n'
    b += f'  <path class="axis" d="M{X0} {Y1 - H - 20}V{Y1}H{X0 + 330}"/>\n'
    b += box('out', 450, 70, 440, 78, [
        ('', 'Intended (and now computed):'),
        ('small', f'L_d = Σ c·w_c = 1×{w[0]:.4f} + 2×{w[1]:.4f} = {w[0] + 2 * w[1]:.4f}'),
        ('small', 'same for sires (all from class 1: L_s = 1); L = (L_s + L_d)/2 = 1.014')])
    b += box('out', 450, 165, 440, 98, [
        ('', 'Original code (assignment instead of sum):'),
        ('small', 'L_d ← (value left by trunc_delta) + c*·w_c*  for the last active class c*'),
        ('small', '   = 1.0275 + 2×0.0275 = 1.083 on these numbers: class 2 counted twice'),
        ('small', 'specified-count mode: trunc_delta never runs, L_d ← c*·w_c* only')])
    return svg(920, 290, 'Generation interval: intended computation versus the original code', b)


def box(cls, x, y, w, h, lines):
    out = [f'  <rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="8"/>']
    for k, (c, t) in enumerate(lines):
        cl = f' class="{c}"' if c else ''
        out.append(f'  <text{cl} x="{x + 12}" y="{y + 22 + 18 * k}">{t}</text>')
    return '\n'.join(out) + '\n'


# 3. rate of inbreeding vs number of sires (Poissoncorr) ---------------------------
def deltaf():
    """test1-based grid, 50 dams, 20 female candidates per dam (p_f = 0.05)."""
    m = [3, 5, 10, 19, 20, 25]
    base = [10.183, 8.217, 6.134, 4.590, 4.682, 3.972]
    var = [11.868, 9.514, 6.719, 4.624, 4.682, 3.972]
    X0, X1, Y0, Y1 = 90, 560, 60, 300
    ymin, ymax = 3.0, 12.5

    def X(v):
        return X0 + (v - 0) / 27 * (X1 - X0)

    def Y(v):
        return Y1 - (v - ymin) / (ymax - ymin) * (Y1 - Y0)
    b = '  <text class="head" x="25" y="31">Predicted rate of inbreeding against the number of sires</text>\n'
    for v in range(4, 13, 2):
        b += f'  <path class="grid" d="M{X0} {Y(v):.1f}H{X1}"/><text class="tiny" x="{X0 - 8}" y="{Y(v) + 4:.1f}" text-anchor="end">{v}%</text>\n'
    for v in (3, 5, 10, 15, 19, 20, 25):
        b += f'  <text class="tiny" x="{X(v):.1f}" y="{Y1 + 18}" text-anchor="middle">{v}</text>\n'
    b += f'  <path class="axis" d="M{X0} {Y0 - 10}V{Y1}H{X1}"/>\n'
    b += f'  <text class="small" x="{(X0 + X1) / 2:.0f}" y="{Y1 + 40}" text-anchor="middle">number of sires M_s (50 dams)</text>\n'
    b += f'  <path class="grid" d="M{X(19.5):.1f} {Y0 - 10}V{Y1}" style="stroke:#c9a14a;stroke-dasharray:4 3"/>\n'
    b += f'  <text class="tiny" x="{X(19.5) + 6:.1f}" y="{Y0 + 2}">M_s &lt; 20 branch switches off</text>\n'
    def path(xs, ys, cls):
        return '  <path class="' + cls + '" d="M' + ' L'.join(f'{X(a):.1f} {Y(c):.1f}' for a, c in zip(xs, ys)) + '"/>\n'
    b += path(m[:4], var[:4], 'pline')
    b += path(m[:4], base[:4], 'line').replace('class="line"', 'class="line" style="stroke:#2d756b;stroke-width:2"')
    b += path(m[4:], base[4:], 'line').replace('class="line"', 'class="line" style="stroke:#2d756b;stroke-width:2"')
    for a, c in zip(m, base):
        b += f'  <circle class="sdot" cx="{X(a):.1f}" cy="{Y(c):.1f}" r="5"/>\n'
    for a, c in zip(m[:4], var[:4]):
        b += f'  <circle class="pdot" cx="{X(a):.1f}" cy="{Y(c):.1f}" r="5"/>\n'
    lx, ly = 600, 90
    b += f'  <circle class="sdot" cx="{lx}" cy="{ly}" r="6"/><text x="{lx + 14}" y="{ly + 5}">as coded: female fractions use 1/M_s</text>\n'
    b += f'  <circle class="pdot" cx="{lx}" cy="{ly + 34}" r="6"/><text x="{lx + 14}" y="{ly + 39}">alternative: female fractions use 1/M_d</text>\n'
    b += (f'  <text class="tiny" x="{lx}" y="{ly + 80}">Female selected fraction p_f = 0.05 is below 1/M_s</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 97}">for M_s &lt; 20, so the choice matters here. With</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 114}">p_f = 0.2 (as in the test fixtures) both give the</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 131}">same answer. Note the rise from 19 to 20 sires,</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 148}">where both the adjustment and the extra β terms</text>\n'
          f'  <text class="tiny" x="{lx}" y="{ly + 165}">of hyper_correct switch at once.</text>\n')
    return svg(920, 360, 'Predicted rate of inbreeding against number of sires, as coded and with the alternative', b)


if __name__ == '__main__':
    figs = {'fig_agelag': lag(2 * 20.961, 2 * 8.665), 'fig_interval': interval(), 'fig_deltaf': deltaf()}
    for name, s in figs.items():
        with open(f'{OUT}/{name}.svg', 'w') as f:
            f.write(s)
