# ==============================================================================
# EU ESG REGULATION IMPACT ON CORPORATE GOVERNANCE
# Panel Data Analysis (2003-2022)
# ==============================================================================
# Research Question: Did NFRD regulation (2014) change board composition?
# Hypotheses:
#   H1: Board size increases
#   H2: Board independence increases  
#   H3: Gender diversity increases
#   H4: CSR committees increase
# ==============================================================================

# Load required packages
library(tidyverse)   # Data manipulation
library(plm)         # Panel data models (fixed effects)
library(lmtest)      # Statistical tests
library(stargazer)   # Regression tables
library(knitr)       # Markdown tables

# Create output directories
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ==============================================================================
# 1. DATA PREPARATION
# ==============================================================================

# Load data
data <- read.csv("cleaned_data.csv")

# See what zeros look like
table(data$Gender_diversity == 0, data$year)
table(data$Board_independent == 0, data$year)

# Clean data: remove zeros (likely missing values, not true zeros)
data_clean <- data %>%
  filter(
    year >= 2008,              # Data quality threshold
    Board_size > 0,
    Gender_diversity > 0,      # Now these are more likely real
    Board_independent > 0,     # Now these are more likely real
    Employee > 0,
    age > 0
  ) %>%
  mutate(
    Name = as.factor(Name),
    nfrd = as.factor(nfrd)
  )

# Sample overview
cat("\n=== SAMPLE OVERVIEW ===\n")
cat("Total observations:", nrow(data_clean), "\n")
cat("Companies:", length(unique(data_clean$Name)), "\n")
cat("Years:", min(data_clean$year), "-", max(data_clean$year), "\n")
cat("Before NFRD:", sum(data_clean$nfrd == 0), "\n")
cat("After NFRD:", sum(data_clean$nfrd == 1), "\n\n")

# ==============================================================================
# 2. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("\n=== DESCRIPTIVE STATISTICS ===\n\n")

# Split data by treatment period
pre_nfrd <- data_clean %>% filter(nfrd == 0)
post_nfrd <- data_clean %>% filter(nfrd == 1)

# Calculate means before and after
desc_stats <- tibble(
  Variable = c("Board Size", "Gender Diversity (%)", "Board Independence (%)", "CSR Committee (%)"),
  Before = c(
    mean(pre_nfrd$Board_size),
    mean(pre_nfrd$Gender_diversity),
    mean(pre_nfrd$Board_independent),
    mean(pre_nfrd$CSR) * 100
  ),
  After = c(
    mean(post_nfrd$Board_size),
    mean(post_nfrd$Gender_diversity),
    mean(post_nfrd$Board_independent),
    mean(post_nfrd$CSR) * 100
  )
) %>%
  mutate(
    Change = After - Before,
    Pct_Change = (Change / Before) * 100
  )

print(desc_stats, n = 4)

# Save descriptive statistics
write.csv(desc_stats, "results/descriptive_statistics.csv", row.names = FALSE)

# ==============================================================================
# 3. STATISTICAL SIGNIFICANCE TESTS
# ==============================================================================

cat("\n=== STATISTICAL TESTS ===\n\n")

# T-tests for continuous variables
t_bs <- t.test(post_nfrd$Board_size, pre_nfrd$Board_size)
t_gd <- t.test(post_nfrd$Gender_diversity, pre_nfrd$Gender_diversity)
t_bi <- t.test(post_nfrd$Board_independent, pre_nfrd$Board_independent)

cat("Board Size: t =", round(t_bs$statistic, 3), ", p =", format.pval(t_bs$p.value, digits = 3), "\n")
cat("Gender Diversity: t =", round(t_gd$statistic, 3), ", p =", format.pval(t_gd$p.value, digits = 3), "\n")
cat("Board Independence: t =", round(t_bi$statistic, 3), ", p =", format.pval(t_bi$p.value, digits = 3), "\n")

# Proportion test for CSR committee
prop_csr <- prop.test(c(sum(post_nfrd$CSR), sum(pre_nfrd$CSR)), 
                       c(nrow(post_nfrd), nrow(pre_nfrd)))
cat("CSR Committee: χ² =", round(prop_csr$statistic, 3), ", p =", format.pval(prop_csr$p.value, digits = 3), "\n\n")

# ==============================================================================
# 4. REGRESSION ANALYSIS: POOLED OLS (Simple Before-After)
# ==============================================================================

cat("\n=== POOLED OLS MODELS ===\n\n")

# THE KEY CHANGE: Remove ESG from independent variables!
# We test if outcomes changed after NFRD, controlling for firm characteristics
# NOT testing if ESG-outcome relationship changed

# H1: Board Size (count data → Poisson regression)
model_bs_ols <- glm(Board_size ~ nfrd + CEO + Employee + age, 
                    data = data_clean, 
                    family = poisson(link = "log"))

# H2: Board Independence (continuous → linear regression)
model_bi_ols <- lm(Board_independent ~ nfrd + CEO + Employee + age, 
                   data = data_clean)

# H3: Gender Diversity (continuous → linear regression)
model_gd_ols <- lm(Gender_diversity ~ nfrd + CEO + Employee + age, 
                   data = data_clean)

