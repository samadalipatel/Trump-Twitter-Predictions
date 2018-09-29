# Load relevant libraries 
library(rvest)
library(dplyr)
library(zoo)
library(stringr)
library(lubridate)

### Load the data into a dataframe ### 
url <- 'https://www.trackalytics.com/twitter/profile/realdonaldtrump/'
page <- read_html(url)
data <- page %>% html_nodes('#summary') %>% html_table(fill = T)
df <- data[[1]]

### Clean Data ### 
# Column names are the first row; remove first column
colnames(df) <- df[1,]
df <- df[-1,]

# Extract number of followers for each date 
followers <- str_extract_all(string = df$`Followers  (change)`, pattern = '.*\\s', simplify = T) %>% 
   trimws()
# Remove commas
followers <- str_replace_all(followers, ',', '') %>% as.numeric()
 
# Extract change for each date 
follower_change <- str_extract_all(string = df$`Followers  (change)`, pattern = '(?<=\\().*', 
                          simplify = T) %>% 
   str_replace_all(pattern = '\\)', replacement = '') %>% # Replace end parenthesis
   str_replace_all(pattern = '\\+', replacement = '') %>% # Replace + sign
   str_replace_all(pattern = ',', replacement = '') %>%  # Replace commas
   as.numeric()

# Make Date a datetime object
date <- mdy(df$Date)