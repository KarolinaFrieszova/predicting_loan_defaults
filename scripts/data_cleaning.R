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
  select(-c(id, member_id, url, desc, last_pymnt_d, last_pymnt_amnt, last_credit_pull_d, # unrequited
            sub_grade, addr_state, # replaced with abbreviation
            tax_liens, # only one different value
            policy_code, # only policy code = 1 or NA, no policy code = 2
            initial_list_status, # False, NA
            collections_12_mths_ex_med, chargeoff_within_12_mths, # 0, NA 
            title, # high correlation with purpose
            emp_title, next_pymnt_d, # high cardinalty and a lot missing 
            zip_code, earliest_cr_line, # high cardinalty, not required
            funded_amnt, funded_amnt_inv, # highly correlated with loan_amount
            pymnt_plan, # only one True value - rest False
            total_pymnt_inv, # highly correlated with total_pymnt
            acc_now_delinq, # 4 rows = 1 all have loan_status = fully paid
            delinq_amnt, # 2 rows with loan_status = fully paid
            application_type, # all applications are individual
            fico_range_low, # highly correlated with fico_range_high
            mths_since_last_delinq, # 63.3 % missing values
            mths_since_last_record, # 91.4% missing vales
            out_prncp_inv, # highly correlated with out_prncp
            last_fico_range_low # highly correlated with last_fico_range_high
            )) %>% 
  drop_na(open_acc) # remove 32 rows as this rows are missing across multiple columns

# feature engineering
lending_loans <- lending_loans %>% 
  mutate(default_loan = case_when(loan_status == "Fully Paid" ~ 0,
                                  loan_status == "Current" ~ 0,
                                  loan_status == "Does not meet the credit policy. Status:Fully Paid" ~ 0,
                                  loan_status == "Charged Off" ~ 1,
                                  loan_status == "In Grace Period" ~ 1,
                                  loan_status == "Late (31-120 days)" ~ 1,
                                  loan_status == "Late (16-30 days)" ~ 1,
                                  loan_status == "Default" ~ 1,
                                  loan_status == "Does not meet the credit policy. Status:Charged Off" ~ 1
                                  )) %>% # abstraction: loan status normal = 0, default = 1
  select(-loan_status) %>% 
  rename("addr_state" = "state_name") %>% 
  mutate(delinq_2yrs = ifelse(delinq_2yrs == 0, 0, 1), # past-due incidences of delinquency in the borrower's credit file for the past two years
         inq_last_6mths  = ifelse(inq_last_6mths == 0, 0, 1),
         pub_rec = ifelse(pub_rec == 0, 0, 1), # derogatory public records, no = 0, yes = 1
         out_prncp = ifelse(out_prncp == 0, 0, 1), # Remaining outstanding principal for total amount funded, no = 0, yes = 1
         total_rec_late_fee = ifelse(total_rec_late_fee == 0, 0, 1), # Late fees received to date, no = 0, yes = 1
         recoveries = ifelse(recoveries == 0, 0, 1), # post charge off gross recovery, no = 0, yes = 1
         collection_recovery_fee = ifelse(collection_recovery_fee == 0, 0, 1), # post charge off collection fee, no = 0, yes = 1
         int_rate = str_remove_all(int_rate, "[%]"),
         int_rate = as.numeric(int_rate), # convert interest rate to numeric
         issue_d = str_remove_all(issue_d, "[0-9-]"), # remove year, leave month
         issue_d = case_when(issue_d %in% c("Jan", "Feb", "Mar") ~ "Q1",
                             issue_d %in% c("Apr", "May", "Jun") ~ "Q2",
                             issue_d %in% c("Jul", "Aug", "Sep") ~ "Q3",
                             issue_d %in% c("Oct", "Nov", "Dec") ~ "Q4"),
         emp_length = recode(emp_length, "n/a" = "unknown"),
         revol_util = str_remove_all(revol_util, "[%]"), # the amount of credit the borrower is using relative to all available revolving credit
         revol_util = as.numeric(revol_util), # convert to numeric
         revol_util = coalesce(revol_util, median(revol_util, na.rm = TRUE)), # replace missing values with median
         pub_rec_bankruptcies = as.character(pub_rec_bankruptcies),
         pub_rec_bankruptcies = case_when(pub_rec_bankruptcies == "0" ~ "no", 
                                          pub_rec_bankruptcies == "1" ~ "yes",
                                          pub_rec_bankruptcies == "2" ~ "yes", 
                                          TRUE ~ "unknown"), # public record bankruptcies
         install_mth_perc = round((installment * 100) / (annual_inc/12), 2), # monthly expense %
         )

write_csv(lending_loans, "clean_data/lending_loans.csv")
