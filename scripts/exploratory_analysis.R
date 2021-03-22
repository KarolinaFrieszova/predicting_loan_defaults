library(tidyverse)
library(here)
library(ggthemes)

lending_loans <- read_csv(here("clean_data/lending_loans.csv"))

# loan status
loan_status_graph <- lending_loans %>% 
  group_by(loan_status) %>% 
  summarise(count = n()) %>% 
  ggplot(aes (x = loan_status, y = count))+
  geom_col(fill = c("#e41a1c", "#4daf4a"), stat="identity")+
  geom_text(aes(label = count), size = 6, vjust = 1.2, col = "white")+
  labs(title = "Distribution of loans by repayment status",
       y = "Count",
       x = "Loan status (Charged off = False, Paid = True)")+
  theme_economist()

# loan amonut
loan_amount_his <- lending_loans %>% 
  ggplot(aes(x = loan_amnt))+
  geom_histogram(fill = "#377eb8", bins = 30)+
  labs(title = "Distribution of Loan Amount",
       x = "Loan Amount",
       y = "Count")+
  theme_economist()

loan_amount_box <- lending_loans %>% 
  ggplot(aes(x = loan_status, y = loan_amnt))+
  geom_boxplot(fill = c("#e41a1c", "#4daf4a"))+
  coord_flip()+
  labs(title = "Loan Amount by Loan Status",
       x = "Loan Status",
       y = "Loan Amount")+
  theme_economist()

# interest rate
interest_rate_his <- lending_loans %>% 
  ggplot(aes(x = int_rate_pct))+
  geom_histogram(fill = "#377eb8", bins = 30)+
  labs(title = "Distribution of Interest Rate %",
       x = "Interest Rate %",
       y = "Count")+
  theme_economist()

interest_rate_box <- lending_loans %>% 
  ggplot(aes(x = loan_status, y = int_rate_pct))+
  geom_boxplot(fill = c("#e41a1c", "#4daf4a"))+
  coord_flip()+
  labs(title = "Interest Rate % by Loan Status",
       x = "Loan Status",
       y = "Interest Rate %")+
  theme_economist()

# fico range

fico_his <- lending_loans %>% 
  ggplot(aes(x = fico_range_avg))+
  geom_histogram(fill = "#377eb8", bins = 30)+
  labs(title = "Distribution of Average Fico Range",
       x = "Mean Fico Range",
       y = "Count")+
  theme_economist()

fico_box <- lending_loans %>% 
  ggplot(aes(x = loan_status, y = fico_range_avg))+
  geom_boxplot(fill = c("#e41a1c", "#4daf4a"))+
  coord_flip()+
  labs(title = "Avg Fico Range by Loan Status",
       x = "Loan Status",
       y = "Meam Fico Range")+
  theme_economist()

# home ownership

home_ownership_graph <- lending_loans %>% 
  ggplot(aes(x = home_ownership, fill = loan_status))+
  geom_bar()+
  labs(title = "Loan Status by Home Ownership",
       x = "Home Ownership",
       y = "Count",
       fill = "Loan Status")+
  scale_fill_manual(values = c("#e41a1c", "#4daf4a"))+
  theme_economist()

# verification status

ver_status_graph <- lending_loans %>% 
  ggplot(aes(x = verification_status, fill = loan_status))+
  geom_bar()+
  labs(title = "Loan Status by Verification Status",
       x = "Verification Status",
       y = "Count",
       fill = "Loan Status")+
  scale_fill_manual(values = c("#e41a1c", "#4daf4a"))+
  theme_economist()

# purpose

purpose_graph_1 <- lending_loans %>% 
  group_by(purpose) %>% 
  summarise(count = n()) %>% 
  ggplot(aes(x = reorder(purpose, count), y = count))+
  geom_col(fill = "#377eb8")+
  coord_flip()+
  labs(title = "Loans by Purpose",
       y = "Frequency",
       x = "Purpose")+
  theme_economist()

purpose_graph_2 <- lending_loans %>% 
  group_by(purpose, loan_status) %>% 
  summarise(purchase_count = n()) %>% 
  mutate(pct = round(purchase_count * 100 / sum(purchase_count))) %>%
  ggplot(aes(x = purpose, y = pct, fill = loan_status))+
  geom_col()+
  coord_flip()+
  labs(title = "% of Loans by Purpose and Loan Status",
       y = "Frequency",
       x = "Purpose",
       fill = "Fully Paid")+
  scale_fill_manual(values = c("#e41a1c", "#4daf4a"))+
  theme_economist()

# grade

grade_graph_1 <- lending_loans %>% 
  mutate(grade = fct_relevel(grade, "A", "B", "C", "D", "E", "F", "G")) %>% 
  ggplot(aes(x = grade))+
  geom_bar(fill = "#377eb8")+
  labs(title = "Loans by Grade Category",
       y = "Count",
       x = "Grade")+
  theme_economist()

grade_graph_2 <- lending_loans %>% 
  select(grade, loan_status) %>% 
  group_by(grade, loan_status) %>% 
  mutate(grade = fct_relevel(grade, "A", "B", "C", "D", "E", "F", "G")) %>% 
  summarise(grade_count = n()) %>% 
  mutate(pct = round(grade_count * 100 / sum(grade_count))) %>% 
  ggplot(aes(x = grade, y = pct, fill = loan_status))+
  geom_col()+
  labs(title = "Distribution of Loans by Grading System and Loan Status",
       fill = "Fully Paid",
       y = "Percentage",
       x = "Grade")+
  scale_fill_manual(values = c("#e41a1c", "#4daf4a"))+
  theme_economist()


