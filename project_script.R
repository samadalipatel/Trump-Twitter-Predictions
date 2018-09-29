# Load relevant libraries 
library(rvest)
library(dplyr)
library(zoo)
library(stringr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(readr)

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
   str_remove_all(pattern = '\\)') %>% # Replace end parenthesis
   str_remove_all(pattern = '\\+') %>% # Replace + sign
   str_remove_all(pattern = ',') %>%  # Replace commas
   as.numeric()

# Extract number of tweets per day 
tweets_that_day <- str_extract_all(string = df$`Tweets  (change)`, pattern = '(?<=\\().*', 
                   simplify = T) %>% 
   str_remove_all(pattern = '\\)') %>% # Replace end parenthesis
   str_remove_all(pattern = '\\+') %>% as.numeric() # Replace + sign

# Make Date a datetime object
date <- mdy(df$Date)

# Place into df 
follows <- tibble(date, followers, follower_change, tweets_that_day)
colnames(follows) <- c('Date', 'Followers', 'Follower_Change', 'Num_Tweets')

### Merging ### 
tweets <- read_csv('~/Desktop/trump_tweets.csv')
# Remove rows where we don't have favorite_counts
tweets <- tweets %>% filter(!is.na(favorite_count))

# Make dates into datetime
tweets$created_at <- mdy_hm(tweets$created_at)
# Create column for left_join
tweets$Date <- date(tweets$created_at)

# Merge
full_df <- left_join(x = tweets, follows, by = "Date")

exp <- distinct(full_df)
