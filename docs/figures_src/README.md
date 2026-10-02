# Report figure sources

`make_figs.py` generates `selaction_sources.svg`, `selaction_truncation.svg`,
`selaction_bulmer.svg` and `selaction_agethreshold.svg` for
`SelAction_Technical_Report.tex`:

    python3 make_figs.py .. test1_rounds.txt
    cd .. && for f in sources truncation bulmer agethreshold; do
      rsvg-convert -f pdf -o selaction_$f.pdf selaction_$f.svg; done

`test1_rounds.txt` holds the per-round values plotted in the Bulmer figure
(round, sire index variance, dam index variance, sire accuracy, dam accuracy,
total response). They were logged from `fortran_mac` running
`tests/fixtures/test1.in` through `msseld`, with one temporary `write` added
after `call covariance_update` in `sel1s`. The final values match the program
output (index variance 203.380, accuracy 0.576, total response 27.849).

The other figures (`selaction_flow`, `selaction_stages`, `selaction_ages`) are
hand-written SVG.
