# load libraries
library(pharmaverseadam)
library(ggplot2)
library(dplyr)
library(tidyr)

# load data 
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

# get population from adsl
adsl_safety <- adsl %>%
  filter(SAFFL == "Y")
n_subjects <- nrow(adsl_safety)

# Plot 1: AE Severity Distribution by Treatment 
severity_plot <- ggplot(adae, aes(x = ACTARM, fill = AESEV)) +
  geom_bar(position = "stack") +
  labs(
    title = "AE Severity Distribution by Treatment",
    x = "Treatment Arm",
    y = "Count of AEs",
    fill = "Severity/Intensity"
  ) +
  theme_minimal()

if(!dir.exists("question_3_tlg")) dir.create("question_3_tlg")
ggsave("question_3_tlg/ae_severity_plot.png", plot = severity_plot, width = 8, height = 6)

# Plot 2: Top 10 Most Frequent AEs with 95% Clopper-Pearson CIs

# Deduplicate to count unique subjects per AE, then calculate CIs
top_10_ae <- adae %>%
  filter(TRTEMFL == "Y") %>%
  distinct(USUBJID, AETERM) %>% 
  count(AETERM) %>%
  slice_max(n, n = 10) %>%
  rowwise() %>% # Compute CI row-by-row
  mutate(
    rate_pct = (n / n_subjects) * 100,
    # binom.test defaults to exact Clopper-Pearson method
    ci_lower = binom.test(n, n_subjects, conf.level = 0.95)$conf.int[1] * 100,
    ci_upper = binom.test(n, n_subjects, conf.level = 0.95)$conf.int[2] * 100
  ) %>%
  ungroup()

# Create the forest-style plot
top10_plot <- ggplot(top_10_ae, aes(x = rate_pct, y = reorder(AETERM, rate_pct))) +
  geom_point(size = 3) +
  # Use geom_errorbar to create the horizontal lines with end caps
  geom_errorbar(aes(xmin = ci_lower, xmax = ci_upper), width = 0.3) +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = sprintf("n = %d subjects; 95%% Clopper-Pearson CIs", n_subjects),
    x = "Percentage of Patients (%)",
    y = NULL # Removes the Y-axis label to match the sample image
  ) +
  # Add the '%' sign to the X-axis ticks
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  theme_minimal() +
  theme(
    panel.grid.minor = element_blank(),
    plot.subtitle = element_text(color = "grey30")
  )

ggsave("question_3_tlg/ae_top10_plot.png", plot = top10_plot, width = 8, height = 6)

# log if successful
writeLines("AE Visualizations created successfully", "question_3_tlg/ae_visuals_log.txt")