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

# remove columns in which stored value is only NA
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
  select(-c(id, member_id, url, desc, # unrequited
            sub_grade, addr_state, # replaced with abbreviation
            tax_liens, # only one different value
            policy_code, # only policy code = 1 or NA, no policy code = 2
            initial_list_status, # False, NA
            collections_12_mths_ex_med, chargeoff_within_12_mths, # 0, NA 
            title, # high correlation with purpose
            emp_title, next_pymnt_d, # high cardinalty and a lot missing 
            zip_code, # high cardinalty
            funded_amnt, funded_amnt_inv, # highly correlated with loan_amount
            pymnt_plan, # only one True value - rest False
            total_pymnt_inv, # highly correlated with total_pymnt
            acc_now_delinq, # 4 rows = 1 all have loan_status = fully paid
            delinq_amnt # 2 rows with loan_status = fully paid
            ))

summary(lending_loans)
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
  select(-c(last_pymnt_d, 
            loan_status, # replaced with abbreviation
            )) %>% 
  rename("addr_state" = "state_name")

write_csv(lending_loans, "clean_data/lending_loans.csv")


# out_prncp, out_prncp_inv, # unrequited

# application_type only individual or NA

lending_loans %>% 
  select(loan_status, pub_rec_bankruptcies) %>% 
  filter(!pub_rec_bankruptcies == 0)