"""Generate the new SelAction report figures as SVG, in the house style of
docs/selaction_*.svg (Arial, navy text, teal = sires, blue = dams)."""
import math, sys

OUT = sys.argv[1]
STYLE = """<defs><style>
text{font-family:Arial,Helvetica,sans-serif;fill:#14243b;font-size:14px}
.head{font-size:17px;font-weight:700}
.small{font-size:13px;fill:#476276}
.tiny{font-size:12px;fill:#476276}
.s{fill:#e5f0ed;stroke:#2d756b;stroke-width:1.5}
.d{fill:#e9eef5;stroke:#4f719b;stroke-width:1.5}
.cand{fill:#fff4dc;stroke:#b07a12;stroke-width:2}
.out{fill:#f7f8fa;stroke:#8294a5;stroke-width:1.4}
.line{stroke:#8294a5;stroke-width:1.6;fill:none}
.arrow{stroke:#647e90;stroke-width:2;fill:none;marker-end:url(#a)}
.axis{stroke:#647e90;stroke-width:1.3;fill:none}
.grid{stroke:#e3e8ee;stroke-width:1}
</style><marker id="a" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0L8 4L0 8Z" fill="#647e90"/></marker></defs>"""


def svg(w, h, label, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" role="img" aria-label="{label}">\n'
            f'  {STYLE}\n  <rect width="{w}" height="{h}" fill="white"/>\n{body}</svg>\n')


def sub(base, s):
    return f'{base}<tspan baseline-shift="sub" font-size="10">{s}</tspan>'


def phi(z):
    return math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi)


def sf(z):
    return 0.5 * math.erfc(z / math.sqrt(2))


def box(cls, x, y, w, h, lines):
    out = [f'  <rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="8"/>']
    for k, (c, t) in enumerate(lines):
        cl = f' class="{c}"' if c else ''
        out.append(f'  <text{cl} x="{x + 12}" y="{y + 22 + 18 * k}">{t}</text>')
    return '\n'.join(out) + '\n'


# 1. information sources around a candidate ---------------------------------
def sources():
    b = '  <text class="head" x="25" y="31">Information sources for one selection candidate</text>\n'
    b += box('d', 60, 55, 210, 62, [('', 'Dam'), ('small', 'EBV of the dam: source 2')])
    b += box('s', 330, 55, 210, 62, [('', 'Sire'), ('small', 'EBV of the sire: source 3')])
    b += box('d', 600, 55, 270, 62, [('', 'Other dams mated to the sire'),
                                     ('small', 'mean EBV of these dams: 44–63')])
    b += box('out', 60, 175, 210, 62, [('', 'Full sibs'), ('small', 'group mean: sources 4–23')])
    b += box('cand', 330, 175, 210, 62, [('', 'Candidate'), ('small', 'own performance: source 1')])
    b += box('out', 600, 175, 270, 62, [('', 'Paternal half sibs'), ('small', 'group mean: sources 24–43')])
    b += box('out', 330, 290, 210, 62, [('', 'Progeny of the candidate'), ('small', 'group mean: sources 64–83')])
    # mating lines between parents, a drop to a sibship bar, and drops to each offspring box
    b += '  <path class="line" d="M270 86H330M300 86V150M165 150H435M165 150V175M435 150V175"/>\n'
    b += '  <path class="line" d="M540 86H600M570 86V150M570 150H735M735 150V175"/>\n'
    b += '  <path class="line" d="M435 237V290"/>\n'
    b += '  <text class="tiny" x="577" y="144">mated</text><text class="tiny" x="307" y="144">mated</text>\n'
    b += ('  <text class="tiny" x="25" y="372">Full sibs share both parents; paternal half sibs share only the sire; up to 20 groups of each type. '
          'Choosing BLUP (input code 2)</text>\n'
          '  <text class="tiny" x="25" y="388">adds the dam EBV (2), the sire EBV (3) and, for each half-sib group, '
          'the mean EBV of its dams (44–63): this is how SelAction approximates BLUP.</text>\n')
    return svg(900, 402, 'Information sources available for a selection candidate', b)


