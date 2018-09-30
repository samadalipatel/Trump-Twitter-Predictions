# Load relevant libraries 
library(rvest)
library(dplyr)
library(zoo)
library(stringr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(readr)
library(corrplot)

############################
### PART TWO: COLLECTING ###
############################

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
follows <- distinct(follows)
colnames(follows) <- c('Date', 'Followers', 'Follower_Change', 'Num_Tweets')
# Write to a file 
write.csv(x = follows, file = 'trump_followers_data.csv', row.names = F)

##########################
### PART TWO: CLEANING ###
##########################
# TODO: For markdown file, read in files here 
### Merging ### 
tweets <- read_csv('~/Desktop/trump_tweets.csv')
# Remove rows where we don't have favorite_counts
tweets <- tweets %>% filter(!is.na(favorite_count))
# Remove rows where favorite count is 0
tweets <- tweets %>% filter(favorite_count != 0)

# Make dates into datetime
tweets$created_at <- mdy_hm(tweets$created_at)
# Create column for left_join
tweets$Date <- date(tweets$created_at)

# Merge
df <- left_join(x = tweets, y = follows, by = "Date")
# Merge didn't work out quite as expected - there are more rows than I want. 
# Some tweets are being repeated. Only include unique id_strings
df <- df %>% distinct(id_str, .keep_all = T)

### Cleaning ###
# MISSING DATA - NUM_TWEETS # 
# There are some dates that don't have any followers data 
dates_without_followers <- df[!complete.cases(df), ]$Date %>% unique()
# Number of Tweets will be easy - sum up unique ids for each given date 
imputed_num_tweets <- df %>% group_by(Date) %>% summarize('Tweets' = n()) %>% 
   filter(Date %in% dates_without_followers)

# Place those values into their proper place in df
# Convoluted, but gets the job done 
df <- left_join(df, imputed_num_tweets, 'Date')
df[!is.na(df$Tweets),'Num_Tweets'] <- df[!is.na(df$Tweets),'Tweets']
# Remove Tweets variable
df <- df %>% select(-Tweets)



# MISSING DATA - FOLLOWERS CHANGE # 
# What's the density of the change of followers? 
# ggplot(df) + geom_density(aes(Follower_Change), colour = 'white') + 
#    theme_solarized(light = FALSE)
# 
# # What does it look like over time? 
# ggplot(df) + geom_line(aes(Date, Follower_Change), colour = 'white') + 
#    theme_solarized(light = FALSE)
# 
# # Will impute with the average change in followers that week 
# week(dates_without_followers)
# year(dates_without_followers)
# 
# # Dataframe with 
# change <- df %>% group_by('Week' = week(df$Date), 'Year' = year(df$Date)) %>% 
#    summarise('Change' = mean(Follower_Change, na.rm = TRUE))
# change %>% filter(Week %in% week(dates_without_followers), 
#                   Year %in% year(dates_without_followers))
# # Empty vector to append to
# relevant_changes <- c()
# # Loop to extract relevant values from change
# for (i in 1:length(dates_without_followers)){
#    to_append <- change %>% filter(Week == week(dates_without_followers[i]), 
#                                   Year == year(dates_without_followers[i]))
#    relevant_changes <- append(relevant_changes, to_append[3][[1]])
# }
# 
# # Throw values into a dataframe 
# change <- tibble('Date' = dates_without_followers, relevant_changes)
# 
# # Place those values into their proper place in df
# df <- left_join(df, change, 'Date')
# df[!is.na(df$relevant_changes),'Follower_Change'] <- df[!is.na(df$relevant_changes),'relevant_changes']
# # Remove Tweets variable
# df <- df %>% select(-relevant_changes)

# Everything above is irrelevant now. 
# Just divide total change between a gap by number of days in gap.
delta1 <- df[df$Date == '2017-03-21', 'Follower_Change'] %>% unique() %>% as.numeric() / 5
delta2 <- df[df$Date == '2016-07-06', 'Follower_Change'] %>% unique() %>% as.numeric() / 4

# Since we must change the dates at end of gaps, throw those into relevant_dates 
relevant_dates <- append(dates_without_followers, date('2017-03-21'), after = 0)
relevant_dates <- append(relevant_dates, date('2016-07-06'), after = 5)
# Create df
change <- tibble('Date' = relevant_dates, 'relevant_changes' = c(rep(delta1, 5), rep(delta2, 4)))
# Place those values into their proper place in df
df <- left_join(df, change, 'Date')
df[!is.na(df$relevant_changes),'Follower_Change'] <- df[!is.na(df$relevant_changes),'relevant_changes']
# Remove Tweets variable
df <- df %>% select(-relevant_changes)



# MISSING DATA - FOLLOWERS #
# The idea here is simple - add the previous followers to the next followers_change 

# For each date
for (i in 1:(length(relevant_dates) - 1)){
   # If the followers for the previous date is missing 
   if (is.na(df[df$Date == relevant_dates[i+1], 'Followers'] %>% unique() %>% as.numeric())){
      # Fill those NA vals with the Followers from date i - Followers_Change for date i 
      # Followers from date i 
      old_follows <- df[df$Date == relevant_dates[i], 'Followers'] %>% unique() %>% as.numeric()
      # Followers change for date i 
      old_change <- df[df$Date == relevant_dates[i], 'Follower_Change'] %>% unique() %>% as.numeric() 
      # Change df 
      df[df$Date == relevant_dates[i+1], 'Followers'] <- old_follows - old_change
   }
}

# Just in case I fuck up later 
df_copy <- df 
x <- df$source
# SPARSE CLASSES #
# I want to see the sources of Trump's tweets
sort(prop.table(table(df$source))*100, decreasing = TRUE)
# 95% come from 3 sources; everything else should become other 
# The following code gives me what I need to copy and paste into car::recode
paste('\'', names(sort(table(df$source), decreasing = T)[4:14]), '\'', sep = '') %>% toString()
# Recode
df$source <- car::recode(x, "c('Media Studio', 'Twitter Ads', 'Twitter for iPad', 'Instagram', 
                         'Twitter for BlackBerry', 'Twitter QandA', 'Periscope', 'Facebook', 
                         'TweetDeck', 'Mobile Web (M5)', 'Twitter Mirror for iPad') = 'Other'")

plot_table <- df %>% group_by(source) %>% summarize('ave' = min(favorite_count))
ggplot(plot_table) + geom_bar(aes(source, ave), stat = 'identity')



# DATE AND TIME 
df$Year <- year(df$created_at)
df$Month <- month(df$created_at)
df$Week <- week(df$created_at)
df$Hour <- hour(df$created_at)



# DELETING VARIABLES
df <- df %>% select(-which(colnames(df) %in% c('created_at', 'is_retweet', 'id_str', 'Date')))

m1 <- lm(favorite_count~Followers+Follower_Change+Num_Tweets+Month+Hour, data = df)
summary(m1)
plot(m1)
lambda <- powerTransform(m1)$lambda
m2 <- lm(favorite_count^lambda~Followers+Follower_Change+Num_Tweets+Month+Hour, data = df)
summary(m2)
plot(m2)
# Wow, m2 is surprisingly good. Check collinearity 
cor_df <- cor(df[,c(5:11)])
corrplot(cor_df)

library(MASS)
library(car)
vif(m2)
