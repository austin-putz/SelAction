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

**Status on 2026-10-09, after step 4b (27 fixtures, 8 error cases): 159
of 162 input statements are reached.** The 3 not reached are in
overlapping generations (fixed numbers per age class, and a goal-only
trait); the step-4c inputs cover them (last section). Before step 4b, 124
were reached.

Notation: *sel1s / sel2s / sel3s* are the 1-, 2- and 3-stage routines in
`seldiscrete.f90`; they ask the same questions, so they share a table
with one line-number column each. "All discrete" = every discrete
fixture: 1-stage `test1`, `blup1`, `advgrp`, `noce1`, `goalonly`,
`onetrait`, `fivetr`, `multigrp`, `matrat1`, `sires19`, `sires20`,
`sxd1`, `nophen1`, `nophen1n`; 2-stage `test2s`, `sxd2`, `prog2s`,
`onetrt2s`, `nophen2`, `nophen2n`; 3-stage `test3s`, `sxd3`, `prog3s`,
`nophen3`, `nophen3n`. "Re-asks"
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
| file name | always | ≤ 8 characters, no blanks (`read_name`) | 16 | 1169 | 2812 | all discrete + error cases |
| number of traits | always | integer | 32 | 1185 | 2828 | all discrete |
| different indices / sources for sires and dams? | always | `y`/`n` | 96 | 1257 | 2909 | all discrete (`y`: `sxd1`–`sxd3`, `nophen1`–`nophen3`) |
| use common environmental effects? | always | `y`/`n` (re-asks) | 127 | 1301 | 2968 | all discrete (`n`: `noce1`; `y`: the rest) |
| phenotypic variance, per trait | always | real | 145 | 1319 | 2986 | all discrete |
| heritability h², per trait | always | 0 < h² < 1 (re-asks) | 150 | 1324 | 2991 | all discrete |
| c², per trait | common environment `y` | 0 ≤ c² < 1, h² + c² < 1 (re-asks) | 167 | 1341 | 3008 | all discrete |
| use full-sib groups? | always | `y`/`n` | 190 | 1364 | 3031 | all discrete |
| number of full-sib groups | FS `y` | integer, "max=20" (not checked) | 195 | 1369 | 3036 | most discrete; 2-stage: `prog2s`, `sxd2`, `onetrt2s` |
| animals per full-sib group, per group | FS `y` | real | 200 | 1374 | 3041 | as above |
| use half-sib groups? | always | `y`/`n` | 206 | 1380 | 3047 | all discrete |
| number of half-sib groups | HS `y` | integer, "max=20" (not checked) | 211 | 1385 | 3052 | most discrete; 2-stage: `prog2s`, `sxd2`, `onetrt2s` |
| dams per half-sib group, per group | HS `y` | real | 216 | 1390 | 3057 | as above |
| animals per half-sib group, per group | HS `y` | real | 220 | 1394 | 3061 | as above |
| use progeny groups? | always | `y`/`n` | 226 | 1400 | 3067 | all discrete |
| number of progeny groups | progeny `y` | integer, "max=20" (not checked) | 231 | 1405 | 3072 | `advgrp`, `multigrp`; `prog2s`; `prog3s` |
| dams per progeny group, per group | progeny `y` | real | 237 | 1411 | 3078 | as above |
| animals per progeny group, per group | progeny `y` | real | 243 | 1417 | 3084 | as above |
| phenotypic correlation, per trait pair | always | −1 < r < 1 (re-asks the pair) | 316 | 1510 | 3199 | all discrete |
| genetic correlation, per trait pair | always | −1 < r < 1 (re-asks the pair) | 325 | 1519 | 3208 | all discrete |
| common environmental correlation, per pair | common environment `y` | −1 < r < 1 (re-asks the pair) | 335 | 1529 | 3218 | all discrete |
| number of selected sires | always | integer | 367 | 1561 | 3250 | all discrete |
| number of selected dams | always | integer | 371 | 1566 | 3254 | all discrete |
| male candidates per dam | always | real | 375 | 1571 | 3258 | all discrete |
| female candidates per dam | always | real | 379 | 1575 | 3262 | all discrete |
| proportion selected sires (stage 1) | always | real | 383 | 1580 | 3266 | all discrete |
| proportion selected sires, stage 2 | 2- and 3-stage | real | — | 1585 | 3270 | all 2- and 3-stage |
| proportion selected sires, stage 3 | 3-stage | real | — | — | 3274 | all 3-stage |
| proportion selected dams (stage 1) | always | real | 387 | 1590 | 3278 | all discrete |
| proportion selected dams, stage 2 | 2- and 3-stage | real | — | 1595 | 3282 | all 2- and 3-stage |
| proportion selected dams, stage 3 | 3-stage | real | — | — | 3286 | all 3-stage |
| **correction:** change sire or dam sources? | separate indices `y`, a trait has no phenotypic source in either sex and no genetic correlation with a trait that has one, and the answer to the warning (section 4, `note_pheninfo`) is `i` | `s`/`d`; then the sources for that trait are asked again (section 4) and the check repeats | 486 | 1692 | 3383 | `nophen1` (`s`), `nophen2` (`d`), `nophen3` (`s`) |
| **correction:** new genetic correlation (no-source trait listed first) | as above but answer `c`, separate indices `y`; asked for the **first** trait with phenotypic sources, when it comes after the no-source trait | real | 513 | 1727 | 3426 | `nophen1`, `nophen2`, `nophen3` |
| **correction:** new genetic correlation (no-source trait listed later) | as above, when the first trait with sources comes before the no-source trait | real | 522 | 1736 | 3435 | `nophen1`, `nophen2`, `nophen3` |
| **correction:** new genetic correlation, same index (first trait after) | separate indices `n`, a trait without phenotypic source and no genetic correlation with one that has, answer `c` | real | 571 | 1788 | 3493 | `nophen1n`, `nophen2n`, `nophen3n` |
| **correction:** new genetic correlation, same index (first trait before) | as above | real | 580 | 1797 | 3502 | `nophen1n`, `nophen2n`, `nophen3n` |
| c² in the progeny test, per trait | progeny groups `y` **and** common environment `y` | 0 < c² < 1 (re-asks; note: 0 is rejected) | 623 | 1850 | 3561 | `advgrp`, `multigrp`; `prog2s`; `prog3s` |

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
| truncation selection, or fixed number per age class? | always | `t`/`n` | 94 | same (all answer `t`) |
| male candidates in age class, per class except the first (set from candidates per dam) | always | real | 112 | same |
| female candidates in age class, per class except the first | always | real | 118 | same |
| selected sires in age class, per class | fixed numbers (`n`) | real | **138** | **none** |
| selected dams in age class, per class | fixed numbers (`n`) | real | **145** | **none** |
| use common environmental effects? | always | `y`/`n` | 238 | `ovlp2` (`n`), `ovlpgrp` (`y`) |
| phenotypic variance, per trait | always | real | 256 | `ovlp2`, `ovlpgrp` |
| heritability h², per trait | always | 0 < h² < 1 (re-asks) | 261 | `ovlp2`, `ovlpgrp` |
| c², per trait | common environment `y` | as discrete | 278 | `ovlpgrp` |
| use full-sib groups? | always | `y`/`n` | 301 | `ovlp2`, `ovlpgrp` |
| number of full-sib groups / animals per group | FS `y` | integer / real | 306, 311 | `ovlpgrp` |
| use half-sib groups? | **only if sires < dams** | `y`/`n` | 318 | `ovlp2`, `ovlpgrp` |
| number of half-sib groups / dams / animals per group | HS `y` | integer / real / real | 323, 328, 332 | `ovlpgrp` |
| use progeny groups? | always | `y`/`n` | 342 | `ovlp2`, `ovlpgrp` |
| number of progeny groups / dams / animals per group | progeny `y` | integer / real / real | 347, 353, 358 | `ovlpgrp` |
| next sire age class with more information (or −1) | truncation (`t`); after the sources for the first sire class | integer or −1 | 404 | `ovlp2`, `ovlpgrp` |
| next dam age class with more information (or −1) | truncation (`t`); after the sources for the first dam class | integer or −1 | 470 | `ovlp2`, `ovlpgrp` |
| phenotypic / genetic / common env. correlation, per pair | always (common env. only if `y`) | −1 < r < 1 (re-asks the pair) | 530, 539, 549 | `ovlp2`, `ovlpgrp` (549: `ovlpgrp`) |
| c² in the progeny test, per trait | progeny `y` and common environment `y` | 0 < c² < 1 (re-asks) | 621 | `ovlpgrp` |