# 2. truncation selection on a normal curve ---------------------------------
def truncation():
    p = 0.20
    lo, hi = 0.0, 5.0                      # solve t with bisection on the survival function
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if sf(mid) > p else (lo, mid)
    t = (lo + hi) / 2
    i = phi(t) / p
    k = i * (i - t)
    X0, X1, Y0, H = 60, 500, 250, 190      # plot box: x in [-3.5, 3.5]
    sx = lambda z: X0 + (z + 3.5) / 7 * (X1 - X0)
    sy = lambda f: Y0 - f / phi(0) * H
    zs = [-3.5 + 7 * n / 280 for n in range(281)]
    curve = 'M' + ' L'.join(f'{sx(z):.1f} {sy(phi(z)):.1f}' for z in zs)
    tail = [z for z in zs if z >= t]
    shade = (f'M{sx(t):.1f} {Y0} L' + ' L'.join(f'{sx(z):.1f} {sy(phi(z)):.1f}' for z in [t] + tail)
             + f' L{sx(3.5):.1f} {Y0} Z')
    b = '  <text class="head" x="25" y="31">Truncation selection: the best fraction p of candidates is kept</text>\n'
    b += f'  <path d="{shade}" fill="#e5f0ed" stroke="none"/>\n'
    b += f'  <path d="{curve}" stroke="#14243b" stroke-width="2" fill="none"/>\n'
    b += f'  <path class="axis" d="M{X0} {Y0}H{X1}"/>\n'
    for z in range(-3, 4):
        b += f'  <path class="axis" d="M{sx(z):.1f} {Y0}v5"/><text class="tiny" x="{sx(z) - 4:.1f}" y="{Y0 + 19}">{z}</text>\n'
    b += f'  <text class="small" x="{X0 + 150}" y="{Y0 + 40}">index value, in index standard deviations</text>\n'
    b += f'  <path d="M{sx(t):.1f} {Y0}V62" stroke="#b07a12" stroke-width="2" stroke-dasharray="5 4"/>\n'
    b += f'  <text x="{sx(t) + 8:.1f}" y="72">threshold t = {t:.2f}</text>\n'
    b += f'  <path d="M{sx(i):.1f} {Y0}V{Y0 - 40}" stroke="#2d756b" stroke-width="2.5"/>\n'
    b += f'  <path class="line" d="M{sx(i):.1f} {Y0 - 40}L{sx(2.35):.1f} {Y0 - 92}"/>\n'
    b += f'  <text x="{sx(2.35) + 4:.1f}" y="{Y0 - 104}">mean of the selected</text>\n'
    b += f'  <text x="{sx(2.35) + 4:.1f}" y="{Y0 - 86}">= i = {i:.2f}</text>\n'
    b += f'  <text class="small" x="{sx(2.35) + 4:.1f}" y="{Y0 - 62}">shaded: the selected p = {p:.0%}</text>\n'
    b += box('out', 650, 70, 285, 168, [
        ('', 'For p = 20%:'),
        ('small', f'threshold t = {t:.3f}'),
        ('small', f'intensity i = φ(t)/p = {i:.3f}'),
        ('small', f'k = i(i − t) = {k:.3f}'),
        ('small', f'variance among selected = 1 − k = {1 - k:.3f}'),
        ('small', 'The variance reduction k drives the'),
        ('small', 'Bulmer effect.')])
    return svg(960, 310, 'Truncation selection on a standard normal index', b)


# 3. Bulmer iteration: loop diagram plus the real test1 trajectory ------------
def bulmer(rounds_file):
    rows = [list(map(float, l.split()[1:])) for l in open(rounds_file) if l.startswith('RND')]
    rnd = [r[0] for r in rows]
    series = [('index variance', [r[1] for r in rows], '#2d756b'),
              ('total response', [r[5] for r in rows], '#4f719b'),
              ('accuracy', [r[3] for r in rows], '#b07a12')]
    b = '  <text class="head" x="25" y="31">Selection reduces variance, so SelAction iterates to equilibrium (Bulmer effect)</text>\n'
    b += box('out', 30, 60, 250, 52, [('', 'Index, accuracy, response'), ('tiny', 'selection_index')])
    b += box('out', 30, 145, 250, 52, [('', 'Truncation: intensity i, k'), ('tiny', 'i from rawl3 (family-adjusted), k from trunc')])
    b += box('out', 30, 230, 250, 68, [('', 'Covariance update'), ('tiny', 'family variance × (1 − k r²), one trait'),
                                       ('tiny', 'covariance_update')])
    b += '  <path class="arrow" d="M155 112V143"/><path class="arrow" d="M155 197V228"/>\n'
    b += '  <path class="arrow" d="M30 264H12V86H28"/>\n'
    b += '  <text class="tiny" x="40" y="322">repeated for exactly 25 rounds</text>\n'
    # chart, values relative to round 1
    X0, X1, Y0, Y1 = 370, 860, 290, 70
    lo, hi = 60, 100
    sx = lambda r: X0 + (r - 1) / 24 * (X1 - X0)
    sy = lambda v: Y0 - (v - lo) / (hi - lo) * (Y0 - Y1)
    for g in range(lo, hi + 1, 10):
        b += f'  <path class="grid" d="M{X0} {sy(g):.1f}H{X1}"/><text class="tiny" x="{X0 - 30}" y="{sy(g) + 4:.1f}">{g}%</text>\n'
    b += f'  <path class="axis" d="M{X0} {Y0}H{X1}"/>\n'
    for r in (1, 5, 10, 15, 20, 25):
        b += f'  <text class="tiny" x="{sx(r) - 5:.1f}" y="{Y0 + 18}">{r}</text>\n'
    b += f'  <text class="small" x="{X0 + 170}" y="{Y0 + 38}">round</text>\n'
    b += f'  <text class="small" x="{X0}" y="{Y1 - 12}">relative to round 1 (example test1: sire index; total response)</text>\n'
    for k, (name, vals, col) in enumerate(series):
        rel = [100 * v / vals[0] for v in vals]
        d = 'M' + ' L'.join(f'{sx(r):.1f} {sy(v):.1f}' for r, v in zip(rnd, rel))
        b += f'  <path d="{d}" stroke="{col}" stroke-width="2.2" fill="none"/>\n'
        b += (f'  <text class="tiny" x="{sx(25) - 205:.1f}" y="{sy(rel[-1]) - 7:.1f}" style="fill:{col}">'
              f'{name}: {vals[0]:.3g} → {vals[-1]:.3g} ({rel[-1]:.0f}%)</text>\n')
    return svg(900, 345, 'Bulmer effect iteration and convergence in example test1', b)


