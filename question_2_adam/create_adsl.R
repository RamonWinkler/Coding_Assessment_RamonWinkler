# Load required libraries
library(dplyr)
library(admiral)
library(pharmaversesdtm)
library(lubridate)

# Input SDTM datasets
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

# onvert blank character to na (recommended in admiral 1.4.1)
dm <- convert_blanks_to_na(dm)
vs <- convert_blanks_to_na(vs)
ex <- convert_blanks_to_na(ex)
ds <- convert_blanks_to_na(ds)
ae <- convert_blanks_to_na(ae)

# create a blank dataset with DM domain as basis
adsl <- dm %>%
  select(STUDYID, USUBJID, SUBJID, AGE, SEX, ARM) %>%
  mutate(
    ITTFL = if_else(!is.na(ARM), "Y", "N") # [cite: 147, 150]
  )

# Age grouping in demanded categories
adsl <- adsl %>%
  mutate(
    AGEGR9 = case_when(
      AGE < 18 ~ "<18",
      AGE <= 50 ~ "18 - 50",
      AGE > 50 ~ ">50"
    ),
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE <= 50 ~ 2,
      AGE > 50 ~ 3
    ) %>% as.integer()
  )

# define a valid exposure as dose > 0 or placebo 
ex_valid <- ex %>%
  filter(EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", EXTRT, ignore.case = TRUE)))

# get first exposure and derive TRTSDTM/TRTSTMF using admiral 
trt_start <- ex_valid %>%
  group_by(USUBJID) %>%
  slice_min(order_by = EXSTDTC, with_ties = FALSE) %>%
  ungroup() %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "TRTS",
    highest_imputation = "h",        
    date_imputation = "first"
  ) %>%
  select(USUBJID, TRTSDTM, TRTSTMF)

# merge with ADSL
adsl <- adsl %>% left_join(trt_start, by = "USUBJID")

# define the last known alive date (LSTAVLDT) sources

# last VS date with valid result
vs_dates <- vs %>%
  filter(!is.na(VSSTRESN) | !is.na(VSSTRESC), !is.na(VSDTC)) %>%
  derive_vars_dt(dtc = VSDTC, new_vars_prefix = "LSTVS") %>% # Using derive_vars_dt instead of convert_dtc
  group_by(USUBJID) %>%
  summarise(LSTVS = max(LSTVSDT, na.rm = TRUE), .groups = "drop")

# 2. Last AE onset date
ae_dates <- ae %>%
  filter(!is.na(AESTDTC)) %>%
  derive_vars_dt(dtc = AESTDTC, new_vars_prefix = "LSTAE") %>%
  group_by(USUBJID) %>%
  summarise(LSTAE = max(LSTAEDT, na.rm = TRUE), .groups = "drop")

# last disposition date 
ds_dates <- ds %>%
  filter(!is.na(DSSTDTC)) %>%
  derive_vars_dt(dtc = DSSTDTC, new_vars_prefix = "LSTDS") %>%
  group_by(USUBJID) %>%
  summarise(LSTDS = max(LSTDSDT, na.rm = TRUE), .groups = "drop")

# last exposure date
ex_dates <- adsl %>%
  select(USUBJID, TRTSDTM) %>%
  mutate(LSTEX = date(TRTSDTM))

# combine all sources and take maximum date 
last_alive <- vs_dates %>%
  full_join(ae_dates, by = "USUBJID") %>%
  full_join(ds_dates, by = "USUBJID") %>%
  full_join(ex_dates, by = "USUBJID") %>%
  rowwise() %>%
  mutate(
    LSTAVLDT = max(c(LSTVS, LSTAE, LSTDS, LSTEX), na.rm = TRUE)
  ) %>%
  mutate(LSTAVLDT = if_else(is.infinite(as.numeric(LSTAVLDT)), as.Date(NA), LSTAVLDT)) %>%
  ungroup() %>%
  select(USUBJID, LSTAVLDT)

# merge last alive into ADSL
adsl <- adsl %>% left_join(last_alive, by = "USUBJID")

# create folder if it doesn't exist
if (!dir.exists("question_2_adam")) {
  dir.create("question_2_adam")
}

# dave ADSL dataset and log
write.csv(adsl, "question_2_adam/adsl.csv", row.names = FALSE)
writeLines("ADSL dataset created successfully.", "question_2_adam/adsl_log.txt")