With fixed numbers (`n`), the sources are asked for **every** age class
that has animals selected, instead of "next age class" questions.

## 4. Shared routines (`selroutines.f90`)

| Routine | Question | Asked when | Answer (checks) | Line | Covered by |
|---|---|---|---|---|---|
| `read_name` | (reads the line for a file or trait name) | every name | text | 32 | every fixture and error case |
| `traitinfo` | trait name, per trait | discrete, always | ≤ 8 characters, no blanks, unique (`read_name`) | 1226 | all discrete + `longtrt`, `spacetrt`, `duptrt` |
| `traitinfo` | use: index `i` / goal `h` / both `b` / not now `n` | discrete, **more than one trait** (one trait is set to `b`) | `i`/`h`/`b`/`n` (re-asks) | 1239 | all discrete + `duptrt` |
| `traitinfo` | economic value, goal-only trait | use `h` | ≠ 0 (re-asks) | 1252 | `goalonly`, `fivetr`, `nophen*`, `sxd2`, `sxd3`, `prog2s`, `prog3s` |
| `traitinfo` | economic value, index-and-goal trait | use `b` | ≠ 0 (re-asks) | 1264 | all discrete + `duptrt` |
| `traitinfoovlp` | trait name, per trait | overlapping | as above | 1299 | `ovlp2`, `ovlpgrp`, `ovlptrt` |
| `traitinfoovlp` | use `i`/`h`/`b`/`n` | overlapping, more than one trait | as above | 1312 | `ovlp2`, `ovlpgrp` |
| `traitinfoovlp` | economic value, goal-only trait | use `h` | ≠ 0 | **1325** | **none** |
| `traitinfoovlp` | economic value, index-and-goal trait | use `b` | ≠ 0 | 1337 | `ovlp2`, `ovlpgrp` |
| `traitinfo2` | dams: use `i`/`h`/`b`/`n` | separate indices `y` | as above | 1379 | `sxd1`–`sxd3`, `nophen1`–`nophen3` |
| `traitinfo3` | sires, stage 2: add to index? `i`/`n` | 2- or 3-stage, more than one trait, for each trait **not** in the stage-1 index (use `n` or `h`) | `i`/`n` | 1438 | `sxd2`, `sxd3`, `prog2s`, `prog3s`, `nophen2`, `nophen2n`, `nophen3`, `nophen3n` |
| `traitinfo4` | dams, stage 2: as above | separate indices `y`, 2- or 3-stage, each dam trait not in the stage-1 dam index | `i`/`n` | 1483 | `sxd2`, `sxd3`, `nophen2`, `nophen3` |
| `traitinfo5` | sires, stage 3: as above | 3-stage, trait not in the stage-2 index | `i`/`n` | 1536 | `sxd3`, `prog3s`, `nophen3`, `nophen3n` |
| `traitinfo6` | dams, stage 3: as above | separate indices `y`, 3-stage, each dam trait not in the stage-2 dam index | `i`/`n` | 1581 | `sxd3`, `nophen3` |
| `info_sources` | information sources for a trait, first and following codes | each index trait (sires; dams too if separate indices) | codes: 1 own performance, 2 BLUP, 3+n full-sib group n, 23+n half-sib group n, 63+n progeny group n; −1 ends | 513, 516 | all discrete |
| `info_sourcesovlp` | as above, per age class | overlapping | as above | 677, 680 | `ovlp2`, `ovlpgrp` |
| `info_sources2` | sources added in stage 2 | 2- and 3-stage, if any remain | codes, −1 ends | 895, 905 | all 2- and 3-stage |
| `info_sources3` | sources added in stage 3 | 3-stage, if any remain | codes, −1 ends | 1102, 1112 | all 3-stage |
| `note_pheninfo` | warning: trait without phenotypic sources and without genetic correlation to one that has them: edit sources `i` or correlations `c`? | the checks in section 2 find such a trait (discrete only) | `i`/`c` (re-asks) | 394 | `nophen1`–`nophen3`, `nophen1n`–`nophen3n` |

