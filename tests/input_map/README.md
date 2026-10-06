# Input map: every question SelAction asks, and which test reaches it

SelAction reads its input as a sequence of answers on standard input
(the `.in` files). This map lists **every input statement** in
`fortran/*.f90`, **when** it is asked, and **which test input reaches
it**. It is used for two things:

- **test-hardening T2** (steps 4b/4c): the questions no test reaches yet
  say which new test inputs are needed;
- **the I/O plan, Phase 1** (step 5): the translator from YAML scenarios
  to the program's answers must produce exactly this sequence.

`reads.csv` is generated: `tests/tools/read_map.sh` builds the coverage
build, runs each fixture and error case on its own, and records which
input lines each one executed. This README is written by hand from it and
from the code. **After adding fixtures, rerun the script and update the
"Covered by" columns.** Line numbers refer to `fortran/` at the commit
that last updated this file.

**Status on 2026-10-06 (7 fixtures, 6 error cases): 124 of 162 input
statements are reached; 38 are not.** All 38 are covered by the new test
inputs planned for steps 4b/4c (last section).

Notation: *sel1s / sel2s / sel3s* are the 1-, 2- and 3-stage routines in
`seldiscrete.f90`; they ask the same questions, so they share a table
with one line-number column each. "All discrete" = `test1`, `blup1`,
`advgrp` (1-stage), `test2s` (2-stage), `test3s` (3-stage). "Re-asks"
means the program prints a message and asks again (with `goto`) on an
invalid answer; in batch mode (I/O Phase 2) these become errors.

## 1. Start (`selaction.f90`)

| Question | Asked when | Answer | Line | Covered by |
|---|---|---|---|---|
| 1, 2 or 3 stage selection, or overlapping generations? | always | `1`/`2`/`3`/`o` (re-asks) | `selaction.f90:22` | every fixture and error case |

## 2. Discrete generations (`seldiscrete.f90`)

Order of the questions in all three routines: file name → number of
traits → separate indices for sires and dams → trait information
(section 4) → common environment → variance, h², c² per trait → groups →
information sources (section 4) → correlations → population and
proportions selected → checks and corrections → c² in the progeny test.

