library(shiny)
library(shinydashboard)
library(here)
library(tidyverse)
    
ui <- dashboardPage(
    dashboardHeader(title = "Pedicting loan defaults"),
    dashboardSidebar(
        sidebarMenu(
            tags$style(HTML(".sidebar-menu li a { font-size: 18px; }")),
            menuItem("About", tabName = "about"),
            menuItem("Introduction", tabName = "introduction"),
            menuItem("Data Preparation", tabName = "preparation"),
            menuItem("Exploratory Analysis", tabName = "analysis"),
            menuItem("Model Building", tabName = "model"),
            menuItem("Evaluation", tabName = "evaluation"),
            menuItem("Conclusion", tabName = "conclusion")
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(tabName = "about",
                    h2(tags$b("Welcome!"), align = "center", style = "color:#484848"),
                    br(),
                    br(),
                    p("Name: Karolina Frieszova", 
                      style = "font-size:20px"),
                    br(),
                    p("Position: Data Analyst, CodeClan graduate", 
                      style = "font-size:20px"),
                    br(),
                    p("Project involves: data cleaning, data visualisation, dashboard building, machine learning",
                      style = "font-size:20px"),
                    br(),
                    p("Language: R",
                      style = "font-size:20px")
                    
            ),
            tabItem(tabName = "introduction",
                    h2(tags$b("Introduction"), align = "center", style = "color:#484848"),
                    h3(tags$b("Aim of the project"), style = "color:#377eb8"),
                    p("The project aimed to develop a predictive machine learning model on 
                      data provided by an online loan provider called LendingClub 
                      to improve their understanding and risk assessment of who 
                      they should lend to and who is likely to default in the future.",
                      style = "font-size:20px"),
                    h3(tags$b("Business description"), style = "color:#377eb8"),
                    p("LendingClub is an American peer-to-peer lending company where borrowers
                      submit their applications and individual lenders select those that they 
                      want to fund based on the information supplied about the borrower.",
                      style = "font-size:20px"),
                    h3(tags$b("Business problem"), style = "color:#377eb8"),
                    p("This online lending platform has brought opportunities to investors. 
                      But at the same time, they are also faced with the risk of user loan default, 
                      which is related to the sustainable and healthy development of LendingClub's 
                      platform. Investors want to maximise their profit and minimise their risk. 
                      They want to avoid funding loan to someone who won't pay them back. Equally, 
                      they do not want to miss the opportunity to lend to someone who would pay back.",
                      style = "font-size:20px"),
                    h3(tags$b("Dataset"), style = "color:#377eb8"),
                    fluidRow(
                        valueBoxOutput("num_var"),
                        valueBoxOutput("num_row"),
                        valueBoxOutput("period")
                    )
            ),
            tabItem(tabName = "preparation",
                    h2(tags$b("Data Preparation"), align="center", style = "color:#484848"),
                    uiOutput("myList"),
                    fluidRow(
                        box(
                            h4(tags$b("Raw dataset"), style = "color:#377eb8"),
                            DT::dataTableOutput("raw_table_output"), width = 6
                        ),
                        box(
                            h4(tags$b("Clean dataset"), style = "color:#377eb8"),
                            DT::dataTableOutput("clean_table_output"), width = 6
                        )
                    )
            ),
            tabItem(tabName = "analysis",
                    h2(tags$b("Exploratory Analysis"), align = "center", style = "color:#484848"),
                    fluidRow(
                        box(plotOutput("loan_amount_1", height = 250)),
                        box(plotOutput("loan_amount_2", height = 250))
                    ),
                    fluidRow(
                        box(plotOutput("interest_rate_1", height = 250)),
                        box(plotOutput("interest_rate_2", height = 250))
                    ),
                    fluidRow(
                        box(plotOutput("fico_1", height = 250)),
                        box(plotOutput("fico_2", height = 250))
                    ),
                    fluidRow(
                        box(plotOutput("grade_1", height = 250)),
                        box(plotOutput("grade_2", height = 250))
                    ),
                    fluidRow(
                        box(plotOutput("purpose_1", height = 250)),
                        box(plotOutput("purpose_2", height = 250))
                    ),
                    fluidRow(
                        box(plotOutput("home_ownership", height = 250)),
                        box(plotOutput("ver_status", height = 250))
                    )
            ),
            tabItem(tabName = "model",
                    h2(tags$b("Building logistic regression model"), align="center", style = "color:#484848"),
                    uiOutput("myList_2"),
                    fluidRow(
                        box(h4(tags$b("Model's estimated probabilities"), style = "color:#377eb8"),
                            DT::dataTableOutput("prediction_table"), width = 6
                        ),
                        box(h4(tags$b("Threshold probability"), style = "color:#377eb8"),
                            selectInput("cutoff_select", 
                                        "Choose a threshold probability ",
                                        c("threshold 0.5" = "pred_thresh_0.5", 
                                          "threshold 0.8" = "pred_thresh_0.8", 
                                          "actual outcome" = "loan_status")
                                        
                            ),
                            plotOutput("cutoff_graph"), width = 6
                        )
                    ),
                    fluidRow(
                        box(h4(tags$b("Receiver operator characteristic curve"), style = "color:#377eb8"),
                            plotOutput("roc_graph_1"), width = 6
                        ),
                        box(
                            h4(tags$b("Finding optimal threshold - Youden's index method"), style = "color:#377eb8"),
                            plotOutput("roc_graph_2"), width = 6
                        )
                    )
            ),
            tabItem(
                tabName = "evaluation",
                h2(tags$b("Evaluation"), align = "center", style = "color:#484848"),
                fluidRow(
                    box(h3(tags$b("Confusion matrix"), style = "color:#377eb8"),
                        plotOutput("cm"), width = 6
                    ), 
                    box(h3(tags$b("Area under the curve"), style = "color:#377eb8"),
                        plotOutput("auc"), width = 6
                    )
                ),
                fluidRow(
                    box(
                        h3(tags$b("Feature Relative Importance"), style = "color:#377eb8"),
                        plotOutput("feature_importance"), width = 8
                    )
                )
            ),
            tabItem(
                tabName = "conclusion",
                h2(tags$b("Conclusion"), align = "center", style = "color:#484848"),
                h3(tags$b("Findings"), style = "color:#377eb8"),
                uiOutput("myList_3"),
                br(),
                h3(tags$b("Enhancements"), style = "color:#377eb8"),
                uiOutput("myList_4")
            )
        )
    )
)