# H4: CSR Committee (binary → logistic regression)
model_csr_ols <- glm(CSR ~ nfrd + CEO + Employee + age, 
                     data = data_clean, 
                     family = binomial(link = "logit"))

# Display summaries
cat("\n--- Board Size (Poisson) ---\n")
print(summary(model_bs_ols))

cat("\n--- Board Independence (OLS) ---\n")
print(summary(model_bi_ols))

cat("\n--- Gender Diversity (OLS) ---\n")
print(summary(model_gd_ols))

cat("\n--- CSR Committee (Logit) ---\n")
print(summary(model_csr_ols))

# ==============================================================================
# 5. FIXED EFFECTS MODELS (Recommended - controls for company-specific factors)
# ==============================================================================

cat("\n\n=== FIXED EFFECTS MODELS ===\n\n")

# Convert to panel data format
pdata <- pdata.frame(data_clean, index = c("Name", "year"))

# Fixed effects models
# These compare each company to ITSELF before vs after
# Controls for time-invariant company characteristics (industry, culture, etc.)

# H1: Board Size
model_bs_fe <- plm(Board_size ~ nfrd + Employee + age, 
                   data = pdata, 
                   model = "within",
                   effect = "individual")

# H2: Board Independence
model_bi_fe <- plm(Board_independent ~ nfrd + Employee + age, 
                   data = pdata, 
                   model = "within",
                   effect = "individual")

# H3: Gender Diversity
model_gd_fe <- plm(Gender_diversity ~ nfrd + Employee + age, 
                   data = pdata, 
                   model = "within",
                   effect = "individual")

# H4: CSR Committee (linear probability model for simplicity)
model_csr_fe <- plm(CSR ~ nfrd + Employee + age, 
                    data = pdata, 
                    model = "within",
                    effect = "individual")

# Display results
cat("\n--- Board Size (FE) ---\n")
print(summary(model_bs_fe))

cat("\n--- Board Independence (FE) ---\n")
print(summary(model_bi_fe))

cat("\n--- Gender Diversity (FE) ---\n")
print(summary(model_gd_fe))

cat("\n--- CSR Committee (FE) ---\n")
print(summary(model_csr_fe))

# ==============================================================================
# 6. CREATE SUMMARY TABLES
# ==============================================================================

# Extract key results
summary_results <- tibble(
  Hypothesis = c("H1: Board Size ↑", "H2: Board Independence ↑", 
                 "H3: Gender Diversity ↑", "H4: CSR Committee ↑"),
  Descriptive_Change = round(desc_stats$Change, 2),
  FE_Coefficient = c(
    round(coef(model_bs_fe)["nfrd1"], 3),
    round(coef(model_bi_fe)["nfrd1"], 3),
    round(coef(model_gd_fe)["nfrd1"], 3),
    round(coef(model_csr_fe)["nfrd1"], 3)
  ),
  P_Value = c(
    summary(model_bs_fe)$coefficients["nfrd1", "Pr(>|t|)"],
    summary(model_bi_fe)$coefficients["nfrd1", "Pr(>|t|)"],
    summary(model_gd_fe)$coefficients["nfrd1", "Pr(>|t|)"],
    summary(model_csr_fe)$coefficients["nfrd1", "Pr(>|t|)"]
  ),
  Significant = ifelse(P_Value < 0.001, "***",
                       ifelse(P_Value < 0.01, "**",
                              ifelse(P_Value < 0.05, "*", "n.s."))),
  Supported = c(
    ifelse(P_Value[1] < 0.05 & FE_Coefficient[1] > 0, "Yes ✓", 
           ifelse(P_Value[1] < 0.05, "No (Opposite)", "No (n.s.)")),
    ifelse(P_Value[2] < 0.05 & FE_Coefficient[2] > 0, "Yes ✓", "No"),
    ifelse(P_Value[3] < 0.05 & FE_Coefficient[3] > 0, "Yes ✓", "No"),
    ifelse(P_Value[4] < 0.05 & FE_Coefficient[4] > 0, "Yes ✓", "No")
  )
)

cat("\n\n=== HYPOTHESIS TESTING SUMMARY ===\n\n")
print(summary_results)

# Save summary
write.csv(summary_results, "results/hypothesis_summary.csv", row.names = FALSE)

# ==============================================================================
# 7. CREATE REGRESSION TABLES FOR PAPER
# ==============================================================================

# Save OLS models
stargazer(model_bs_ols, model_bi_ols, model_gd_ols, model_csr_ols,
          type = "text",
          title = "Pooled OLS Results",
          out = "results/ols_models.txt",
          column.labels = c("Board Size", "Independence", "Gender Div", "CSR"),
          covariate.labels = c("NFRD", "CEO Duality", "Employees", "Firm Age"),
          omit.stat = c("f", "ser"))

# Save Fixed Effects models
stargazer(model_bs_fe, model_bi_fe, model_gd_fe, model_csr_fe,
          type = "text",
          title = "Fixed Effects Results",
          out = "results/fe_models.txt",
          column.labels = c("Board Size", "Independence", "Gender Div", "CSR"),
          covariate.labels = c("NFRD", "Employees", "Firm Age"),
          omit.stat = c("f", "ser"))