| Question | Asked when | Answer (checks) | sel1s | sel2s | sel3s | Covered by |
|---|---|---|---|---|---|---|
| file name | always | ≤ 8 characters, no blanks (`read_name`) | 16 | 1163 | 2800 | all discrete + error cases |
| number of traits | always | integer | 32 | 1179 | 2816 | all discrete |
| different indices / sources for sires and dams? | always | `y`/`n` | 90 | 1245 | 2891 | all discrete (all answer `n`) |
| use common environmental effects? | always | `y`/`n` (re-asks) | 121 | 1289 | 2950 | all discrete (all `y`) |
| phenotypic variance, per trait | always | real | 139 | 1307 | 2968 | all discrete |
| heritability h², per trait | always | 0 < h² < 1 (re-asks) | 144 | 1312 | 2973 | all discrete |
| c², per trait | common environment `y` | 0 ≤ c² < 1, h² + c² < 1 (re-asks) | 161 | 1329 | 2990 | all discrete |
| use full-sib groups? | always | `y`/`n` | 184 | 1352 | 3013 | all discrete |
| number of full-sib groups | FS `y` | integer, "max=20" (not checked) | 189 | **1357** | 3018 | `test1`, `test3s`; **2-stage: none** |
| animals per full-sib group, per group | FS `y` | real | 194 | **1362** | 3023 | `test1`, `test3s`; **2-stage: none** |
| use half-sib groups? | always | `y`/`n` | 200 | 1368 | 3029 | all discrete |
| number of half-sib groups | HS `y` | integer, "max=20" (not checked) | 205 | **1373** | 3034 | 1-stage, `test3s`; **2-stage: none** |
| dams per half-sib group, per group | HS `y` | real | 210 | **1378** | 3039 | 1-stage, `test3s`; **2-stage: none** |
| animals per half-sib group, per group | HS `y` | real | 214 | **1382** | 3043 | 1-stage, `test3s`; **2-stage: none** |
| use progeny groups? | always | `y`/`n` | 220 | 1388 | 3049 | all discrete |
| number of progeny groups | progeny `y` | integer, "max=20" (not checked) | 225 | **1393** | **3054** | `advgrp`; **2- and 3-stage: none** |
| dams per progeny group, per group | progeny `y` | real | 231 | **1399** | **3060** | `advgrp`; **2- and 3-stage: none** |
| animals per progeny group, per group | progeny `y` | real | 237 | **1405** | **3066** | `advgrp`; **2- and 3-stage: none** |
| phenotypic correlation, per trait pair | always | −1 < r < 1 (re-asks the pair) | 310 | 1498 | 3181 | all discrete |
| genetic correlation, per trait pair | always | −1 < r < 1 (re-asks the pair) | 319 | 1507 | 3190 | all discrete |
| common environmental correlation, per pair | common environment `y` | −1 < r < 1 (re-asks the pair) | 329 | 1517 | 3200 | all discrete |
| number of selected sires | always | integer | 361 | 1549 | 3232 | all discrete |
| number of selected dams | always | integer | 365 | 1554 | 3236 | all discrete |
| male candidates per dam | always | real | 369 | 1559 | 3240 | all discrete |
| female candidates per dam | always | real | 373 | 1563 | 3244 | all discrete |
| proportion selected sires (stage 1) | always | real | 377 | 1568 | 3248 | all discrete |
| proportion selected sires, stage 2 | 2- and 3-stage | real | — | 1573 | 3252 | `test2s`, `test3s` |
| proportion selected sires, stage 3 | 3-stage | real | — | — | 3256 | `test3s` |
| proportion selected dams (stage 1) | always | real | 381 | 1578 | 3260 | all discrete |
| proportion selected dams, stage 2 | 2- and 3-stage | real | — | 1583 | 3264 | `test2s`, `test3s` |
| proportion selected dams, stage 3 | 3-stage | real | — | — | 3268 | `test3s` |
| **correction:** change sire or dam sources? | separate indices `y`, a trait has no phenotypic source in either sex and no genetic correlation with a trait that has one, and the answer to the warning (section 4, `note_pheninfo`) is `i` | `s`/`d`; then the sources for that trait are asked again (section 4) and the check repeats | **480** | **1680** | **3365** | **none** |
| **correction:** new genetic correlation (no-source trait listed first) | as above but answer `c`, separate indices `y`; asked for the **first** trait with phenotypic sources, when it comes after the no-source trait | real | **507** | **1715** | **3408** | **none** |
| **correction:** new genetic correlation (no-source trait listed later) | as above, when the first trait with sources comes before the no-source trait | real | **516** | **1724** | **3417** | **none** |
| **correction:** new genetic correlation, same index (first trait after) | separate indices `n`, a trait without phenotypic source and no genetic correlation with one that has, answer `c` | real | **565** | **1776** | **3475** | **none** |
| **correction:** new genetic correlation, same index (first trait before) | as above | real | **574** | **1785** | **3484** | **none** |
| c² in the progeny test, per trait | progeny groups `y` **and** common environment `y` | 0 < c² < 1 (re-asks; note: 0 is rejected) | 617 | **1838** | **3543** | `advgrp`; **2- and 3-stage: none** |

With separate indices `n` and answer `i` to the warning, the sources
for the trait are asked again (section 4) without a sire/dam question.

## 3. Overlapping generations (`selovlp.f90`, routine `ovlp`)

Order: file name → number of traits → population → age classes →
truncation or fixed numbers → candidates (and selected) per age class →
trait information (section 4) → common environment → variance, h², c² →
groups → information sources per age class (section 4) → correlations →
c² in the progeny test. Unlike discrete generations, there is no
"separate indices" question, and the **half-sib question is skipped when
there are as many sires as dams**.

