# Plan: modern scenario inputs and structured outputs for `fortran/`

## Status

**Design approved, revision 12 (2026-10-05).** All of Austin's questions
are answered, and multiple sweeps per folder are confirmed. Nothing is
implemented yet. The defaults listed in the last section stand unless
Austin changes them.

**This plan starts after test-hardening T0, T1 and T2** (agreed with
Austin 2026-10-05). The combined, numbered list of steps from both plans,
with dependencies and status, is
[`implementation-sequence.md`](implementation-sequence.md).
This plan changes no equations, so it only needs the tests that guard the
code it edits; the rest of test-hardening (T3–T5, T7: unit, correctness
and property tests) follows Phases 1–3 and builds on `results.csv` and
sweeps. Model changes and the R port still wait until those pass. Two
test-hardening steps also do work this plan needs, so they are not
repeated here:

- **T1's `tests/tools/strict.sh`** is the strict debug build. Phase 2
  reuses it.
- **T2's branch map and new golden fixtures** are the branch-coverage
  fixtures Phase 1 needs for the translator. Phase 1 only adds fixtures
  for branches T2 leaves uncovered.

Revision 9 changed no design. It updated binary names to `selaction`,
line references, fixture counts and the overlaps above.

Revision 10 changes no design. `fortran_mac/` was renamed `fortran/` and
`fortran_linux/` was removed, so there is one source tree for every
platform. Decision 6 is updated and the old Phase 6 (port to
`fortran_linux/`) is replaced by checking other platforms in CI.

Revision 11 changes no design. The binary is now built by the top-level
`Makefile` into `build/selaction`, and new Fortran modules are added to
its `SOURCES` list.

