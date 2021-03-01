library(tidyverse)
library(here)
library(janitor)

# read in data
grade_info <- read_csv(here("raw_data/grade_info.csv"))
lcd_dictionary <- read_csv(here("raw_data/LCDataDictionary.csv")) %>% 
  clean_names()
lending_club_loans <- read_csv(here("raw_data/lending_club_loans.csv"))
state_names <- read_csv(here("raw_data/state_names_info.csv"))

# add seven loan classifiers which indicate different levels of risk and corresponding returns
lending_club_loans <- left_join(lending_club_loans, grade_info, by = "sub_grade")

# add state names
lending_club_loans <- left_join(lending_club_loans, state_names, 
                                by = c("addr_state" = "state_abb"))

# remove data-sets
rm(grade_info, state_names)

# feature abstraction: loan status normal = 0, default = 1
lending_club_loans <- lending_club_loans %>% 
  mutate(default_status = case_when(loan_status == "Fully Paid" ~ 0,
                                    loan_status == "Current" ~ 0,
                                    loan_status == "Does not meet the credit policy. Status:Fully Paid" ~ 0,
                                    loan_status == "Charged Off" ~ 1,
                                    loan_status == "In Grace Period" ~ 1,
                                    loan_status == "Late (31-120 days)" ~ 1,
                                    loan_status == "Late (16-30 days)" ~ 1,
                                    loan_status == "Default" ~ 1,
                                    loan_status == "Does not meet the credit policy. Status:Charged Off" ~ 1
                                    )) %>% 
  drop_na(open_acc) %>% 

# there is exactly 29 rows missing in seven columns so we will drop them 
lending_club_loans <- lending_club_loans %>% 
  drop_na(open_acc)



