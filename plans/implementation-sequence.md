# Implementation sequence

*Agreed with Austin 2026-10-05.* One ordered list of every step in
[`test-hardening.md`](test-hardening.md) (T-steps) and
[`modernize-inputs-and-outputs.md`](modernize-inputs-and-outputs.md)
(I/O phases). The two plans hold the detail and the acceptance checks;
this file only fixes the **order**, the **dependencies** and the
**status**. Update the status column here when a step is done.

**Where are we?** See [`progress.md`](progress.md): its top section says
what was finished last and what comes next, and it has a short summary
of every finished step.

## Rules for every step

- **Before starting:** show Austin the exact steps in plan mode, and wait
  for approval.
- **While working:**
  - no equation changes; a suspected numerical error is reported, not
    fixed
  - `make test` stays green
  - every golden `.out` stays byte-identical, unless the step says
    otherwise
- **When done:**
  - a `NEWS.md` entry
  - one commit per step (or sub-step), pushed to `main`
  - the status column here updated
  - **a summary added to [`progress.md`](progress.md)**, using its
    template (what changed, tests, whether results changed, findings,
    next step), and its "Current position" section updated

## Why this order

- **The I/O work (steps 6–8) changes no equations.** It only needs tests
  that guard the code it edits: the strict debug build (T1) and test
  inputs for every input path (T2).
- **The proof that the numbers are correct** (unit, correctness and
  property tests, steps 9–11) comes after. It uses the full-precision
  `results.csv` and sweeps from the I/O work, and the correctness cases
  wait on review by Austin, Jack and Piter anyway.
- **Model changes and the R port come last,** after that proof.

## Already done (outside the plans)

| What | Commit |
|---|---|
| One source tree `fortran/`; `fortran_linux/` removed | `1df843a` |
| Build with `make` into `build/` | `49e01e4` |
| Bad file/trait names stop the run (`-error-30-`, exit 2); first error tests in `tests/errors/` | `5e98c91` |

## The sequence

| # | Step | Plan section | Depends on | Size | Status |
|---|---|---|---|---|---|
| 1 | **T0:** delete the dead `selinbreeding.f90` | test-hardening T0 | — | small | done 2026-10-05 |
| 2 | **T1:** test tooling: `strict.sh`, `coverage.sh`, `compare_out.R`, `run_all.sh` (`make check`) | test-hardening T1 | 1 | medium | done 2026-10-05 |
| 3 | **T6:** CI on GitHub Actions (Linux, macOS Apple Silicon, Windows): golden byte-exact on Linux and Windows, tolerant on Apple Silicon | test-hardening T6 | 2 | small–medium | done 2026-10-06 |
| 4a | **T2a:** input map: every input question, and which fixture reaches it | test-hardening T2 | 2 | medium | done 2026-10-06 (`tests/input_map/`) |
| 4b | **T2b:** new discrete-generation fixtures: `sxd1`–`sxd3`, `matrat1`, `nophen1`–`nophen3`, `nophen1n`–`nophen3n`, `noce1`, `goalonly`, `onetrait`, `onetrt2s`, `fivetr`, `multigrp`, `prog2s`, `prog3s`, `sires19`/`sires20` | test-hardening T2 | 4a | large | done 2026-10-09 (`5d65e12`–`5517a5e`); `matrat1` (Q6) and `sires19`/`sires20` (Q7) marked *pending answer* |
| 4c | **T2c:** new overlapping-generation fixtures: `ovlpfix`, `ovlp3ac`; coverage check (≥ 95% lines, branches reported) | test-hardening T2 | 4a | medium | **next**; `ovlp3ac` (Q2, Q4) marked *pending answer* |
| 5a | **I/O 1a:** `driver/spec.yaml`, translator and importer for **1-stage** discrete | I/O Phase 1 | 4b | large | |
| 5b | **I/O 1b:** translator and importer for **2- and 3-stage** | I/O Phase 1 | 5a | medium | |
| 5c | **I/O 1c:** translator and importer for **overlapping generations**; round trip passes for every fixture | I/O Phase 1 | 5a, 4c | medium | |
| 6 | **I/O 2:** `--batch`, exit codes 2/3, input guards, file name widened to 64 characters; new error cases in `tests/errors/` and the strict build | I/O Phase 2 | 2, 4 | medium | |
| 7 | **I/O 3:** `selreport.f90` writes `results.csv` and `messages.csv`; golden CSVs and the `.out` ↔ CSV check | I/O Phase 3 | 6 | large | |
| 8 | **T6** (if not done at step 3) | test-hardening T6 | 2 | small–medium | not needed (done at step 3) |
| 9 | **T3:** unit tests of the maths routines against R | test-hardening T3 | 2 | medium | |
| 10 | **T4:** correctness cases, drafted by Claude, *provisional* until verified | test-hardening T4 | 7 | large | needs review by Austin, Jack, Piter; case 5 expected to fail until Q5 is answered; their worked examples added when they arrive |
| 11 | **T5:** property tests (as paired inputs, or as sweeps once step 12 exists) | test-hardening T5 | 7 | medium | needs review; "more sires → lower ΔF" fails at 19→20 (Q7); "fewer selected → higher response" direction to confirm |
| 12 | **I/O 4:** full driver: the three ways to run (one file, complete files, base + changes), merge, conflicts, validator, trait labels, parallel runs, batch tables | I/O Phase 4 | 5, 7 | large | can run alongside 9–11 |
| 13 | **I/O 5:** docs (`inputs.md`, `outputs.md`, `messages.md`, `scenarios.md`) and examples | I/O Phase 5 | 12 | medium | |
| 14 | **T7:** coverage gate in CI | test-hardening T7 | 3 or 8, 4c | small | |
| 15 | **I/O 6:** driver and batch tests in CI on every platform | I/O Phase 6 | 3 or 8, 12 | small | |

