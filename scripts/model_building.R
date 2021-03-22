library(tidyverse)
library(here)
library(caTools)
library(modelr)
library(ROCit)
library(cvms)
library(broom)
library(caret)

# read in data
lending_loans <- read_csv(here("clean_data/lending_loans.csv"))

# set seed
set.seed(42)

# test/train splitting
split = sample.split(lending_loans$loan_status, SplitRatio = 0.8)
train = subset(lending_loans, split == TRUE)
test = subset(lending_loans, split == FALSE)

# logistic regression - generalised linear model function
log_reg_model <- glm(loan_status ~ emp_length + purpose + pub_rec_bankruptcies +  
                     annual_inc + inq_last_6mths + revol_bal + int_rate_pct + 
                     revol_util_pct + install_mth_pct + fico_range_avg + term_36, 
                     data = train, family = binomial)

#
test_data_with_predictors <- test %>%
  add_predictions(log_reg_model, type = "response") %>% 
  mutate(pred_thresh_0.5 = pred >= 0.5) %>% 
  mutate(pred_thresh_0.8 = pred >= 0.8) %>% 
  select(loan_status, pred, pred_thresh_0.5, pred_thresh_0.8)

#
cutoff_graph <- test_data_with_predictors %>% 
  pivot_longer(c(pred_thresh_0.5, pred_thresh_0.8, loan_status), 
               names_to = "cutoff",
               values_to = "values")

#
make_threshold_graph <- function(cutoff_select){
  cutoff_graph %>% 
    dplyr::filter(cutoff == cutoff_select) %>% 
    ggplot()+
    aes(x = cutoff, fill = values, group = values)+
    geom_bar(position = "dodge")+
    labs(y = "Count\n",
         x = "\nThreshold")+
    scale_fill_manual(values = c("#e41a1c", "#4daf4a"))+
    geom_text(stat="count", aes(label=..count..), size = 6, vjust = 1.2)+
    theme_economist()
}

#
predict_train = predict(log_reg_model, type = "response")

rocr_pred = ROCR::prediction(predict_train, train$loan_status)
rocr_perf = ROCR::performance(rocr_pred, "tpr", "fpr")

## make the score and class
class <- log_reg_model$y
# score = log odds
score <- qlogis(log_reg_model$fitted.values)
## rocit object
rocit_emp <- rocit(score = score,
                   class = class,
                   method = "emp")

# AUC 
test_prob = predict(log_reg_model, newdata = test, type = "response")
test_roc <- pROC::roc(test$loan_status ~ test_prob)

# confusion matrix
thres_0.85 <- test_data_with_predictors %>%
  mutate(pred_thresh_0.85 = pred >= 0.85)

d_binomial <- tibble("prediction" = thres_0.85$pred_thresh_0.85,
                     "actual" = thres_0.85$loan_status)

basic_table <- table(d_binomial)

cfm <- tidy(basic_table)

con_matrix <- plot_confusion_matrix(cfm, 
                      target_col = "actual", 
                      prediction_col = "prediction",
                      counts_col = "n",
                      add_row_percentages = FALSE,
                      add_col_percentages = FALSE,
                      font_counts = font(size = 4))

# feature replative importance

var_importance <- varImp(log_reg_model, scale = FALSE)

var_importance<- var_importance %>% 
  rownames_to_column(var = "predictor") %>% 
  clean_names()

var_importance <- var_importance %>% 
  arrange(desc(overall)) %>% 
  top_n(13)