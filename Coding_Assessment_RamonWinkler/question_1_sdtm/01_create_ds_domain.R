# Load libraries
library(sdtm.oak)
library(pharmaverseraw) # to assess the raw dataset
library(dplyr) # like pandas
library(readr) # helps read csv files

# Load raw dataset
ds_raw <- pharmaverseraw::ds_raw
#head(ds_raw)

# Load study controlled terminology (study_ct file)
sdtm_ct <- read_csv("Coding_Assessment_RamonWinkler/question_1_sdtm/sdtm_ct.csv") # contains the standardized cdisc terms
#head(sdtm_ct)

# only use the "C66727" that is relevant for the disposition (ds) domain
ds_terms <- sdtm_ct %>% 
  filter(codelist_code == "C66727") 
#head(ds_terms)

# Map raw dataset to the ds domain from SDTM
# Map raw dataset to DS domain
ds <- ds_raw %>%
  # join to get the standardized term
  left_join(ds_terms, by = c("IT.DSTERM" = "collected_value")) %>%
  group_by(PATNUM) %>%
  transmute(
    STUDYID = STUDY,
    DOMAIN = "DS",
    USUBJID = PATNUM,
    DSSEQ = row_number(),
    DSTERM = IT.DSTERM,
    DSDECOD = ifelse(!is.na(term_value), term_value, IT.DSDECOD),
    DSCAT = OTHERSP,
    VISIT = INSTANCE,
    DSDTC = DSDTCOL,
    DSSTDTC = DSDTCOL,
    DSSTDY = as.numeric(as.Date(DSDTCOL, "%d-%m-%Y") - min(as.Date(DSDTCOL, "%d-%m-%Y")) + 1)
  ) %>%
  ungroup()

# save dataset in question 1 folder
write.csv(ds, "Coding_Assessment_RamonWinkler/question_1_sdtm/ds_sdtm.csv", row.names = FALSE)

# Save a log file to confirm it ran
writeLines("DS domain created successfully.", "Coding_Assessment_RamonWinkler/question_1_sdtm/ds_log.txt")

# inspect created file
head(ds)