# ======================================
# 8. VISUALIZATIONS
# ======================================

cat("\n=== CREATING VISUALIZATIONS ===\n\n")

# Figure 1: Before-After Comparison
png("figures/before_after_comparison.png", width = 1200, height = 1000, res = 150)
par(mfrow = c(2, 2), mar = c(5, 5, 3, 2))

# Board Size
barplot(c(desc_stats$Before[1], desc_stats$After[1]),
        names.arg = c("Before", "After"),
        main = "Board Size",
        ylab = "Average Size",
        col = c("#e74c3c", "#3498db"),
        ylim = c(0, max(desc_stats$Before[1], desc_stats$After[1]) * 1.2))
text(0.7, desc_stats$Before[1] + 0.5, round(desc_stats$Before[1], 1), pos = 3, font = 2)
text(1.9, desc_stats$After[1] + 0.5, round(desc_stats$After[1], 1), pos = 3, font = 2)

# Gender Diversity
barplot(c(desc_stats$Before[2], desc_stats$After[2]),
        names.arg = c("Before", "After"),
        main = "Gender Diversity",
        ylab = "Percentage (%)",
        col = c("#e74c3c", "#3498db"),
        ylim = c(0, max(desc_stats$Before[2], desc_stats$After[2]) * 1.2))
text(0.7, desc_stats$Before[2] + 1, round(desc_stats$Before[2], 1), pos = 3, font = 2)
text(1.9, desc_stats$After[2] + 1, round(desc_stats$After[2], 1), pos = 3, font = 2)

# Board Independence
barplot(c(desc_stats$Before[3], desc_stats$After[3]),
        names.arg = c("Before", "After"),
        main = "Board Independence",
        ylab = "Percentage (%)",
        col = c("#e74c3c", "#3498db"),
        ylim = c(0, max(desc_stats$Before[3], desc_stats$After[3]) * 1.2))
text(0.7, desc_stats$Before[3] + 2, round(desc_stats$Before[3], 1), pos = 3, font = 2)
text(1.9, desc_stats$After[3] + 2, round(desc_stats$After[3], 1), pos = 3, font = 2)

# CSR Committee
barplot(c(desc_stats$Before[4], desc_stats$After[4]),
        names.arg = c("Before", "After"),
        main = "CSR Committee Presence",
        ylab = "Percentage (%)",
        col = c("#e74c3c", "#3498db"),
        ylim = c(0, 100))
text(0.7, desc_stats$Before[4] + 3, round(desc_stats$Before[4], 1), pos = 3, font = 2)
text(1.9, desc_stats$After[4] + 3, round(desc_stats$After[4], 1), pos = 3, font = 2)

dev.off()

cat("✓ Saved: figures/before_after_comparison.png\n")

# Figure 2: Time Trends
png("figures/time_trends.png", width = 1400, height = 1000, res = 150)
par(mfrow = c(2, 2), mar = c(5, 5, 3, 2))

# Calculate yearly averages
yearly <- data_clean %>%
  group_by(year) %>%
  summarise(
    board_size = mean(Board_size),
    gender_div = mean(Gender_diversity),
    board_ind = mean(Board_independent),
    csr = mean(CSR) * 100
  )

# Board Size over time
plot(yearly$year, yearly$board_size, type = "l", lwd = 2, col = "#e74c3c",
     main = "Board Size Over Time", xlab = "Year", ylab = "Average Size")
points(yearly$year, yearly$board_size, pch = 19, col = "#e74c3c")
abline(v = 2014, lty = 2, lwd = 2, col = "gray40")
text(2014, max(yearly$board_size) * 0.95, "NFRD\n2014", pos = 4, cex = 0.9)

# Gender Diversity over time
plot(yearly$year, yearly$gender_div, type = "l", lwd = 2, col = "#3498db",
     main = "Gender Diversity Over Time", xlab = "Year", ylab = "Percentage (%)")
points(yearly$year, yearly$gender_div, pch = 19, col = "#3498db")
abline(v = 2014, lty = 2, lwd = 2, col = "gray40")

# Board Independence over time
plot(yearly$year, yearly$board_ind, type = "l", lwd = 2, col = "#2ecc71",
     main = "Board Independence Over Time", xlab = "Year", ylab = "Percentage (%)")
points(yearly$year, yearly$board_ind, pch = 19, col = "#2ecc71")
abline(v = 2014, lty = 2, lwd = 2, col = "gray40")

# CSR over time
plot(yearly$year, yearly$csr, type = "l", lwd = 2, col = "#f39c12",
     main = "CSR Committee Adoption Over Time", xlab = "Year", ylab = "Percentage (%)")
points(yearly$year, yearly$csr, pch = 19, col = "#f39c12")
abline(v = 2014, lty = 2, lwd = 2, col = "gray40")

dev.off()

cat("✓ Saved: figures/time_trends.png\n")

# ==============================================================================
# DONE!
