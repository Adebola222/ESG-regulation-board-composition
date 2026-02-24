# EU ESG Regulation Impact on Corporate Governance

**Panel Data Analysis | Fixed Effects Regression**

---

## Overview

Did the EU's Non-Financial Reporting Directive (NFRD, 2014) change how European companies structure their boards? This project uses panel data from 588 companies over 15 years (2008-2022) to test whether ESG regulation led to changes in board size, independence, gender diversity, and CSR oversight.

**Sample:** 588 European companies  
**Period:** 2008-2022 (6,878 observations)  
**Method:** Fixed effects regression  

---

## The Problem

Standard approaches often test the **wrong thing**. Many studies examine if the relationship between ESG scores and governance changes after regulation—but ESG scores are themselves affected by regulation (bad control problem).

**Correct approach:** Directly test if governance metrics changed after NFRD using within-company variation.

---

## Hypotheses

- **H1:** Board size increases after NFRD
- **H2:** Board independence increases after NFRD
- **H3:** Gender diversity increases after NFRD
- **H4:** CSR committee adoption increases after NFRD

---

## Results

### Before vs. After Comparison

| Variable | Before (2008-2013) | After (2014-2022) | Change | Result |
|----------|-------------------|-------------------|--------|---------|
| **Board Size** | 12.42 | 11.96 | **-0.46** | ❌ Decreased |
| **Gender Diversity** | 19.18% | 31.64% | **+12.46%** | ✅ Increased |
| **Board Independence** | 57.47% | 65.42% | **+7.95%** | ✅ Increased |
| **CSR Committee** | 81.56% | 85.68% | **+4.13%** | ✅ Increased |

### Statistical Significance (Fixed Effects)

| Outcome | Coefficient | Std. Error | p-value | Significant? |
|---------|-------------|------------|---------|--------------|
| Board Size | -0.536 | 0.076 | < 0.001 | *** |
| Board Independence | +8.476 | 0.388 | < 0.001 | *** |
| Gender Diversity | +13.653 | 0.245 | < 0.001 | *** |
| CSR Committee | +0.078 | 0.008 | < 0.001 | *** |

**All effects highly significant (p < 0.001)**

### Hypothesis Testing

| Hypothesis | Supported? | Finding |
|------------|------------|---------|
| H1: Board size ↑ | ❌ No | Size decreased (opposite direction) |
| H2: Board independence ↑ | ✅ Yes | +8.5% increase |
| H3: Gender diversity ↑ | ✅ Yes | +13.7% increase |
| H4: CSR committees ↑ | ✅ Yes | +7.8% increase |

**3 out of 4 hypotheses supported **

---

## Key Finding

Boards didn't get **bigger**—they got **BETTER**.

The regulation led to **strategic optimization**: smaller boards with more diverse, more independent members and stronger CSR oversight. This suggests companies responded strategically rather than mechanically adding seats.

**Economic magnitude:**
- Gender diversity increased **65%** (12.5 percentage points)
- Board independence increased **14%** (8 percentage points)
- These are large, meaningful changes

---

## Methodology

### Why Fixed Effects?

Fixed effects regression compares each company **to itself** before vs. after NFRD. This controls for time-invariant company characteristics (industry, culture, founding conditions) and provides stronger causal inference than simple before-after comparisons.

**Model:**
```r
plm(Outcome ~ NFRD + Employee + Firm_Age, 
    data = panel_data, 
    model = "within")
```

### Data Quality Note

Analysis uses 2008-2022 (not full 2003-2022) because:
- Pre-2008: 80%+ observations had zero values for gender diversity and board independence
- These were missing data coded as zeros, not actual all-male boards
- Restricting to 2008+ ensures reliable estimates
- Still provides 6 years pre-treatment (2008-2013) for comparison

### Control Variables
- CEO duality (CEO also chairs board)
- Number of employees (firm size)
- Firm age (organizational maturity)

---

## Project Structure

```
├── README.md                           # This file
├── code/
│   └── analysis.R                      # Complete R analysis script
├── data/
│   └── cleaned_data.csv                # Panel dataset
├── results/
│   ├── descriptive_statistics.csv      # Before/after means
│   ├── hypothesis_summary.csv          # Hypothesis testing results
│   ├── fe_models.txt                   # Fixed effects regression output
│   └── ols_models.txt                  # OLS regression output
└── figures/
    ├── before_after_comparison.png     # Bar charts
    └── time_trends.png                 # Time series plots
```

---

## Replication

**Requirements:** R (≥ 4.0), packages: `tidyverse`, `plm`, `lmtest`, `stargazer`

**Run:**
```r
# Install packages
install.packages(c("tidyverse", "plm", "lmtest", "stargazer"))

# Run analysis
setwd("code/")
source("analysis.R")
```

**Output:**
- Console: Descriptive statistics and regression summaries
- `results/` folder: CSV and TXT files with detailed results
- `figures/` folder: PNG visualizations

---


