# Load libraries
library(sdtm.oak)
library(pharmaverseraw)
library(dplyr)
library(readr)

# Load raw dataset
ds_raw <- pharmaverseraw::ds_raw

# Load study terminology
sdtm_ct <- read_csv("Coding_Assessment_RamonWinkler/question_1_sdtm/sdtm_ct.csv")

# only use the "C66727" that is relevant for the disposition (ds) domain
ds_terms <- sdtm_ct %>% 
  filter(codelist_code == "C66727") 

# Map raw dataset to the ds domain from SDTM
ds <- ds_raw %>%
  
  # join to get the standardized term
  left_join(ds_terms, by = c("IT.DSTERM" = "collected_value")) %>%
  
  # convert date first for correct ordering
  mutate(DSDATE = as.Date(DSDTCOL, "%m-%d-%Y")) %>%
  
  arrange(PATNUM, DSDATE) %>%
  
  group_by(PATNUM) %>%
  
  transmute(
    STUDYID = STUDY,
    DOMAIN = "DS",
    
    # user id 
    USUBJID = paste(STUDY, PATNUM, sep = "-"),
    
    DSSEQ = row_number(),
    
    DSTERM = IT.DSTERM,
    
    DSDECOD = ifelse(!is.na(term_value), term_value, IT.DSDECOD),
    
    # SDTM category
    DSCAT = "DISPOSITION EVENT",
    
    # ADDED: VISITNUM mapping
    VISITNUM = case_when(
      INSTANCE == "Screening 1" ~ 1,
      INSTANCE == "Baseline"    ~ 2,
      INSTANCE == "Week 2"      ~ 3,
      INSTANCE == "Week 4"      ~ 4,
      INSTANCE == "Week 8"      ~ 5,
      INSTANCE == "Week 12"     ~ 6,
      INSTANCE == "Week 16"     ~ 7,
      INSTANCE == "Week 20"     ~ 8,
      INSTANCE == "Week 24"     ~ 9,
      INSTANCE == "Week 26"     ~ 10,
      INSTANCE == "Retrieval"   ~ 11,
      TRUE ~ NA_real_
    ),
    
    VISIT = INSTANCE,
    
    # Fix date format
    DSDTC = format(DSDATE, "%Y-%m-%d"),
    DSSTDTC = format(DSDATE, "%Y-%m-%d"),
    
    DSSTDY = as.numeric(DSDATE - min(DSDATE, na.rm = TRUE) + 1)
  ) %>%
  
  ungroup()

# save dataset
write.csv(ds,"Coding_Assessment_RamonWinkler/question_1_sdtm/ds_sdtm.csv",row.names = FALSE)

# Save a log file
writeLines("DS domain created successfully.","Coding_Assessment_RamonWinkler/question_1_sdtm/ds_log.txt")

# inspect created file
head(ds)