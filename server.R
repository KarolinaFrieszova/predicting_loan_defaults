library(shiny)
library(shinydashboard)
library(DT)
library(cvms)
library(broom)
library(caTools)
library(janitor)
library(ggthemes)

source(here("scripts/exploratory_analysis.R"))
source(here("scripts/dataset_summary.R"))
source(here("scripts/model_building.R"))
lending_club_loans <- read_csv(here("raw_data/lending_club_loans.csv"))


server <- function(input, output) {
    set.seed(42)
    histdata <- rnorm(500)

    output$num_var <- renderValueBox(
        valueBox(paste0(num_variables), 
                 "Features", icon = icon("info"), color = "light-blue")
    )
    output$num_row <- renderValueBox(
        valueBox(paste0(num_rows), 
                 "Observations", icon = icon("users"), color = "light-blue")
    )
    output$period <- renderValueBox(
        valueBox(paste0(loan_period), 
                 "Period", icon = icon("calendar"), color = "light-blue")
    )
    output$raw_table_output <- DT::renderDataTable(
        lending_club_loans_desc, options = list(pageLength = 3, width="100%", scrollX = TRUE)
    )
    output$clean_table_output <- DT::renderDataTable(
        lending_loans, options = list(pageLength = 5, width="100%", scrollX = TRUE)
    )
    
    output$myList <- renderUI(HTML("<font size = 4><ul>
    <li>Supervised machine learning method (logistic regression algorithm)</li>
    <li>Set and encode lean status as target variable to represent only two possibilities: paid and default loans</li>
    <li>Feature reduction</li>
    <li>Data engineering</li>
    </ul></font>"))
    
    output$loan_amount_1 <- renderPlot(
        loan_amount_his
    )
    
    output$loan_amount_2 <- renderPlot(
        loan_amount_box
    )
    
    output$interest_rate_1 <- renderPlot(
        interest_rate_his
    )
    
    output$interest_rate_2 <- renderPlot(
        interest_rate_box
    )
    
    output$fico_1 <- renderPlot(
        fico_his
    )
    
    output$fico_2 <- renderPlot(
        fico_box
    )
    
    output$grade_1 <- renderPlot(
        grade_graph_1
    )
    
    output$grade_2 <- renderPlot(
        grade_graph_2
    )
    
    output$purpose_1 <- renderPlot(
        purpose_graph_1
    )
    
    output$purpose_2 <- renderPlot(
        purpose_graph_2
    )
    output$ver_status <- renderPlot(
        ver_status_graph
    )
    
    output$home_ownership <- renderPlot(
        home_ownership_graph
    )
    
    output$myList_2 <- renderUI(HTML("<font size = 4><ul>
    <li>Model assumptions: binary dependent variable, no multicollinearity among
    independent variables, observations to be independent from each other</li>
    <li>Conventional 80 to 20 random Train/Test Split</li>
    <li>Automated model selection using glmulti package</li>
    <li>Fit logistic regression model using generalised linear model function</li>
    </ul></font>")
    )
    
    output$cutoff_graph <- renderPlot(
        make_threshold_graph(input$cutoff_select)
    )
    
    output$prediction_table <- DT::renderDataTable(
        test_data_with_predictors, options = list(pageLength = 9)
    )
    
    output$roc_graph_1 <- renderPlot(
        plot(rocr_perf, colorize = T, print.cutoffs.at = seq(0.55,1,0.05), 
             text.adj = c(-0.2, 1.7),
             ylab = "True positive rate (sensitivity)", 
             xlab = "False positive rate (1 - specificity / True negative rate)")
    )
    
    output$roc_graph_2 <- renderPlot(
        plot(rocit_emp, col = c(1,"gray50"),
             legend = FALSE, YIndex = TRUE)
    )
    
    output$cm <- renderPlot(
        con_matrix
    )
    
    output$auc <- renderPlot(
        plot(test_roc,  print.auc = TRUE, 
             percent = TRUE, col = "#377eb8", lwd = 4)
    )
    
    output$feature_importance <- renderPlot(
        ggplot(var_importance)+
            aes(x = reorder(predictor, -overall), y = overall)+
            geom_col(fill = "#377eb8")+
            labs(y = "Relative importance",
                 x = "")+
            theme_economist()+
            theme(axis.text.x=element_text(angle=90, hjust=1))
    )
    
    output$myList_3 <- renderUI(HTML("<font size = 4><ul>
    <li>Better performance at predicting who is likely to pay the loan in the future</li>
    <li>Poor performance at predicting who isn't likely to pay off the loan in the future</li>
    <li>Large type II error / false-negative rate</li>
    <li>Area under the curve 0.70 (generally aiming for 0.80)</li>
    <li>Setback: unbalanced dataset</li>
    <li>Common scenario in the investment and banking sector</li>
    <li>Better performance measure: the ROC curve (true positive rates against false-positive rates)</li>
    </ul></font>")
    )
    
    output$myList_4 <- renderUI(HTML("<font size = 4><ul>
    <li>Applying additional methods such as strategy curve, cost-sensitive learning, under-sampling, over-sampling, or re-training model with newer data</li>
    <li>Also, other methods can be used for classification, for instance Random forest, Neural networks, or Naive Bayes</li>
    </ul></font>")
    )
    
    
}