## Not reached yet → step 4c

Step 4b (2026-10-09) added 20 discrete-generation inputs and reached
every discrete question. Three input lines are left, all in overlapping
generations:

| Not reached | Lines | Planned test input |
|---|---|---|
| selected sires / dams per age class (fixed numbers) | selovlp 138, 145 | `ovlpfix` |
| goal-only trait (`h`): economic value | selroutines 1325 | `ovlpfix` (includes a goal-only trait) |

How step 4b reached the correction questions: each `nophen` input has two
goal-only traits with zero genetic correlations (answered `c`; the trait
with sources is listed after the first and before the second), and a
BLUP-only trait (BLUP alone is not phenotypic information) answered `i`.
`nophen1`–`nophen3` use separate indices (`nophen2` answers `d`, the
others `s`); `nophen1n`–`nophen3n` use one index.

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
   is therefore also run in 2-stage selection (`onetrt2s`; the planned
   name `onetrait2` is over the 8-character limit).
6. **The stage-2/3 trait questions (`traitinfo3`–`traitinfo6`) don't
   re-ask.** Any answer other than `i` or `n` falls through: nothing is
   written to the echo `.in` and the trait's stage-2/3 use is left as it
   was. The other use questions re-ask. Found in step 4b; recorded for the
   I/O plan's batch-mode input guards (Phase 2), no code changed.
