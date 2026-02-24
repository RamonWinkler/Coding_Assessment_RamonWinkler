# Analytical Data Science Programmer Coding Assessment 

**Candidate:** Ramon Winkler 

### This repository contains solutions to the Analytical Data Science Programmer Coding Assessment.


## Repository Structure

```
.
├── README.md
│
├── question_1_sdtm/
│   ├── 01_create_ds_domain.R       # Main SDTM DS domain creation script
│   ├── ds_sdtm.csv                 # Final SDTM DS dataset
│   └── ds_log.txt                  # Execution log
│
├── question_2_adam/
│   ├── create_adsl.R               # ADaM ADSL creation script
│   ├── adsl.csv                    # Final ADSL dataset
│   └── adsl_log.txt                # Execution log
│
├── question_3_tlg/
│   ├── 01_create_ae_summary_table.R  # AE summary table using {gtsummary}
│   ├── 02_create_visualizations.R    # AE severity & top-10 AE plots
│   ├── ae_summary_table.html         # Rendered summary table output
│   ├── ae_severity_plot.png          # Plot 1: AE severity by treatment arm
│   ├── ae_top10_plot.png             # Plot 2: Top 10 most frequent AEs with 95% CI
│   └── ae_table_log.txt              # Execution log for table creation
│   └── ae_visuals_log.txt            # Execution log for visuals creation
│
└── question_4_python/
    ├── clinical_trial_data_agent.py  # GenAI agent class & execution logic
    └── test_agent.py                 # Test script with 3 example queries
```

---

## Environment Setup

### R (Questions 1–3)

**Requires R ≥ 4.2.0** — Recommended environment: [Posit Cloud](https://posit.cloud/plans)

```r
install.packages(c(
  "admiral",
  "sdtm.oak",
  "pharmaverseraw",
  "pharmaversesdtm",
  "pharmaverseadam",
  "gtsummary",
  "ggplot2",
  "gt",
  "dplyr",
  "tidyr",
  "lubridate"
))
```

### Python (Question 4)

**Requires Python ≥ 3.9**

```bash
pip install pandas langchain openai
```

> **Note:** An OpenAI API key is required to run the live agent. If unavailable, the LLM response is mocked in `clinical_trial_data_agent.py` — the full logic flow (Prompt → Parse → Execute) remains intact and demonstrable.

---

## Question 1 – SDTM DS Domain Creation

**Script:** `question_1_sdtm/01_create_ds_domain.R`

### Objective

Create the SDTM Disposition (DS) domain from raw clinical trial data using `{sdtm.oak}`. 

### Inputs

| Input | Description |
|-------|-------------|
| `pharmaverseraw::ds_raw` | Raw disposition data |
| `sdtm_ct.csv` | Study controlled terminology data frame |

### Output
**Output:** `ds_sdtm.csv`****

---

## Question 2 – ADaM ADSL Dataset Creation

**Script:** `question_2_adam/create_adsl.R`

### Objective

Create the ADSL (Subject-Level Analysis Dataset) from SDTM source domains using `{admiral}` functions and tidyverse tools.

### Inputs

| Domain | Package |
|--------|---------|
| DM | `pharmaversesdtm::dm` |
| VS | `pharmaversesdtm::vs` |
| EX | `pharmaversesdtm::ex` |
| DS | `pharmaversesdtm::ds` |
| AE | `pharmaversesdtm::ae` |

### Outputs
**Output:** `adsl.csv`

---

## Question 3 – TLG: Adverse Events Reporting

### Objective

Produce regulatory-style adverse event outputs using `pharmaverseadam::adae` and `pharmaverseadam::adsl`.

### 3.1 AE Summary Table

**Script:** `question_3_tlg/01_create_ae_summary_table.R`

**Output:** `ae_summary_table.html`

### 3.2 Visualizations

**Script:** `question_3_tlg/02_create_visualizations.R`

**Output:** `ae_severity_plot.png`

**Output:** `ae_top10_plot.png`

---

## Question 4 – GenAI Clinical Data Assistant *(Bonus)*

**Folder:** `question_4_python/`

### Objective

Build a Generative AI assistant that translates free-text clinical questions into structured Pandas dataset queries.

### Architecture

```
User Question
    │
    ▼
LLM (with schema context + prompt engineering)
    │
    ▼
Structured JSON Output
  { "target_column": "AESEV", "filter_value": "MODERATE" }
    │
    ▼
Pandas Filter Execution
    │
    ▼
Result: unique subject count + list of USUBJIDs
```

---

*Submitted as part of the Roche PD Data Science Analytical Data Science Programmer hiring process.*
