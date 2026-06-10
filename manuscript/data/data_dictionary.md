# Data Dictionary

Datasets accompanying the beta regression tutorial. All four files come from
Wilford et al. (2020), which examined whether instructor fluency affects free
recall and judgments of learning (JOLs). `miko_data.csv` and
`wilford_jol_expt1b.csv` are the raw source files; `fluency_data.csv` and
`jol_data.csv` are the cleaned analysis-ready files derived from them in
`manuscript/ms.qmd`.

---

## fluency_data.csv

Cleaned data for Experiment 1A (free recall accuracy). 96 rows, one per
participant. Derived from `miko_data.csv` by recoding `Condition`, rescaling
recall to a proportion, and keeping only the first free-recall test
(`FreeCt1AVG`).

| Column | Type | Values / Range | Description |
|---|---|---|---|
| (unnamed first column) | integer | 1–96 | Row index written by `write.csv()`; not used in analysis. |
| `Participant` | integer | 1–96 | Anonymous participant ID (dense rank of original `ResponseID`). |
| `Fluency` | character | `"Fluent"`, `"Disfluent"` | Instructor delivery condition (between-subjects). |
| `Accuracy` | numeric | 0–1 | Proportion of idea units correctly recalled (raw 0–10 score / 10). Primary outcome for the Gaussian, beta, ZIB, ZOIB, and ordered-beta models in Case Study 1. |

---

## jol_data.csv

Cleaned data for Experiment 1B (metamemory judgments). 136 rows. Derived from
`wilford_jol_expt1b.csv` by recoding `Condition` and rescaling JOLs to the
unit interval.

| Column | Type | Values / Range | Description |
|---|---|---|---|
| `Participant` | integer | 1–136 | Anonymous participant ID (dense rank of original `ResponseID`). |
| `Fluency` | character | `"Fluent"`, `"Disfluent"` | Instructor delivery condition (between-subjects). |
| `JOL` | numeric | 0–1 | Judgment of learning: participant's predicted likelihood of later recall (raw 0–100 rating / 100). Contains exact 0s and 1s, motivating the ordered-beta model in Case Study 2. |

---

## miko_data.csv

Raw long-format source data for Experiment 1A. 192 rows = 96 participants ×
2 free-recall test averages.

| Column | Type | Values / Range | Description |
|---|---|---|---|
| (unnamed first column) | integer | 1–192 | Row index. |
| `ResponseID` | character | Qualtrics IDs (e.g., `R_00Owxl28JtOADxn`) | Original participant identifier. |
| `Condition` | integer | `1` = Fluent, `2` = Disfluent | Instructor fluency condition. |
| `name` | character | `"FreeCt1AVG"`, `"FreeCt2AVG"` | Which free-recall test the score is for (test 1 or test 2 average). The tutorial uses `FreeCt1AVG` only. |
| `value` | numeric | 0–10 | Number of idea units correctly recalled (out of 10). Becomes `Accuracy` after dividing by 10. |

---

## wilford_jol_expt1b.csv

Raw source data for Experiment 1B (JOLs). 136 rows, one per participant.

| Column | Type | Values / Range | Description |
|---|---|---|---|
| (unnamed first column) | integer | 1–136 | Row index. |
| `ResponseID` | character | Qualtrics IDs | Original participant identifier. |
| `Sample` | integer | `2` (constant in this file) | Sample/wave identifier from the original study. |
| `Condition` | integer | `1` = Fluent, `0` = Disfluent | Instructor fluency condition. **Note:** encoding differs from `miko_data.csv`, where Disfluent = 2. |
| `JOL1` | integer | 0–100 | Judgment of learning rating. Becomes `JOL` after dividing by 100. |

---

## Reference

Wilford, M. M., Kurpad, N., Platt, J. D., & Weinstein-Jones, Y. (2020).
The disfluency effect: Robust or fragile? See `manuscript/bibliography.bib`
(`@wilford2020`) for the full citation.