Revision 12 (2026-10-05, agreed with Austin): **long trait names are
handled by the R driver, not by widening the Fortran.** Trait names are
printed by ~340 `write`/`print` statements, many with fixed `a8` formats,
so widening `xtraits` would change the layout of every report and every
fixture. Instead, YAML trait names may be long; the driver gives the
Fortran short unique labels and maps them back in every CSV (see "Trait
names" under the R validator and Phase 4). Only the **file name** is
widened in the Fortran (Phase 2), which doesn't touch the report.

This plan does not touch any selection-index, response or inbreeding
equations. Every Fortran change is I/O or control flow. The existing `.out`
text report stays byte-identical, so all fixtures in `tests/fixtures/`
keep passing at every step.

## Decisions so far

| # | Question | Decision |
|---|---|---|
| 1 | Driver language | **R.** It is only a front end: it reads YAML, validates, writes the answer stream, runs the binary and collects CSVs. **It does no genetics.** Fortran stays the computational reference until it is "bullet proof"; the later R port (`SelActionR`) is separate work. |
| 2 | How scenarios are organised | **A scenario folder:** `base.yaml` (the defaults) plus one or more files that define named scenarios, each listing only what changes. Default folder `scenarios/`; `--folder <dir>` selects another. Conflicts are checked, and errors stop the batch before anything runs. |
| 3 | Summary table contents | No choice needed (see below). `summary_wide.csv` holds **every** scalar result, one row per scenario, next to the inputs that differ from base. |
| 4 | YAML reader | **The R `yaml` package (CRAN, wraps libyaml).** Nothing is hand-built, and Fortran never parses YAML. The former "Phase 6: native Fortran input" is dropped. |
| 5 | Keep the legacy `.in` echo | **Yes.** It is kept per scenario as the exact replay record. |
| 6 | Platform copies | **One source tree, `fortran/`, for every platform** (revision 10; `fortran_linux/` was removed). All of this work lands there. Other platforms are checked in CI, not ported (see Phase 6). |
| 7 | Does base run as a scenario? | **No.** `base.yaml` is only the defaults. Only explicitly named scenarios run and appear in outputs. |
| 8 | One file controlling many scenarios | **Yes.** One file can hold a `scenarios:` list (named, hand-written changes) and `sweeps:`. A sweep varies one or more inputs, crossed as a grid or paired, with names built from a template. Any input can be varied, including matrices and info-source lists. |
| 9 | Tracking what changed | **Yes.** `changes.csv` records exactly which input changed, from what to what, per scenario. `inputs_wide.csv` records every input of every scenario. The changed inputs are also the leading columns of `summary_wide.csv`. |
| 10 | Re-running a folder | **Error unless `--overwrite`** is given. Output paths stay predictable. |
| 11 | Grids (crossing inputs) | **Yes**, as part of sweeps (`mode: grid`, the default), plus `mode: paired` for inputs that change together. Names come from per-input aliases (`s{sires}_h{h2}`), with a readable default when no template is given. |
| 12 | Rebuild the Fortran input reader? | **No.** The Fortran keeps its `read *` prompt input unchanged, and R translates YAML into that answer stream. The whole program will be rebuilt in R (or other languages) later, so a Fortran input rewrite would be thrown away. It would also mean editing the core routines still under accuracy review. Fortran changes are limited to batch-mode control flow and the structured output writer. |
| 13 | Input checking | **R validates everything before any run**: types, names, matrix shape/symmetry/PD, ranges, sizes and cross-field rules. **Fortran adds guards as a second line**: group counts, info-source codes, proportions, `iostat=` on reads, and incoherent parameters treated as failure in batch mode. Any mistake must make the run fail loudly with a message and a non-zero exit code. |

Austin's priority is that the Fortran must be correct before the R port.
This work supports that goal rather than competing with it:

- **Full-precision CSVs and many-scenario batches make accuracy checking
  systematic.** For example, sweep the number of sires and look for jumps
  or non-monotone ΔF.
- **I/O commits stay separate from any numeric fix**, so a change in
  results can always be traced to one cause.

## How it works today (what we're replacing)

- `selaction` reads about 160 `read *` prompts from stdin:
  105 in `seldiscrete.f90`, 33 in `selovlp.f90` and 22 in `selroutines.f90`.
  **Which prompt comes next depends on earlier answers.** For example, an
  economic value is only asked if a trait's use is `b`, common-environment
  correlations only if `initc=y`, and group sizes only if groups are
  enabled.
- **Some prompts appear only when a check fails.** If a trait has no
  phenotypic information but is genetically correlated with a trait that
  does, the program asks "change sire or dam information sources s/d ?" or
  "new value:" for `gcorr` (`seldiscrete.f90` ~480–575). Piped input can't
  predict these, so the program re-prompts on exhausted stdin. An invalid
  `stages` answer does the same (`selaction.f90`, `goto 1000`).
- **Two output files, both limited.** `<fnam>.in` echoes the answers with
  `! comment` labels. `<fnam>.out` is a fixed-format report: `f10.3`, so
  only 3 decimals, with different layouts per scheme. `fnam` is
  `character(len=8)`. Names used to be silently cut to 8 characters; since
  2026-10-05 a longer name stops the run (`-error-30-`, exit code 2).
- **Errors and warnings have no consistent form.** Errors are `print *` +
  `stop` (`-error-10-` singular matrix, `-error-20-` P-value out of bounds,
  `dFmtblup` inconsistency). Warnings are ad hoc (`selovlp.f90:1139–1183`,
  and multistage non-convergence from eed1236). The exit code is always 0.
- **Info-source input codes** (confirmed in `info_sources`,
  `selroutines.f90:293`): 1 = own performance, 2 = BLUP breeding values,
  4–23 = full-sib group k, 24–43 = half-sib group k, 64–83 = progeny group
  k, and `-1` ends the list. The code sorts the list, so order doesn't
  matter.
  - Codes 3 (sire EBV) and 44–63 (mean EBV of the dams of half-sib group k)
    are **never entered**. They appear in the output as the expansion of
    code 2. That is why `test1` enters `1 2 4 24` but its report lists six
    sources.
  - The read loop does **not** reject invalid codes such as 3, 99 or a group
    that isn't configured. The R validator must.

## Input format: YAML

YAML handles matrices well: a correlation matrix is a list of rows. Other
options (TOML, JSON, Fortran NAMELIST, CSV) were weaker; see revision 1 in
git history for the comparison.

Features that make it AI- and script-friendly:

- **Everything is named.** You set `parameters.ADG.h2: 0.3` without
  knowing the prompt order.
- **Info sources use names:** `own`, `blup`, `fs_group: k`, `hs_group: k`
  and `progeny_group: k`. Raw codes (1, 2, 4–23, 24–43, 64–83) are also
  accepted.
- **Correlations can be a full symmetric matrix or named pairs**
  (`ADG~FCR: -0.5`). Pairs are the natural form in scenario changes, because you
  can change one correlation without retyping the whole matrix.
- **One specification file drives everything.** `driver/spec.yaml` lists
  every field with its type, range, units and when it's required. The R
  validator, `docs/inputs.md` and the commented templates are all
  generated from it, so they can't drift apart.

### `scenarios/base.yaml` (the defaults, never run itself; `test1` as the example)

```yaml
description: "3-trait pig index, FS+HS groups, base case"

scheme:
  type: discrete                   # discrete | overlapping
  stages: 1                        # 1 | 2 | 3   (discrete only)
  separate_indices_for_sexes: false

traits:                            # order here = order of matrix rows/columns
  - {name: eADG, use: index}                    # index | goal | both
  - {name: ADG,  use: both, economic_value: 5}
  - {name: FCR,  use: both, economic_value: -27}

common_environment: true
parameters:
  eADG: {phenotypic_variance: 25.0, h2: 0.20, c2: 0.05}
  ADG:  {phenotypic_variance: 95.0, h2: 0.30, c2: 0.05}
  FCR:  {phenotypic_variance: 0.04, h2: 0.20, c2: 0.05}

correlations:
  phenotypic:
    matrix:
      - [1.00,  0.25,  0.10]
      - [0.25,  1.00, -0.50]
      - [0.10, -0.50,  1.00]
  genetic:
    pairs: {eADG~ADG: 0.25, eADG~FCR: 0.10, ADG~FCR: -0.50}
  common_environment:
    pairs: {eADG~ADG: 0.05, eADG~FCR: 0.05, ADG~FCR: -0.05}

groups:
  full_sib: [{animals: 9}]
  half_sib: [{dams: 200, animals: 9}]
  progeny:  []

population:
  sires: 10
  dams: 200
  male_candidates_per_dam: 5
  female_candidates_per_dam: 5
  proportion_selected: {sires: 0.01, dams: 0.20}

info_sources:                      # same for both sexes unless separate_indices_for_sexes
  eADG: [own, blup, fs_group: 1, hs_group: 1]
  ADG:  [own, blup, fs_group: 1, hs_group: 1]
  FCR:  [own, blup, fs_group: 1, hs_group: 1]
```

Other schemes use the same structure:

- **Two- and three-stage selection:** `info_sources` and
  `proportion_selected` are given per stage (`stage_1:`, `stage_2:` …).
- **Overlapping generations:** add `age_classes_per_sex`,
  `selection_method: truncation | fixed` and per-age-class `info_sources`
  and numbers.

`spec.yaml` covers every branch the current prompts cover. The importer
(Phase 1) is what proves it.

### Scenario files: named scenarios and sweeps

`base.yaml` is **only the defaults. It is never run and never appears in
the outputs.** Every scenario that runs has an explicit name and lists only
what it changes from base.

The other `.yaml` files in the folder define scenarios. There can be one
file or many, with any file names. Each file can use either or both of two
blocks, and each block can hold as many entries as you like:

- **`scenarios:`** hand-written scenarios
- **`sweeps:`** any number of sweeps

All scenarios from all files and all sweeps run together as one batch.
They are collected in the same output tables and told apart by `group`.

```yaml
# scenarios/study.yaml

scenarios:                          # 1) hand-written scenarios: a name + what changes
  - name: A
    description: "fewer sires, same dams"
    set:
      population.sires: 5
  - name: B
    set:                            # several inputs can change together
      population.sires: 20
      population.dams: 400
  - name: weak_rg
    set:                            # change one correlation by name
      correlations.genetic.pairs: {ADG~FCR: -0.20}
  - name: new_rg_matrix
    set:                            # or replace a whole matrix
      correlations.genetic.matrix:
        - [1.00, 0.30, 0.10]
        - [0.30, 1.00, -0.40]
        - [0.10, -0.40, 1.00]

sweeps:                             # 2) shorthand: vary one or more inputs -> many scenarios
  - id: sires                       # sweep id: short, unique; recorded as the scenario's `group`
    vary:
      sires: {path: population.sires, values: [5, 10, 20, 50, 100]}
    name: "sires_{sires}"           # -> sires_5, sires_10, sires_20, sires_50, sires_100

  - id: sxh                         # two inputs -> every combination (a grid): 5 x 3 = 15 scenarios
    vary:
      sires: {path: population.sires,  values: [5, 10, 20, 50, 100]}
      h2:    {path: parameters.ADG.h2, values: [0.1, 0.2, 0.3]}
    name: "s{sires}_h{h2}"          # -> s5_h0.1, s5_h0.2, ... s100_h0.3

  - id: rg                          # matrices (or lists) need a short label per value
    vary:
      rg:
        path: correlations.genetic.matrix
        values:
          low:                      # label "low"
            - [1.00, 0.10, 0.00]
            - [0.10, 1.00, -0.20]
            - [0.00, -0.20, 1.00]
          high:
            - [1.00, 0.50, 0.30]
            - [0.50, 1.00, -0.70]
            - [0.30, -0.70, 1.00]
    name: "rg_{rg}"                 # -> rg_low, rg_high

  - id: popsize                     # paired: inputs change together, not crossed
    mode: paired                    # default is "grid" (every combination)
    vary:
      sires: {path: population.sires, values: [10, 20, 40]}
      dams:  {path: population.dams,  values: [200, 400, 800]}
    name: "pop{sires}x{dams}"       # -> pop10x200, pop20x400, pop40x800 (3 scenarios, not 9)
```

**How a sweep works.** A sweep is shorthand for writing many hand-written
scenarios. The driver takes `base.yaml` and, for every combination of the
`vary` values, makes one scenario with those inputs set. The `sires` sweep
above is exactly the same as writing five `scenarios:` entries by hand.

- **One input in `vary` gives a simple sweep.** Two or more inputs give a
  grid with every combination (`mode: grid`, the default). With
  `mode: paired`, the first values go together, then the second values,
  and so on, so all lists must be the same length.
- **Each varied input gets a short alias** (`sires`, `h2`, `rg`). The alias
  is what you use in the name template.
- **`path` can name any input**: a number, a whole matrix, a single
  correlation pair, or a list such as info sources. Each value must be
  valid for that input, for example a 3×3 matrix for
  `correlations.genetic.matrix`.
- **Numbers can be listed directly.** Matrices and lists must be given as
  `label: value`, and the label is what appears in names and tables.

**Naming.** Every scenario name must be unique across the whole folder, and
nothing is named after the file.

- **In `scenarios:`**, you write the name yourself. It can be descriptive
  or generic like `A`, `B`, `C`.
- **In a sweep, the `name` template builds it** from the aliases: `{sires}`
  becomes that scenario's value (or label). Two extra tokens are available:
  `{index}` (1, 2, 3 …) and `{letter}` (A, B, C …). So `name: "S{index}"`
  gives `S1` … `S15` if you want generic names.
- **If `name` is omitted**, the default is `{id}` followed by
  `_alias-value` for each varied input, e.g. `sxh_sires-5_h2-0.1`. You
  always get readable, unique names without writing a template.
- **Allowed characters in names are letters, digits, `.`, `_` and `-`.**
  Values are used as written in the YAML (`0.1` stays `0.1`). If a template
  would produce a duplicate or illegal name, that is an error before
  anything runs. For example, `"s{sires}"` on the `sxh` grid gives 3
  scenarios called `s5`, because it leaves out `h2`.
- **Size guard:** if a folder expands to more than 1000 scenarios, the
  driver stops unless `--max-scenarios N` is given. This catches an
  accidental 5×5×5×5 grid.

**The name is for people, not for analysis.** Every scenario also records
its `group` (the sweep id, or the file for hand-written scenarios) and each
varied input as its own column. So filtering "all `sxh` scenarios with
h2 = 0.2" never depends on decoding the name. See "Tracking inputs" below.

### Merge rules

- **`set:` keys use dotted paths** (`population.sires`). Nested YAML is
  also accepted.
- **Maps merge key by key.** `set` values replace base values.
- **Lists are replaced whole.** For example, `info_sources.eADG` replaces
  the base list for eADG, and a `matrix:` is replaced whole too.
- **Use `pairs:` to change single correlations.** Pairs are merged by trait
  name onto the base matrix.
- **There is no chaining.** A scenario is always base + its own `set`.
  Scenarios never build on each other.

### Conflict and consistency checks

The driver runs every check on **all** files before **any** scenario runs,
and reports every problem at once rather than stopping at the first.

| Check | Severity |
|---|---|
| `set`/`vary` path not in `spec.yaml` (typo, e.g. `population.sire`) | error |
| Trait name in `set`/`vary` not defined in base `traits` | error |
| A scenario changes `traits` (adds/removes) but trait-dependent blocks no longer match (parameters, matrices, info sources) | error |
| Same correlation set as both `matrix` and `pairs` in one scenario | error |
| Duplicate scenario name anywhere in the folder, including names differing only in case (they'd collide as folders on macOS) | error |
| Scenario name not filesystem-safe (spaces, `/`, …) | error |
| Sweep template produces duplicate names, or omits a varied alias so combinations collide | error |
| Sweep template uses an unknown alias, or a matrix/list value has no label | error |
| `mode: paired` with value lists of different lengths | error |
| Two varied inputs in one sweep with the same `path` | error |
| Duplicate sweep `id` in the folder | error |
| Scenario entry missing `name`, or a sweep missing `id`/`vary`/`path`/`values` | error |
| Folder expands to more than 1000 scenarios without `--max-scenarios` | error |
| A `set` value identical to base (redundant change) | warning |
| **Two scenarios resolve to identical inputs** (catches "copied it but forgot to change it") | warning |
| Scenario with empty `set` | warning |
| Folder has no `base.yaml`, or no scenarios at all | error |

Then **every resolved scenario gets the full validation** (see "Input
validation" below for the full rule list and why R has to do it).

Example error:

```
ERROR scenarios/study.yaml, scenario weak_rg: E012 trait eADG has no phenotypic info source but genetic
      correlation 0.25 with ADG; add an info source or set the correlation to 0
```

## Input validation

### What the Fortran checks today

I read this from `sel1s` (`seldiscrete.f90`) and `ovlp` (`selovlp.f90`).
The other stages follow the same pattern.

| Input | Fortran check | Gap |
|---|---|---|
| Heritability | 0 < h² < 1, re-prompts | none |
| Common-env. effect c² | 0 ≤ c² < 1 and h² + c² < 1, re-prompts | none |
| Progeny-test c² (`ccprog`) | 0 < c² < 1, re-prompts | none |
| Each correlation | −1 < r < 1, re-prompts | none per entry |
| Breeding goal | ≥ 1 goal trait, otherwise "start over" | none |
| Common environment y/n | re-prompts on anything else | other y/n flags mostly aren't checked; a typo such as `Y` silently falls to the "else" branch |
| **Positive definiteness** of phenotypic/genetic correlation matrices | **Only *after* all results are computed** (`seldiscrete.f90:1087`): prints `** incoherent genetic parameters detected` at the end of `.out`, **but the results are still printed** | an impossible parameter set produces numbers that look normal; the common-env. matrix is never checked |
| Number of FS/HS/progeny groups | **none** | the arrays are `dimension(20)`, so 21+ groups **write past the array end** (memory corruption, not an error) |
| Info-source codes | **none** | 3, 44–63, 99 or a code for an unconfigured group are accepted silently |
| Proportions selected | **none at input**; `trunc` later stops with `-error-20-` only if p is outside [0, 1] | p = 0 or p = 1 gets through to the math |
| Sires, dams, candidates per dam | **none** | zero, negative, sires > dams, or too few candidates for the requested proportion all reach the math |
| Trait names and file name | **done 2026-10-05**: `read_name` stops the run (`-error-30-`, exit 2) on names longer than 8 characters, empty, or with a space or comma; duplicate trait names (ignoring case) also stop it. Error cases in `tests/errors/` | the file name is widened in Phase 2. Trait names stay 8 characters in the Fortran for good; long names are handled by the driver's short labels (revision 12) |
| Number of traits, age classes | **none** | 0 or a negative count reaches `allocate` |
| Type (text where a number is expected) | the gfortran runtime aborts (`Bad real number in item 1 of list input`) | a crash with a compiler message, not a SelAction message |

So the Fortran checks some single values, but **not structure, sizes,
cross-field consistency or types**, and its one matrix check comes too late
to stop a run. This confirms the plan's split: the R validator is the real
gate, and the Fortran gets a few cheap guards as a second line of defence.

### R validator: the primary gate

Every rule lives in `driver/spec.yaml` and is checked on every resolved
scenario before anything runs. All failures are reported together, each
naming the file, the scenario, the input path and the trait names involved.

**Types**
- Trait names are strings.
- Numbers must be numbers; integer or decimal YAML values are both
  accepted and treated as doubles.
- Counts (traits, groups, age classes) must be whole numbers. `20` and
  `20.0` are fine, `20.5` is an error.
- Flags must be booleans or one of the listed choices. Free text is never
  accepted where a choice is expected.
- **Quoted numbers are an error.** `"0.3"` is a string in YAML, and silently
  converting it would hide mistakes.

**Trait names**
- 1–32 characters, letters, digits and `_` only. In particular, no
  spaces.
- Unique, case-insensitively.
- **Short labels for the Fortran.** The Fortran keeps its 8-character
  trait names (`xtraits`, printed in fixed-width report columns). The
  driver gives each trait a label of at most 8 characters:
  - a name of 8 characters or fewer is its own label
  - a longer name gets its first 6 characters plus a 2-digit trait
    number, e.g. `eADG_purebred` (trait 1) → `eADG_p01`
  - labels must be unique (ignoring case); the driver checks this and
    errors if a short name collides with a generated label
- The label map is written to `trait_labels.csv` in the run folder and
  into each `resolved.yaml`. Every CSV the driver assembles uses the full
  names; the classic `.out` report shows the labels.
- Every trait name used anywhere (parameters, pairs, info sources, `set`,
  `vary`) must be in `traits`.

**Matrices**
- Square, with dimension equal to the number of traits, in `traits` order.
- Symmetric to within 1e-8.
- Diagonal exactly 1.
- Off-diagonal strictly between −1 and 1, matching the Fortran rule.
- **Positive definite**, checked with an eigenvalue decomposition in R.
  This applies to the phenotypic, genetic and common-environment matrices.
  The error names the smallest eigenvalue and suggests the pairs most
  likely responsible.
- `pairs` must name valid trait pairs, with no pair given twice (`A~B` and
  `B~A` count as the same pair).

**Ranges** (same as the Fortran where it has a rule)
- 0 < h² < 1, 0 ≤ c² < 1, h² + c² < 1
- phenotypic variance > 0
- 0 < proportion selected < 1, at every stage
- sires ≥ 1, dams ≥ sires, candidates per dam > 0
- the number of candidates must allow the requested selected numbers and
  proportions

**Sizes**
- At least 1 trait, at most 20 (the manual's maximum).
- At most 20 groups of each type (the Fortran array size).
- Overlapping generations: the age-class count and per-class numbers must
  be consistent.

**Cross-field**
- At least one goal trait.
- Every info source references a configured group, and only enterable
  codes are used.
- Scheme-specific blocks are present, and blocks from another scheme are
  absent.
- A trait with no phenotypic source that is genetically correlated with
  one that has a source is an error (today this triggers an interactive
  prompt).

**Precision**
- Fortran stores single precision (about 7 significant digits). Values
  that would be rounded when stored (e.g. `0.123456789`) give a warning, so
  nobody believes extra digits were used.

### Fortran guards: second line of defence (Phase 2)

These are plain programming guards, the same kind as the earlier
`ccprog`/`initblup` fixes, with no equation changes. They protect
interactive users and anyone who bypasses R:

- **Group counts** of 0–20 are enforced before the read loops, so writes
  can't go past the arrays.
- **Number of traits and age classes** must be ≥ 1 before `allocate`.
- **Info-source codes** are rejected unless they are legal and reference a
  configured group.
- **Proportions** must be strictly between 0 and 1 at input.
- **`read` uses `iostat=`**, so text where a number belongs gives a
  SelAction error message (in batch mode `error stop 2`) instead of a
  compiler runtime abort.
- **In batch mode, each of the above is an `E` error.** Interactively the
  program re-prompts as it does today.

**The late positive-definiteness check stays where it is.** R rejects
non-PD input before any run, so normally it never fires. If it ever does
fire in batch mode, for example because R was bypassed:

- the scenario is marked **failed**, with exit code 3, an `E` code in
  `messages.csv` and `status=error` in `manifest.csv`
- its results are still written, but they are never reported as a normal
  run

Interactive behaviour is unchanged. (Decided 2026-10-02: Austin's rule is
that a mistake must make SelAction fail loudly, not finish quietly.)

### Test builds

The strict debug build comes from test-hardening T1
(`tests/tools/strict.sh`: `-fcheck=bounds,do,mem,pointer
-finit-real=snan -ffpe-trap=invalid,zero,overflow`). This plan adds its
negative (invalid-input) fixtures to that run, so every fixture, valid and
invalid, runs against it. Any out-of-bounds
access or use of an uninitialised value then fails loudly instead of
silently corrupting a result.

## Architecture

`make` builds `fortran/` into a single binary, `build/selaction`, which
accepts every scheme. The driver always calls `selaction`; it never chooses between
binaries.

```
scenarios/base.yaml + scenarios/*.yaml
        │   Rscript driver/selaction.R run --folder scenarios
        │   (merge → check conflicts → validate all → translate)
        ▼
  legacy answer stream (<scenario>.in)  ──►  selaction --batch
                                                 │
                                                 ├─ <scenario>.out           (unchanged text report)
                                                 ├─ <scenario>.results.csv   (NEW, written by Fortran)
                                                 ├─ <scenario>.messages.csv  (NEW)
                                                 └─ exit code 0 / 2 / 3      (NEW)
        ▲
  driver collects per-scenario files → batch tables
```

- **The driver lives in `driver/` in this repo.** It is an R script, not an
  R package, which keeps it clearly apart from `SelActionR`.
  - Dependencies: base R, `yaml`, and `parallel` (which ships with R).
  - Parallel runs use `parallel::mclapply`, which works on macOS and Linux.
- **Numerics are untouched.** The driver produces exactly the answer stream
  the binaries already accept, so the fixtures keep validating the same
  code path.
- **Fortran writes the structured results itself**, straight from its own
  variables, rather than the driver parsing `.out`.
- **Legacy use still works.** Interactive runs and existing `.in` files
  behave as before.
- **Fallback if prompt mirroring proves fragile:** R could write a Fortran
  `NAMELIST` file instead of the answer stream. That is not planned and is
  only noted for completeness.

## Output design

### Per-scenario results: long CSV, written by Fortran

There is one row per reported number, and the columns are the same for
every scheme:

```
scenario,quantity,trait,sex,stage,age_class,source,unit,value
sires_20,index_weight,eADG,both,1,,own,,-0.2010472
sires_20,index_weight,eADG,both,1,,dam_ebv,,-0.0540115
sires_20,equilibrium_h2,ADG,,,,,,0.2512304
sires_20,equilibrium_genetic_corr,ADG~FCR,,,,,,-0.4480117
sires_20,response,ADG,sires,,,,trait_units,3.455102
sires_20,response,ADG,total,,,,economic_units,26.56844
sires_20,response_pct_of_total,ADG,sires,,,,,62.02391
sires_20,correlated_response,eADG,total,,,,trait_units,0.4940132
sires_20,total_response,,total,,,,economic_units,27.84901
sires_20,accuracy,,both,1,,,,0.5763012
sires_20,delta_F,,,,,,per_generation,0.04046
```

(The numbers are illustrative.)

- **Precision:** about 7 significant digits. The program's internals are
  single-precision `real`, so the documentation won't imply more.
- **Coverage:** I'll build the checklist by walking every `write(unit=20`
  site, so nothing in `.out` is missing from the CSV. It covers:
  - resolved inputs
  - index weights, using the *expanded* sources (`dam_ebv`, `sire_ebv`,
    `hs_dams_ebv:k`)
  - equilibrium parameters and correlations
  - responses by trait × sex × unit, and correlated and total response
  - per-stage results for multistage selection: proportion, intensity,
    truncation point and response
  - per-age-class results for overlapping generations: index variance,
    accuracy, numbers selected and generation interval
  - ΔF
  - run diagnostics: iterations and convergence flags

### Messages CSV and exit codes

```
scenario,severity,code,where,message
sires_5,warning,W031,ovlp/truncation,"requested number of sires cannot be met; selected 4.871"
```

- **Every existing warning or error gets a stable code**, listed in
  `docs/messages.md`.
- **Messages still appear in stderr and `.out` as today**, so the
  byte-identical rule holds.
- **Exit codes:** 0 = ok (warnings allowed), 2 = input error, 3 = numerical
  failure.

### Batch output (assembled by the driver)

```
runs/<folder name>/              # e.g. runs/scenarios/, runs/my_scenarios_folder/
  manifest.csv                   # scenario, status, exit_code, n_warnings, runtime_s, input_sha256, git_commit, binary
  scenarios.csv                  # scenario, group, source file, description, + one column per varied input (value or label)
  changes.csv                    # long: scenario, input_path, base_value, scenario_value: exactly what changed
  inputs_wide.csv                # one row per scenario, one column per input (flattened), all inputs
  results_long.csv               # every scenario's results.csv stacked
  summary_wide.csv               # one row per scenario: inputs that differ from base + EVERY scalar result
  messages.csv                   # all warnings/errors, including merge/validation warnings
  input_copy/                    # verbatim copy of the scenario folder as submitted
  scenarios/<scenario>/
      resolved.yaml              # base + this scenario's changes, defaults filled: exactly what ran
      <scenario>.in              # generated legacy answer stream (replay record)
      <scenario>.out             # classic text report
      <scenario>.results.csv
      <scenario>.messages.csv
      stdout.log
```

**Tracking inputs.** Because sweeps generate scenarios that have no
input file of their own, the driver records the inputs itself, at three
levels of detail:

- **`changes.csv`** has one row per changed input per scenario, for
  example:

  ```
  scenario,group,input_path,base_value,scenario_value
  sires_5,sires,population.sires,10,5
  s5_h0.2,sxh,population.sires,10,5
  s5_h0.2,sxh,parameters.ADG.h2,0.30,0.2
  weak_rg,study.yaml,correlations.genetic.ADG~FCR,-0.50,-0.20
  rg_low,rg,correlations.genetic.eADG~ADG,0.25,0.10
  rg_low,rg,correlations.genetic.ADG~FCR,-0.50,-0.20
  ```

  Matrices are always recorded **per pair, by trait names**, so a matrix
  change shows exactly which correlations moved.
- **`inputs_wide.csv`** has every input of every scenario (matrices
  flattened the same way), whether or not it changed.
- **`resolved.yaml`**, one per scenario, is a complete standalone input
  file. It can be re-run or shared on its own.

**About `summary_wide.csv`** (this answers question 3 from revision 1):
there is nothing to choose. It is simply `results_long.csv` turned
sideways. Each scenario is one row, and each distinct result gets its own
column, named like `response.ADG.total.economic_units` or `delta_F`. In
front of those come `scenario`, `group` and one column for every input that
varies anywhere in the folder, named by its path (`population.sires`,
`parameters.ADG.h2`). Swept matrices also get a column holding their label
(`low`/`high`), next to the per-pair columns. For example, in `sxh` you can
filter `group == "sxh" & parameters.ADG.h2 == 0.2` and plot ΔF against
`population.sires`. So all values are there, and plotting ΔF against sires
is one line in R or Excel.

**Failure policy:** if one scenario fails during its run, the others still
run. The failure is recorded in `manifest.csv` and `messages.csv`, and the
batch exits non-zero. Validation failures are different: they stop the
whole batch up front, before anything runs.

## Driver commands

```
Rscript driver/selaction.R validate [--folder scenarios]
Rscript driver/selaction.R run      [--folder scenarios] [--out runs/<folder>] [--jobs N] [--overwrite]
Rscript driver/selaction.R template --scheme discrete --stages 2 --traits 3 > scenarios/base.yaml
Rscript driver/selaction.R import   legacy.in > base.yaml
Rscript driver/selaction.R collect  runs/<folder>
Rscript driver/selaction.R sources  # name ↔ code table
```

- **`run` validates first** and refuses to write into an existing output
  directory unless `--overwrite` is given.
- **Running several folders back to back is safe.** For example,
  `--folder heritability_study` then `--folder sire_study` give separate
  `runs/heritability_study/` and `runs/sire_study/` directories.
- **`collect` rebuilds the batch tables**, for example after re-running a
  failed subset.

## Phased implementation

Each phase keeps `tests/run_tests.sh` green, and every change
gets a `NEWS.md` entry. Work happens in `fortran/` and `driver/` only.

**Phase 1: spec, translator and importer (R only, no Fortran edits)**
- `driver/spec.yaml`.
- The YAML → answer-stream translator. It mirrors each conditional prompt
  branch of `sel1s`/`sel2s`/`sel3s`/`ovlp`/`info_sources*`.
- The `import` command (legacy `.in` → YAML).
- **Branch-coverage fixtures.** The translator must reproduce the prompt
  order exactly, so every conditional `read *` branch needs a fixture.
  Test-hardening T2 builds the branch map and most of these fixtures
  (`sxd1`–`sxd3`, `noce1`, `goalonly`, `prog2s`/`prog3s`, `ovlpfix`, …).
  Phase 1 starts from that map and adds a fixture only for a branch T2
  leaves uncovered, through the normal `tests/fixtures/` +
  `manifest.txt` route.
- **Acceptance:** for every fixture in `tests/fixtures/`, `import` then
  translate gives a byte-identical `.out`.

**Phase 2: batch-mode hardening (Fortran control flow only)**
- A `--batch` flag: no banner padding on stdout.
- In batch mode, EOF or an invalid answer gives `error stop 2` instead of
  a re-prompt loop. The check-failure correction prompts become errors.
- `stop` becomes `error stop 3` for numerical failures.
- Widen the **file name** (`fnam`, `fnamein`, `fnameout`) to 64
  characters and raise `read_name`'s limit for it to match. `fnam` only
  names the files and appears in the `.in` echo, not in the `.out`
  report, so no fixture changes. The `longfile`/`longovlp` error cases
  move to a 65-character name. **Trait names stay at 8 characters**
  (revision 12).
- The input guards from "Fortran guards: second line of defence" above:
  group counts, trait/age-class counts, info-source codes, proportions,
  and `iostat=` on reads.
- The negative fixtures are added to T1's strict build (`strict.sh`).
- **Acceptance:** fixtures stay byte-identical. Negative fixtures exit fast
  with the right code, including 21 groups, code 99 and text in a numeric
  field. All fixtures pass under the strict build.

**Phase 3: structured result writer (Fortran, output only)**
- A new module, `selreport.f90`, provides `report_value` and
  `report_message`.
- Each call sits beside an existing `write(unit=20` result line and writes
  the same variables. There is no new computation.
- `selreport.f90` is added to `SOURCES` in the `Makefile` (before
  `selaction.f90`) and to the fallback command in `README.md`/`CLAUDE.md`.
- **Acceptance:** a golden `results.csv` for each fixture, compared with a
  numeric tolerance, plus a script checking that every `.out` number equals
  its CSV value rounded to 3 decimals.

**Phase 4: driver merge/validate/run/collect**
- Scenario/sweep expansion, merge, conflict checks, `changes.csv`, the full validator, parallel runs,
  the `runs/` layout and all batch tables.
- Trait labels: generate the short labels, write `trait_labels.csv`, pass
  labels to the Fortran, and replace labels with full names in every
  collected CSV. Test: a base with a 13-character trait name runs, its
  `.out` shows the label, and `summary_wide.csv` shows the full name.

**Phase 5: docs and examples**
- `docs/inputs.md` (generated from `spec.yaml`), `docs/outputs.md` (the
  quantity dictionary) and `docs/messages.md`.
- `examples/scenarios/`: a base plus a scenarios file (with sweeps) for each scheme.
- **`docs/scenarios.md`: a user guide to scenario folders and sweeps.** The
  design is settled but not yet written up for users. It should cover:
  - how `base.yaml` and scenario files combine
  - hand-written `scenarios:`
  - one-input sweeps, grids and `mode: paired`
  - several sweeps in one folder
  - aliases and name templates (`{alias}`, `{index}`, `{letter}`, and the
    default name)
  - labelled values for matrices and lists
  - how to find a scenario's inputs again in `scenarios.csv`,
    `changes.csv` and `summary_wide.csv`
  - the common errors (duplicate names, templates missing an alias,
    paired length mismatch, the size guard)

  Each example in the guide doubles as a test folder, so the docs can't
  drift from the behaviour.
- A short "for AI agents" section: use `template`, edit, then `validate`.

**Phase 6: other platforms (CI, no port)**
- No porting: `fortran/` is the only source tree. The driver and the
  batch tests run in the test-hardening T6 CI on Linux and macOS (and
  Windows, once added), with the tolerant comparison where last digits
  differ from the reference toolchain.

## Testing strategy

- **Existing fixtures:** byte-identical through every phase.
- **Round trip:** `.in → YAML → .in → .out` for every fixture.
- **Structured output:** golden `results.csv` (with tolerance) and the
  `.out` ↔ CSV consistency check.
- **Merge and conflict cases:** one test folder per row of the conflict
  table, each asserting the exact error or warning code.
- **Negative inputs:**
  - a non-PD matrix
  - an undefined group
  - an illegal source code
  - an uncorrelated trait with no phenotypic info
  - `stages: 4`

  Each must fail fast and never hang; the runner enforces a timeout.
- **Batch:** a folder with a base, 2 hand-written scenarios and a
  5-value sweep must produce exactly 7 rows with unique keys. A second
  folder must spread several sweeps (a 5-value sweep, a 5×3 grid and a
  paired 3-value sweep) across two files and produce exactly 23 rows, each
  with the right `group`. In both folders, `changes.csv` must list exactly
  the changed inputs, with no extra rows.
- **Sweep expansion:**
  - each sweep must expand to the same resolved inputs as the equivalent
    hand-written `scenarios:` entries
  - a 5×3 grid gives 15 scenarios and a paired 3+3 sweep gives 3
  - the default names and template names match the documented examples

## Defaults (no open questions)

All questions are answered. The choices below are defaults I picked; they
stand unless Austin changes them.

Decisions I've made that you can override:

- the R driver is a plain script in `driver/`, not a package
- lists in `set` replace the base list whole
- each scenario is base + its own changes, with no chaining
- validation errors stop the whole batch before any run, but a runtime
  failure of one scenario doesn't stop the others
- the size guard is 1000 scenarios per folder (override with
  `--max-scenarios`)
- scenario names allow only letters, digits, `.`, `_` and `-`
- `run` refuses to write into an existing `runs/<folder>/` unless
  `--overwrite` is given; with it, the old folder is replaced entirely, not
  merged