## Where Jack and Piter's input is needed

*Decided with Austin 2026-10-05:* **the sequence goes ahead without
waiting for them.** Their answers are needed only before the equations
change, which is after the sequence.

The open questions (Q1–Q7) are in
`correspondence/2026-10-bijma-dekkers/SelAction_open_questions.pdf`,
**sent to Jack and Piter on 2026-10-05**:

1. generation interval
2. genetic lag between age classes
3. the former search range and clamp
4. family structure under overlapping generations
5. stage correlations, r13|2 and the 0.93 cap
6. half-sib information when each sire has one dam
7. the switch in the inbreeding correction at 20 sires

Addendum (`correspondence/2026-10-bijma-dekkers-addendum/`, written
2026-10-06 after the input map, not yet sent):

8. should the progeny-test c² be allowed to be 0? (input check only)
- addition to 6: discrete and overlapping generations treat half-sib
  groups differently when sires = dams

**Hard stop: model changes.** No equation changes on Q1–Q7 until Jack
and Piter have answered and steps 10–11 pass. Each change then gets its
own commit, `NEWS.md` entry and before/after results.

**Fixtures marked *pending answer*** (steps 4b–4c). These record what the
code does today, which is all a golden fixture claims. They are built
now, and their `.out` is regenerated if an answer changes the model. The
mark goes at the start of the manifest description, e.g.
`[pending Q6] ...`, and in `tests/README.md`.

| Fixture | Question | Why |
|---|---|---|
| `matrat1` | Q6 | equal numbers of sires and dams: half-sib information with one dam per sire |
| `sires19`, `sires20` | Q7 | the same scheme either side of the 20-sire switch, so a change there shows up |
| `ovlp3ac` | Q2, Q4 | three age classes: genetic lag and the family-structure correction |

**Tests expected to fail until an answer arrives** (steps 10–11). They
run, and their failure is recorded as a finding that names the question.
The Fortran is not changed to make them pass, and they are not hidden.

| Test | Question | Expected |
|---|---|---|
| T4 case 5: two-stage selection with no new information equals one-stage with p₁·p₂ | Q5 | fails; the 0.93 cap distorts the stage correlation |
| T5: more sires gives lower ΔF | Q7 | fails between 19 and 20 sires |
| T5: fewer selected gives higher response | — | direction to confirm with them (Bulmer and finite-population effects) |

**Review of provisional tests** (steps 10–11). Every correctness and
property case Claude drafts runs straight away. It counts as *verified*
only once Austin, Jack or Piter has checked it, whenever convenient.
Nothing waits for this.

**Worked examples.** If they send examples with known answers, these
become the strongest correctness cases and are added to step 10 when they
arrive. Until then, step 10 uses cases from published theory.

**Anything else unexpected.** If any step turns up a number that looks
wrong outside Q1–Q7, that item stops. It is written up with evidence in
`progress.md`, and Austin decides whether it goes to Jack and Piter.
Other steps continue.

## After the sequence

| Step | Plan | Waits on |
|---|---|---|
| Model changes from Jack and Piter's answers, each with before/after results | `correspondence/2026-10-bijma-dekkers/` | their answers, and steps 9–11 passing |
| Prebuilt downloads on GitHub Releases | [`releases.md`](releases.md) | CI (step 3 or 8); can come any time after |
| Documentation site (the old `document.md` idea was dropped 2026-10-09; user docs are I/O Phase 5, step 13) | — | step 13 |
| R port (`SelActionR`, separate repository) | — | everything above |

## Notes

- **Step 3 or 8.** CI is cheap and guards every later commit, so doing
  it at step 3 is recommended. It is listed twice only so that the order
  works either way.
- **Step 9 (T3)** depends only on T1, so it can move earlier if
  convenient. The agreed order puts it after the I/O work.
- **Step 6 needs only part of step 5.** It edits the Fortran input code,
  which T2 (step 4) covers, so it may start before all of step 5 is done.
- **Steps 10 and 11 stay provisional.** Their cases run and fail loudly,
  but count as verified only once Austin, Jack or Piter has checked them
  (test-hardening, Decision 4).