# 4. overlapping generations: one threshold across age classes --------------
def agethreshold():
    N = [1000, 500]
    m = [0.0, -1.2]                         # illustrative: class 2 lags one generation of gain
    x = 2.0
    X0, X1, Y0, H = 60, 600, 255, 175
    sx = lambda z: X0 + (z + 4.5) / 8 * (X1 - X0)
    peak = N[0] * phi(0)
    sy = lambda f: Y0 - f / peak * H
    zs = [-4.5 + 8 * n / 320 for n in range(321)]
    cols = [('#2d756b', '#cfe5df'), ('#4f719b', '#d6e0ee')]
    b = '  <text class="head" x="25" y="31">Overlapping generations: one threshold is applied to all age classes</text>\n'
    for c in range(2):
        f = lambda z: N[c] * phi(z - m[c])
        tail = [x] + [z for z in zs if z > x]
        b += (f'  <path d="M{sx(x):.1f} {Y0} L' + ' L'.join(f'{sx(z):.1f} {sy(f(z)):.1f}' for z in tail)
              + f' L{sx(3.5):.1f} {Y0} Z" fill="{cols[c][1]}" stroke="none"/>\n')
        b += (f'  <path d="M' + ' L'.join(f'{sx(z):.1f} {sy(f(z)):.1f}' for z in zs)
              + f'" stroke="{cols[c][0]}" stroke-width="2" fill="none"/>\n')
    b += f'  <path class="axis" d="M{X0} {Y0}H{X1}"/>\n'
    b += f'  <path d="M{sx(x):.1f} {Y0}V54" stroke="#b07a12" stroke-width="2" stroke-dasharray="5 4"/>\n'
    b += f'  <text text-anchor="end" x="{sx(x) - 8:.1f}" y="66">common threshold {sub("x", "s")}</text>\n'
    b += f'  <text class="small" text-anchor="end" x="{sx(-0.75):.1f}" y="{sy(N[0] * phi(0.75)) - 6:.1f}" style="fill:#2d756b">age class 1 (young)</text>\n'
    b += f'  <text class="small" text-anchor="end" x="{sx(m[1] - 0.95):.1f}" y="{sy(N[1] * phi(0.95)) - 6:.1f}" style="fill:#4f719b">age class 2 (older)</text>\n'
    b += f'  <text class="small" x="{X0 + 120}" y="{Y0 + 26}">index value (older classes sit lower: they lag behind genetic progress)</text>\n'
    n = [N[c] * sf(x - m[c]) for c in range(2)]
    b += box('out', 625, 80, 260, 160, [
        ('', 'Illustrative numbers'),
        ('small', f'class 1: {N[0]} candidates, mean 0'),
        ('small', f'   selected {N[0]} × P(Z > 2.0) = {n[0]:.1f}'),
        ('small', f'class 2: {N[1]} candidates, mean −1.2'),
        ('small', f'   selected {N[1]} × P(Z > 3.2) = {n[1]:.2f}'),
        ('small', f'{sub("x", "s")} is solved so that the total'),
        ('small', 'equals the number of sires wanted')])
    return svg(900, 300, 'Common truncation threshold across age classes', b)


figs = {'selaction_sources.svg': sources(), 'selaction_truncation.svg': truncation(),
        'selaction_bulmer.svg': bulmer(sys.argv[2]), 'selaction_agethreshold.svg': agethreshold()}
for name, text in figs.items():
    open(f'{OUT}/{name}', 'w').write(text)
    print('wrote', name)
