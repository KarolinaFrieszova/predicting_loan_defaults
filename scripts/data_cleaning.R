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
lending_loans <- lending_club_loans %>% 
  mutate(default_loan = case_when(loan_status == "Fully Paid" ~ 0,
                                  loan_status == "Current" ~ 0,
                                  loan_status == "Does not meet the credit policy. Status:Fully Paid" ~ 0,
                                  loan_status == "Charged Off" ~ 1,
                                  loan_status == "In Grace Period" ~ 1,
                                  loan_status == "Late (31-120 days)" ~ 1,
                                  loan_status == "Late (16-30 days)" ~ 1,
                                  loan_status == "Default" ~ 1,
                                  loan_status == "Does not meet the credit policy. Status:Charged Off" ~ 1
                                  )) %>% 
  drop_na(open_acc) %>% # drop missing values - 29 rows in seven columns
  select(-c(id, member_id, sub_grade, addr_state, loan_status, url, decs,
            funded_amnt_inv, pymnt_plan, desc, initial_list_status,
            last_pymnt_d, next_pymnt_d)) %>% 
  rename("addr_state" = "state_name")

write_csv(lending_loans, "clean_data/lending_club_loans.csv")

unique(lending_club_loans$initial_list_status)



