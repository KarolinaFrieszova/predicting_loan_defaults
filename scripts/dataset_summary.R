library(tidyverse)
library(here)

lending_club_loans <- read_csv(here("raw_data/lending_club_loans.csv"))

num_variables <- ncol(lending_club_loans)
num_rows <- nrow(lending_club_loans)
loan_period <- "2007 - 2011"

lending_club_loans_desc <- lending_club_loans %>% 
  mutate(desc = str_extract(desc,"[^a_]"))