| Question | Asked when | Answer (checks) | Line | Covered by |
|---|---|---|---|---|
| file name | always | ≤ 8 characters, no blanks (`read_name`) | 23 | `ovlp2`, `ovlpgrp`, `longovlp`, `ovlptrt` |
| number of traits | always | integer | 39 | `ovlp2`, `ovlpgrp`, `ovlptrt` |
| total selected sires | always | integer | 47 | same |
| total selected dams | always | integer | 51 | same |
| male candidates per dam | always | real | 55 | same |
| female candidates per dam | always | real | 59 | same |
| number of age classes per sex | always | integer | 66 | same |
| truncation selection, or fixed number per age class? | always | `t`/`n` | 88 | same (all answer `t`) |
| male candidates in age class, per class except the first (set from candidates per dam) | always | real | 106 | same |
| female candidates in age class, per class except the first | always | real | 112 | same |
| selected sires in age class, per class | fixed numbers (`n`) | real | **132** | **none** |
| selected dams in age class, per class | fixed numbers (`n`) | real | **139** | **none** |
| use common environmental effects? | always | `y`/`n` | 232 | `ovlp2` (`n`), `ovlpgrp` (`y`) |
| phenotypic variance, per trait | always | real | 250 | `ovlp2`, `ovlpgrp` |
| heritability h², per trait | always | 0 < h² < 1 (re-asks) | 255 | `ovlp2`, `ovlpgrp` |
| c², per trait | common environment `y` | as discrete | 272 | `ovlpgrp` |
| use full-sib groups? | always | `y`/`n` | 295 | `ovlp2`, `ovlpgrp` |
| number of full-sib groups / animals per group | FS `y` | integer / real | 300, 305 | `ovlpgrp` |
| use half-sib groups? | **only if sires < dams** | `y`/`n` | 312 | `ovlp2`, `ovlpgrp` |
| number of half-sib groups / dams / animals per group | HS `y` | integer / real / real | 317, 322, 326 | `ovlpgrp` |
| use progeny groups? | always | `y`/`n` | 336 | `ovlp2`, `ovlpgrp` |
| number of progeny groups / dams / animals per group | progeny `y` | integer / real / real | 341, 347, 352 | `ovlpgrp` |
| next sire age class with more information (or −1) | truncation (`t`); after the sources for the first sire class | integer or −1 | 398 | `ovlp2`, `ovlpgrp` |
| next dam age class with more information (or −1) | truncation (`t`); after the sources for the first dam class | integer or −1 | 464 | `ovlp2`, `ovlpgrp` |
| phenotypic / genetic / common env. correlation, per pair | always (common env. only if `y`) | −1 < r < 1 (re-asks the pair) | 524, 533, 543 | `ovlp2`, `ovlpgrp` (543: `ovlpgrp`) |
| c² in the progeny test, per trait | progeny `y` and common environment `y` | 0 < c² < 1 (re-asks) | 615 | `ovlpgrp` |

With fixed numbers (`n`), the sources are asked for **every** age class
that has animals selected, instead of "next age class" questions.

## 4. Shared routines (`selroutines.f90`)

| Routine | Question | Asked when | Answer (checks) | Line | Covered by |
|---|---|---|---|---|---|
| `read_name` | (reads the line for a file or trait name) | every name | text | 23 | every fixture and error case |
| `traitinfo` | trait name, per trait | discrete, always | ≤ 8 characters, no blanks, unique (`read_name`) | 1191 | all discrete + `longtrt`, `spacetrt`, `duptrt` |
| `traitinfo` | use: index `i` / goal `h` / both `b` / not now `n` | discrete, **more than one trait** (one trait is set to `b`) | `i`/`h`/`b`/`n` (re-asks) | 1204 | all discrete + `duptrt` |
| `traitinfo` | economic value, goal-only trait | use `h` | ≠ 0 (re-asks) | **1217** | **none** |
| `traitinfo` | economic value, index-and-goal trait | use `b` | ≠ 0 (re-asks) | 1229 | all discrete + `duptrt` |
| `traitinfoovlp` | trait name, per trait | overlapping | as above | 1264 | `ovlp2`, `ovlpgrp`, `ovlptrt` |
| `traitinfoovlp` | use `i`/`h`/`b`/`n` | overlapping, more than one trait | as above | 1277 | `ovlp2`, `ovlpgrp` |
| `traitinfoovlp` | economic value, goal-only trait | use `h` | ≠ 0 | **1290** | **none** |
| `traitinfoovlp` | economic value, index-and-goal trait | use `b` | ≠ 0 | 1302 | `ovlp2`, `ovlpgrp` |
| `traitinfo2` | dams: use `i`/`h`/`b`/`n` | separate indices `y` | as above | **1344** | **none** |
| `traitinfo3` | sires, stage 2: add to index? `i`/`n` | 2- or 3-stage, more than one trait, for each trait **not** in the stage-1 index (use `n` or `h`) | `i`/`n` | **1403** | **none** |
| `traitinfo4` | dams, stage 2: as above | separate indices `y`, 2- or 3-stage, each dam trait not in the stage-1 dam index | `i`/`n` | **1448** | **none** |
| `traitinfo5` | sires, stage 3: as above | 3-stage, trait not in the stage-2 index | `i`/`n` | **1501** | **none** |
| `traitinfo6` | dams, stage 3: as above | separate indices `y`, 3-stage, each dam trait not in the stage-2 dam index | `i`/`n` | **1546** | **none** |
| `info_sources` | information sources for a trait, first and following codes | each index trait (sires; dams too if separate indices) | codes: 1 own performance, 2 BLUP, 3+n full-sib group n, 23+n half-sib group n, 63+n progeny group n; −1 ends | 478, 481 | all discrete |
| `info_sourcesovlp` | as above, per age class | overlapping | as above | 642, 645 | `ovlp2`, `ovlpgrp` |
| `info_sources2` | sources added in stage 2 | 2- and 3-stage, if any remain | codes, −1 ends | 860, 870 | `test2s`, `test3s` |
| `info_sources3` | sources added in stage 3 | 3-stage, if any remain | codes, −1 ends | 1067, 1077 | `test3s` |
| `note_pheninfo` | warning: trait without phenotypic sources and without genetic correlation to one that has them: edit sources `i` or correlations `c`? | the checks in section 2 find such a trait (discrete only) | `i`/`c` (re-asks) | **359** | **none** |

