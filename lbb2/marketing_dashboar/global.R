library(shiny)
library(shinydashboard)
library(tidyverse)
library(lubridate)
library(scales)
library(echarts4r)
library(highcharter)
library(htmlwidgets)
library(magrittr)
library(glue)

# Data Preparation
marketing <- read.csv("marketing_data.csv")

marketing$Income <- parse_number(marketing$Income)
marketing$Dt_Customer <- mdy(marketing$Dt_Customer)

marketing$Education[marketing$Education == "Graduation"] <- "Undergraduate"
marketing$Education[marketing$Education == "2n Cycle"] <- "Master"

status <- c("YOLO", "Alone", "Absurd")
marketing$Marital_Status[marketing$Marital_Status %in% status] <- "Single"

marketing <- marketing %>%
  mutate_if(is.character, as.factor)

average_income <- aggregate(Income ~ Education + Marital_Status, data=marketing, FUN=mean)

imputed_data <- left_join(marketing[is.na(marketing$Income),],
                          average_income,
                          by = c("Education", "Marital_Status"))

imputed_data$Income.x <- imputed_data$Income.y
imputed_data <- imputed_data %>% select(-Income.y)
colnames(imputed_data)[5] <- "Income"

marketing <- full_join(marketing,
                       imputed_data,
                       by = c('ID',
                              'Year_Birth',
                              'Education',
                              'Marital_Status',
                              'Kidhome',
                              'Teenhome',
                              'Dt_Customer',
                              'Recency',
                              'MntWines',
                              'MntFruits',
                              'MntMeatProducts',
                              'MntFishProducts',
                              'MntSweetProducts',
                              'MntGoldProds',
                              'NumDealsPurchases',
                              'NumWebPurchases',
                              'NumCatalogPurchases',
                              'NumStorePurchases',
                              'NumWebVisitsMonth',
                              'AcceptedCmp3',
                              'AcceptedCmp4',
                              'AcceptedCmp5',
                              'AcceptedCmp1',
                              'AcceptedCmp2',
                              'Response',
                              'Complain',
                              'Country'))
marketing <- marketing  %>%
  mutate(Income = coalesce(Income.x, Income.y)) %>%
  select(-c("Income.x", "Income.y"))

marketing <- marketing %>% 
  mutate(Age = as.integer(format(Sys.Date(), "%Y")) - Year_Birth)

convert_age <- function(age){ 
  if(age > 54){
    age <- ">= Baby Boomer" 
  }else if(age >38){
    age <- "Gen X"
  }else if (age > 18){
    age <- "Gen Y"
  } else {
    age <- "Gen Z"
  }
}

marketing$Era <- sapply(X = marketing$Age, 
                        FUN = convert_age) 
marketing$Era <- as.factor(marketing$Era)
convert_country <- function(country) {
  if (country == "AUS") {
    country <- "Australia"
  } else if (country == "CA") {
    country <- "Canada"
  } else if (country == "GER") {
    country <- "Germany"
  } else if (country == "IND") {
    country <- "Indonesia"
  } else if (country == "ME") {
    country <- "Mexico"
  } else if (country == "SA") {
    country <- "Saudi Arabia"
  } else if (country == "SP") {
    country <- "Spain"
  } else if (country == "US") {
    country <- "United States"
  } else {
    country <- "Unknown"
  }
}

marketing$CountryName <- sapply(X = marketing$Country, 
                                FUN = convert_country)
marketing$CountryName <- as.factor(marketing$CountryName)

marketing <- marketing %>% 
  mutate(DayEnroll = wday(Dt_Customer, label = T, abbr = F),
         MonthEnroll = month(Dt_Customer, label = T, abbr = F),
         YearEnroll = year(Dt_Customer),
         DayEnroll = as.character(DayEnroll),
         MonthEnroll = as.character(MonthEnroll),
         YearEnroll = as.factor(YearEnroll))

source("ui.R")
source("server.R")
shinyApp(ui, server)