# Load libraries
library(dplyr)
library(admiral)
library(pharmaversesdtm)
library(lubridate)

# input datasets
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

# covert blank to na as suggested in documentation (admiral 1.4.1)
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
lb <- convert_blanks_to_na(lb)

# create a blank dataset with DM domain as basis
adsl <- dm %>%
  select(STUDYID, USUBJID, SUBJID = SUBJID, AGE, SEX, ARM) %>%
  mutate(ITTFL = if_else(!is.na(ARM), "Y", "N"))

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
    )
  )

# Filter valid doses
ex_valid <- ex %>%
  filter(EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", EXTRT, ignore.case = TRUE))) %>%
  arrange(USUBJID, as_datetime(EXSTDTC))

# First exposure per subject
trt_start <- ex_valid %>%
  group_by(USUBJID) %>%
  slice_min(order_by = as_datetime(EXSTDTC), with_ties = FALSE) %>%
  mutate(
    TRTSDTM = as_datetime(EXSTDTC),  # convert to datetime
    TRTSTMF = if_else(is.na(hour(TRTSDTM)) | is.na(minute(TRTSDTM)), TRUE, FALSE)
  ) %>%
  select(USUBJID, TRTSDTM, TRTSTMF)

# Merge with ADSL
adsl <- adsl %>% left_join(trt_start, by = "USUBJID")

# Last VS date with valid result
vs_dates <- vs %>%
  filter(!is.na(VSSTRESN) | !is.na(VSSTRESC), !is.na(date(VSDTC))) %>%
  group_by(USUBJID) %>%
  summarise(LSTVS = max(date(VSDTC), na.rm = TRUE))

# Parse AE start date
ae_dates <- ae %>%
  filter(!is.na(AESTDTC)) %>%
  mutate(AESTDTC_date = dmy(AESTDTC)) %>%  # adjust dmy/ymd depending on your format
  group_by(USUBJID) %>%
  summarise(LSTAE = max(AESTDTC_date, na.rm = TRUE))

# Last DS date
ds_dates <- ds %>%
  filter(!is.na(DSSTDTC)) %>%
  group_by(USUBJID) %>%
  summarise(LSTDS = max(date(DSSTDTC), na.rm = TRUE))

# Last EX date (first exposure = TRTSDTM)
ex_dates <- trt_start %>%
  mutate(LSTEX = as_date(TRTSDTM)) %>%
  select(USUBJID, LSTEX)

# Combine and take max date
last_alive <- vs_dates %>%
  full_join(ae_dates, by = "USUBJID") %>%
  full_join(ds_dates, by = "USUBJID") %>%
  full_join(ex_dates, by = "USUBJID") %>%
  rowwise() %>%
  mutate(LSTAVLDT = max(c(LSTVS, LSTAE, LSTDS, LSTEX), na.rm = TRUE)) %>%
  select(USUBJID, LSTAVLDT)

# Merge into ADSL
adsl <- adsl %>% left_join(last_alive, by = "USUBJID")

# Create folder if it doesn't exist
if (!dir.exists("question_2_adam")) {
  dir.create("question_2_adam")
}

# Save ADSL dataset
write.csv(adsl, "question_2_adam/adsl.csv", row.names = FALSE)

# Save log
writeLines("ADSL dataset created successfully.", "question_2_adam/adsl_log.txt")

