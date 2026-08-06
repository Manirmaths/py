# Food Inflation-at-Risk under Delayed Feedback

This repository contains the LaTeX manuscript, the frozen external-validation protocol, the Phase 10 forecasting code, processed result tables needed for the figures, and an R/`ggplot2` figure pipeline.

## Project structure

- `manuscript/main.tex` - canonical LaTeX manuscript.
- `manuscript/references.bib` - BibTeX bibliography source.
- `manuscript/figures/` - generated publication figures; do not edit manually.
- `protocol/protocol.tex` - frozen external-validation protocol in LaTeX.
- `code/R/make_figures.R` - generates all six manuscript figures with `ggplot2`.
- `code/python/build_phase10_meta_controller.py` - Phase 10 empirical and simulation analysis.
- `data/processed/` - compact processed CSV outputs used by the R figure pipeline.
- `.github/workflows/render-manuscript.yml` - reproducible CI build for R figures and both PDFs.

## Reproduce locally

Requirements: R (>=4.3), `ggplot2`, `dplyr`, `readr`, `tidyr`, `scales`, `lubridate`, and a LaTeX distribution with `latexmk`.

```bash
make all
```

The generated PDFs are:

- `manuscript/main.pdf`
- `protocol/protocol.pdf`

## Scientific status

The Phase 10 controller is an exploratory second-stage backtest. It improves materially over the static benchmark but does not establish statistically decisive superiority over the best individual expert. Confirmatory claims require the frozen protocol to be applied to a genuinely untouched country or future period.

## Data note

The repository contains only compact processed outputs required to reproduce figures and manuscript tables. Raw NBS and WFP data should be obtained from their original providers under the applicable terms.
