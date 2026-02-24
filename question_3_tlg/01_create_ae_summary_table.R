# load libraries
library(pharmaverseadam)
library(dplyr)
library(tidyr)    
library(gtsummary)
library(gt)

# get population from adsl
adsl_safety <- pharmaverseadam::adsl %>%
  filter(SAFFL == "Y") %>% 
  select(USUBJID, ACTARM)

# reshape to wide format
teae_soc_wide <- pharmaverseadam::adae %>%
  filter(TRTEMFL == "Y") %>%
  distinct(USUBJID, AESOC) %>%
  mutate(value = "Yes") %>%
  pivot_wider(
    id_cols = USUBJID,
    names_from = AESOC,
    values_from = value,
    values_fill = "No"
  )

# reshape PT (AETERM) to 1 row per patient, 1 column per PT
teae_pt_wide <- pharmaverseadam::adae %>%
  filter(TRTEMFL == "Y") %>%
  distinct(USUBJID, AETERM) %>%
  mutate(value = "Yes") %>%
  pivot_wider(
    id_cols = USUBJID,
    names_from = AETERM,
    values_from = value,
    values_fill = "No"
  )

# merge with adsl
data_soc <- adsl_safety %>%
  left_join(teae_soc_wide, by = "USUBJID") %>%
  mutate(across(-c(USUBJID, ACTARM), ~replace_na(.x, "No"))) %>%# replace_na ensures patients with 0 AEs are marked as "No"
  select(-USUBJID)

data_pt <- adsl_safety %>%
  left_join(teae_pt_wide, by = "USUBJID") %>%
  mutate(across(-c(USUBJID, ACTARM), ~replace_na(.x, "No"))) %>%
  select(-USUBJID)

# create tables
tbl_soc <- data_soc %>%
  tbl_summary(
    by = ACTARM,
    value = list(everything() ~ "Yes"),
    sort = all_categorical() ~ "frequency" # Sort by descending frequency [cite: 176]
  ) %>%
  add_overall(last = FALSE, col_label = "**Total** (N = {N})") 

tbl_pt <- data_pt %>%
  tbl_summary(
    by = ACTARM,
    value = list(everything() ~ "Yes"),
    sort = all_categorical() ~ "frequency" 
  ) %>%
  add_overall(last = FALSE, col_label = "**Total** (N = {N})")

# final table format
ae_table <- tbl_stack(
  list(tbl_soc, tbl_pt),
  group_header = c("Primary System Organ Class", "Reported Term") 
) %>%
  modify_header(label = "**Adverse Event**") %>%
  bold_labels()

# create folder if not existing
if(!dir.exists("question_3_tlg")) dir.create("question_3_tlg")

ae_table %>%
  as_gt() %>%
  # apply gt styling
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_row_groups()
  ) %>%
  gtsave("question_3_tlg/ae_summary_table.html")

# log if successful
writeLines("AE summary table created successfully.", "question_3_tlg/ae_table_log.txt")