## Not reached yet → planned test inputs (steps 4b/4c)

| Not reached | Lines | Planned test input |
|---|---|---|
| goal-only trait (`h`): economic value | 1217; 1290 | `goalonly` (discrete); **add a goal-only trait to `ovlpfix`** (overlapping) |
| dams' trait use and stage-2/3 use with separate indices | 1344, 1448, 1546 | `sxd1`, `sxd2`, `sxd3` |
| sires' stage-2/3 trait use (trait added to the index in a later stage) | 1403, 1501 | **`sxd2`/`sxd3` and `prog2s`/`prog3s` must include a trait not in the stage-1 (or stage-2) index** |
| full-sib and half-sib groups in 2-stage | 1357–1382 | **`prog2s` must use full-sib and half-sib groups as well as progeny** |
| progeny groups in 2- and 3-stage, with progeny c² | 1393–1405, 1838; 3054–3066, 3543 | `prog2s`, `prog3s` (common environment `y`) |
| fixed numbers selected per age class | selovlp 132, 139 | `ovlpfix` |
| the no-phenotypic-source warning and its corrections | 359; 480, 507, 516, 565, 574 (and the 2-/3-stage copies 1680–1785, 3365–3484) | **`nophen1`, `nophen2`, `nophen3`** (one per stage, replacing the single `nophen`); each needs two runs' worth of paths, see below |

**The correction paths need more than one `nophen` input.** Each stage
has its own copy of the code, and the five correction questions sit on
different paths: separate indices `y` with answer `i` (then `s`/`d`),
separate indices `y` with answer `c`, and separate indices `n` with
answer `c`; and "trait with sources comes after / before the no-source
trait". One input per stage can cover the separate-indices `y` paths with
two no-source traits (trait 1 answered `i`, trait 3 answered `c`, with a
trait that has sources in between), and the separate-indices `n` path
needs a second input. Plan: **`nophen1`, `nophen2`, `nophen3`** (separate
indices `y`) and **`nophen1n`, `nophen2n`, `nophen3n`** (separate indices
`n`). Six small inputs, built from existing fixtures.

## Findings from the walk (no code changed)

1. **Progeny-test c² cannot be 0.** With common environment `y` and
   progeny groups, `ccprog ≤ 0` is rejected ("must be higher than 0"),
   while the ordinary c² accepts 0 (`cc < 0` is rejected). A user who
   wants no common environment in the progeny test can't say so. Same in
   all four routines. Worth confirming with Jack/Piter whether 0 should
   be allowed; it is an input check, not an equation. **Raised as
   Question 8** in `correspondence/2026-10-bijma-dekkers-addendum/`.
2. **"max=20" groups is not checked** (already a known issue in the
   README); the map confirms it for all four routines.
3. **The genetic-correlation correction only offers one pair.** With
   answer `c`, the program asks for a new correlation with the **first**
   trait that has phenotypic sources, and the check is not repeated for
   that trait afterwards, so entering 0 again leaves the problem in
   place. Recorded for the I/O plan's validator, which will check this
   before running.
4. **Overlapping generations skip the half-sib question when sires =
   dams; discrete generations ask it and later drop half-sib sources
   with a note (`note_matrat`).** The translator (I/O Phase 1) must
   reproduce the difference exactly. Raised as an **addition to
   Question 6** in `correspondence/2026-10-bijma-dekkers-addendum/`.
5. **One trait skips the "use" question** (set to `b`), and in 2- and
   3-stage selection skips the stage-2/3 trait questions. `onetrait`
   should therefore be run in 2-stage as well (`onetrait2`).
