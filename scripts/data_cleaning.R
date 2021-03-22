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

# remove columns with 50% plus missing values
lending_loans <- lending_club_loans %>% 
  select(-c(total_il_high_credit_limit, mths_since_last_major_derog, num_bc_tl,
            mths_since_rcnt_il, mths_since_recent_bc, mths_since_recent_bc_dlq, 
            mths_since_recent_inq, mths_since_recent_revol_delinq, total_bc_limit,
            total_bal_ex_mort, tot_hi_cred_lim, percent_bc_gt_75, pct_tl_nvr_dlq, 
            num_tl_120dpd_2m, num_tl_30dpd, num_tl_90g_dpd_24m, num_tl_op_past_12m,
            num_sats, num_rev_tl_bal_gt_0, num_rev_accts, num_op_rev_tl, num_il_tl,
            num_bc_sats, num_actv_rev_tl, num_actv_bc_tl, num_accts_ever_120_pd,
            mort_acc, mo_sin_rcnt_tl, mo_sin_old_il_acct, mo_sin_old_rev_tl_op,
            mo_sin_rcnt_rev_tl_op, bc_util, bc_open_to_buy, avg_cur_bal, 
            acc_open_past_24mths, inq_last_12m, total_cu_tl, total_rev_hi_lim,
            inq_fi, all_util, max_bal_bc, open_rv_24m, open_rv_12m, il_util,
            total_bal_il, open_il_24m, open_il_12m, open_il_6m, open_acc_6m,
            tot_cur_bal, tot_coll_amt, verification_status_joint, dti_joint, 
            annual_inc_joint))

# remove data-sets
rm(grade_info, state_names, lending_club_loans)

# further column reduction
lending_loans <- lending_loans %>% 
  select(-c(id, member_id, url, desc, last_pymnt_d, last_pymnt_amnt, last_credit_pull_d, # unrequited
            sub_grade, addr_state, # replaced with abbreviation
            tax_liens, # only one different value
            policy_code, # only policy code = 1 or NA, no policy code = 2
            initial_list_status, # False, NA
            collections_12_mths_ex_med, chargeoff_within_12_mths, # 0, NA 
            title, # high correlation with purpose
            emp_title, next_pymnt_d, # high cardinalty and a lot missing 
            zip_code, # earliest_cr_line, # high cardinalty, not required
            funded_amnt, funded_amnt_inv, # highly correlated with loan_amount
            pymnt_plan, # only one True value - rest False
            total_pymnt_inv, # highly correlated with total_pymnt
            acc_now_delinq, # 4 rows = 1 all have loan_status = fully paid
            delinq_amnt, # 2 rows with loan_status = fully paid
            application_type, # all applications are individual
            mths_since_last_delinq, # 63.3 % missing values
            mths_since_last_record, # 91.4% missing vales
            out_prncp_inv, # highly correlated with out_prncp
            last_fico_range_low, # highly correlated with last_fico_range_high
            total_rec_prncp # highly correlated with total_pymnt (principal is the amount you borrowed without interest)
  )) %>% 
  drop_na(open_acc) # remove 32 rows as this rows are missing across multiple columns

lending_loans <- lending_loans %>% 
  filter(!loan_status %in% c("Current", "In Grace Period", "Late (31-120 days)", "Late (16-30 days)", "Default")) %>%
  mutate(loan_status = case_when(loan_status == "Fully Paid" ~ T,
                                 loan_status == "Does not meet the credit policy. Status:Fully Paid" ~ T,
                                 loan_status == "Charged Off" ~ F,
                                 loan_status == "Does not meet the credit policy. Status:Charged Off" ~ F
  )) %>% # abstraction: loan status paid = T, charged off = F
  rename("addr_state" = "state_name") %>% 
  mutate(delinq_2yrs = ifelse(delinq_2yrs == 0, F, T), # past-due incidences of delinquency in the borrower's credit file for the past two years
         inq_last_6mths  = ifelse(inq_last_6mths == 0, F, T),
         pub_rec = ifelse(pub_rec == 0, F, T), # derogatory public records
         total_rec_late_fee = ifelse(total_rec_late_fee == 0, F, T), # Late fees received to date
         recoveries = ifelse(recoveries == 0, F, T), # post charge off gross recovery
         collection_recovery_fee = ifelse(collection_recovery_fee == 0, F, T), # post charge off collection fee
         int_rate_pct = str_remove_all(int_rate, "[%]"),
         home_ownership = recode(home_ownership, "NONE" = "OTHER"),
         int_rate_pct = as.numeric(int_rate_pct), # convert interest rate to numeric
         issue_d = str_remove_all(issue_d, "[0-9-]"), # remove year, leave month
         emp_length = case_when(emp_length == "10+ years" ~ "10+ years",
                                emp_length %in% c("9 years", "8 years", "7 years", "6 years") ~ "above 5 years",
                                emp_length %in% c("5 years", "4 years", "3 years", "2 years") ~ "2 - 5 years",
                                emp_length %in% c("1 year", "< 1 year") ~ "1 and under",
                                emp_length == "n/a" ~ "unknown"),
         addr_state = coalesce(addr_state, "unknown"),
         revol_util_pct = str_remove_all(revol_util, "[%]"), # the amount of credit the borrower is using relative to all available revolving credit
         revol_util_pct = as.numeric(revol_util_pct), # convert to numeric
         revol_util_pct = coalesce(revol_util_pct, median(revol_util_pct, na.rm = TRUE)), # replace missing values with median
         pub_rec_bankruptcies = as.character(pub_rec_bankruptcies),
         pub_rec_bankruptcies = case_when(pub_rec_bankruptcies == "0" ~ "no", 
                                          pub_rec_bankruptcies == "1" ~ "yes",
                                          pub_rec_bankruptcies == "2" ~ "yes", 
                                          TRUE ~ "unknown"), # public record bankruptcies
         install_mth_pct = round((installment * 100) / (annual_inc/12), 2), # monthly installment expense %
         fico_range_avg = (fico_range_low + fico_range_high) / 2,
         earliest_cr_line = str_remove_all(earliest_cr_line, "[A-Za-z-]"),
         earliest_cr_line = case_when(earliest_cr_line >= 2000 ~ "00s",
                                      earliest_cr_line >= 1940 ~ "40s-90s",
                                      T ~ "unknown"),
         term_36 = ifelse(term == "36 months", T, F),
         purpose = case_when(purpose %in% c("home_improvement", "house") ~ "house related",
                             purpose %in% c("vacation", "wedding", "car", "major_purchase") ~ "personal",
                             T ~ as.character(purpose)), #  where relevant reduce the amount of variable labels
         purpose = as.factor(purpose)
  ) %>% # if it is not 36, we know it will be 60 months
  mutate_if(is_character, as_factor) %>% 
  select(-c(collection_recovery_fee, int_rate, revol_util, fico_range_low, 
            fico_range_high, addr_state, issue_d, out_prncp, last_fico_range_high, 
            term, recoveries, total_rec_late_fee, installment, total_pymnt, total_rec_int))

rm(lcd_dictionary)

write_csv(lending_loans, "clean_data/lending_loans.csv")
