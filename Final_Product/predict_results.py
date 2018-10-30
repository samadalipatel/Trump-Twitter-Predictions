# Import necessary packages 
import numpy as np
import pandas as pd
import re
import sys
import pickle
# For scraping
from urllib.request import urlopen
from bs4 import BeautifulSoup
# Twitter scraping
import tweepy 
import json
# Graphs
import matplotlib.pyplot as plt 
import seaborn as sns
# For removing and counting stopwords
from nltk.corpus import stopwords
# For lemmatization 
from textblob import TextBlob
from textblob import Word
# For idf and tf-idf
from sklearn.feature_extraction.text import TfidfVectorizer
import string

class TrumpTwitterPredictions: 
    
    # Initialize class by loading the model 
    def __init__(self, model_file):
        with open(model_file, 'rb') as f: 
            self.model = pickle.load(f)
    
    # Collects data from trackanalytics and twitter - requires Twitter API credentials 
    def CollectData(self, consumer_key, consumer_secret, access_key, access_secret, num_tweets):
        ####################################
        # Collect and Clean Followers Data #
        ####################################
        
        ### COLLECT ###
        # Create and open url 
        url = "https://www.trackalytics.com/twitter/profile/realdonaldtrump/"
        html = urlopen(url)

        # Create BS object 
        soup = BeautifulSoup(html, 'lxml')

        # Find table on this page - only one table, index of 0
        table = soup.findAll('table')[0]

        # Get column names (exist in second row of table)
        colnames = [th.getText() for th in table.findAll('tr', limit=2)[1].findAll('th')]

        # Collect every row with non-header data 
        data_rows = table.findAll('tr')[2:] 

        # For every row, create a list of column data, and append those lists into one large list 
        follower_data = [[td.getText() for td in data_rows[i].findAll('td')] for i in range(len(data_rows))]

        # Create dataframe 
        df = pd.DataFrame(follower_data, columns=colnames, dtype=str)
        
        ### CLEAN ###
        # Remove first column
        df.drop(columns=['id'], inplace=True)

        # Extract number of followers for each date 
        followers = df['Followers  (change)'].apply(lambda x: x.split(' ')[0])
        # Remove commas and change to integer
        followers = followers.str.replace(',', '').astype(int)

        # Extract change for each date
        follower_change = df['Followers  (change)'].apply(lambda x: x.split(' ')[2])
        # Remove parentheses, pluses, minuses, and commas and change to integer
        follower_change = follower_change.str.replace('\\(|\\)|\\+|\\-|\\,', '').astype(int)

        # Extract number of tweets per day
        tweets_that_day = df['Tweets  (change)'].apply(lambda x: x.split(' ')[2])
        # Remove parentheses, pluses, minuses, and commas and change to integer
        tweets_that_day = tweets_that_day.str.replace('\\(|\\)|\\+|\\-|\\,', '').astype(int)

        # Format date
        date = pd.to_datetime(df.Date)

        # Place these features into their own dataframe 
        FollowersData = pd.DataFrame({'Date': date, 'Followers': followers, 'Follower_Change': follower_change, 
                                      'Num_Tweets': tweets_that_day})
        # Change type of Date to integer for merging purposes
        FollowersData.Date = FollowersData.Date.astype(str)
        
        ##################################
        # Collect and Clean Twitter Data #
        ##################################
        
        ### COLLECT ###
        # Twitter API credentials
        con_key = consumer_key
        con_secret = consumer_secret
        acc_key = access_key
        acc_secret = access_secret 
        
        # Authorize twitter, initialize tweepy
        auth = tweepy.OAuthHandler(con_key, con_secret)
        auth.set_access_token(acc_key, acc_secret)
        api = tweepy.API(auth)

        # Collect tweets
        tweets = api.user_timeline(screen_name = 'realDonaldTrump', count = num_tweets,  
                                   tweet_mode = "extended", include_rts = False)

        # Create dataframe with tweet text, date, and favorite count
        TweetsData = pd.DataFrame([[tweet.created_at, tweet.full_text, tweet.favorite_count] for tweet in tweets], 
                         columns = ['created_at', 'text', 'favorite_count'])
        
        ### CLEAN ###
        # Format Date
        TweetsData['Date'] = TweetsData.created_at.dt.strftime('%Y-%m-%d')
        # Change type of Date to integer for merging purposes
        TweetsData.Date = TweetsData.Date.astype(str)
        
        
        #########
        # MERGE #
        #########
        # Merge the two dataframes, return 
        cleaned_df = pd.merge(TweetsData, FollowersData, on='Date', how = 'left')    
        # In case program is run before a trackanalytics update 
        # TODO: Place into if in order to notify user if tweets aren't being shown 
        cleaned_df = cleaned_df.dropna()
        return(cleaned_df)
    
    
    ### Helper functions for feature engineering ###
    # Input: Tweet. Output: Average word length of tweet. 
    def avg_word_length(self, tweet): 
        words = tweet.split()
        if len(words) > 0:
            return(sum(len(word) for word in words) / len(words))
        else: 
            return(0)
        
    # Input: Tweet. Output: Average term-frequency rate     
    def avg_tf_rate(self, tweet):
        # For empty tweets (tweets that were likely just urls), mean tf = 0
        if len(tweet) == 0:
            return(0)
        # For actual tweets, calculate it out 
        else: 
            return(np.mean(pd.value_counts(tweet.split(' '))/len(tweet)))
    
    # Input: tweet, idf_df. Output: Average inverse-document-frequency rate 
    def avg_idf_rate(self, tweet, df):
        # Tokenize the tweet
        tokenized_tweet = tweet.split(' ')
        # Find the idf per word using the idf_df 
        idf_df = df
        idf = idf_df[idf_df.Phrase.isin(tokenized_tweet)].IDF.values
        # Safeguard against empty lists - that means idf = 0
        if len(idf) == 0:
            return(0)
        else: 
            # Otherwise, return the average 
            return(np.mean(idf))


    def EngineerFeatures(self, df): 
        ###################
        # Basic Features #
        ##################
        
        # Create Year, Month, Week, Day, Hour variables 
        df['Year'] = df.created_at.dt.year
        df['Month'] = df.created_at.dt.month
        df['Week'] = df.created_at.dt.week
        df['Day'] = df.created_at.dt.day
        df['Hour'] = df.created_at.dt.hour
        
        # Add holidays feature from full_holidays.csv - read and merge 
        fullholidays = pd.read_csv('fullholidays.csv')
        df = pd.merge(df, fullholidays, on = 'Date', how = 'left')
        # Any non-holiday gets 0 - it will show up as null
        df.iloc[df.Holiday.isnull().index, np.where(df.columns.isin(['Holiday']))[0]] = 0
        
        # Remove urls
        df['trump_text'] = df.text.str.replace(r'http\S+', '')
        
        # Get word count 
        df['Word_Count'] = df.trump_text.apply(lambda x: len(str(x).split(' ')))
        
        # Presence of URLs
        # Create column with all 0s
        df['Any_urls'] = 0
        # Find indices with 0s
        indices_with_urls = df.text.str.extractall(r'(http\S+)').index.get_level_values(0)
        # Make those indices 1
        df.iloc[indices_with_urls, np.where(df.columns.isin(['Any_urls']))[0]] = 1

        # Character count 
        df['Character_Count'] = df.trump_text.str.len()
        
        # Average word length
        df['avg_word_len'] = df.trump_text.apply(self.avg_word_length)
        
        # Count number of stopwords 
        swords = stopwords.words('english')
        df['Num_Stopwords'] = df.trump_text.apply(lambda x: 
                                                  len([word for word in x.split() if word.lower() in swords]))
        
        # Presence of Hashtags
        # Presence 
        indices_with_hashtags = df.trump_text.str.extractall(r'(#)', re.IGNORECASE).index.get_level_values(0)
        # Create an indicator variable, set all to 0 
        df['Any_Hashtags'] = 0
        # Set indices_with_hashtags to 1
        df.iloc[indices_with_hashtags, np.where(df.columns.isin(['Any_Hashtags']))[0]] = 1

        # Number of Hashtags
        df['Num_Hashtags'] = df.trump_text.apply(lambda x: 
                                                 len([word for word in x.split() if word.startswith('#')]))
        
        # Presence of Mentions
        indices_with_mentions = df.trump_text.str.extractall(r'(@)', re.IGNORECASE).index.get_level_values(0)
        # Create indicator variable, set all to 0
        df['Any_Mentions'] = 0
        # Set proper indices to 1
        df.iloc[indices_with_mentions, np.where(df.columns.isin(['Any_Mentions']))[0]] = 1

        # Number of Mentions
        df['Num_Mentions'] = df.trump_text.apply(lambda x: len([word for word in x.split() if word.startswith('#')]))
        
        # Number of Uppercase words Per tweet 
        df['Num_Upper'] = df.trump_text.apply(lambda x: len([word for word in x.split() if word.isupper()]))

        # Presence of Fully Uppercase Tweets 
        df['Upper'] = df.trump_text.str.isupper().astype(int)

        # Number of Exclamation Points
        df['Num_Exclaim'] = df.trump_text.apply(lambda x: len([word for word in x.split() if word.endswith('!')]))

        
        # Presence of Clintons 
        indices_with_clintons = df.trump_text.str.extractall(r'(hillary)|(hillary clinton)|(clinton)|(clintons)|(bill clinton)', 
                                                     re.IGNORECASE).index.get_level_values(0)
        # Create indicator variable, set all to 0
        df['Any_Clinton'] = 0
        # Set proper indices to 1
        df.iloc[indices_with_clintons, np.where(df.columns.isin(['Any_Clinton']))[0]] = 1
        
        
        # Presence of Obama
        indices_with_obama = df.trump_text.str.extractall(r'(obama)|(barrack)', 
                                                             re.IGNORECASE).index.get_level_values(0)
        # Create indicator variable, set all to 0
        df['Any_Obama'] = 0
        # Set proper indices to 1
        df.iloc[indices_with_obama, np.where(df.columns.isin(['Any_Obama']))[0]] = 1

        
        # Presence of MAGA
        indices_with_maga = df.trump_text.str.extractall(r'(MAKE AMERICA GREAT AGAIN)|(MAGA)|(#MAKEAMERICAGREATAGAIN)|(#MAGA)', 
                                                             re.IGNORECASE).index.get_level_values(0)
        # Create indicator variable, set all to 0
        df['Any_MAGA'] = 0
        # Set proper indices to 1
        df.iloc[indices_with_maga, np.where(df.columns.isin(['Any_MAGA']))[0]] = 1       
        
        
        # Presence of Sad/Bad
        indices_with_ad = df.trump_text.str.extractall(r'(sad)|(bad)|(sad!)|(bad!)|(sad.)|(bad.)', 
                                                             re.IGNORECASE).index.get_level_values(0)
        # Create indicator variable, set all to 0
        df['Any_ad'] = 0
        # Set proper indices to 1
        df.iloc[indices_with_ad, np.where(df.columns.isin(['Any_ad']))[0]] = 1
        
        
        # Presence of Democrats
        indices_with_dems = df.trump_text.str.extractall(r'(democrat)|(democratic)|(democrats)|(dems)|(dem)|(dnc)', 
                                                             re.IGNORECASE).index.get_level_values(0)


        # Presence of fake news 
        indices_with_media = df.trump_text.str.extractall(r'(fakenews)|(fake news)|(media)|(fake)|(fakenews!)', 
                                                          re.IGNORECASE).index.get_level_values(0)
        # Create column, set all = 0
        df['FakeNews'] = 0
        # Set those with mentions of fake news = 1
        df.iloc[indices_with_media, np.where(df.columns.isin(['FakeNews']))[0]] = 1


        # Presence of immigration
        indices_mentioning_immigrants = df.trump_text.str.extractall(r'(immigration)|(immigrants)|(border)|(wall)|(buildthewall)|(wall)|(thewall)|(caravan)',
                                                              re.IGNORECASE).index.get_level_values(0)
        # Create column, set all = 0
        df['Any_Immigration'] = 0
        # Set those with mentions of fake news = 1
        df.iloc[indices_mentioning_immigrants, np.where(df.columns.isin(['Any_Immigration']))[0]] = 1
        
        
        # Indices where he says join me
        indices_with_joinme = df.trump_text.str.extractall(r'(join me)|(joining)|(interview)',
                                                              re.IGNORECASE).index.get_level_values(0)

        # Create column, set all = 0
        df['JoinMe'] = 0

        # Set those with mentions = 1
        df.iloc[indices_with_joinme, np.where(df.columns.isin(['JoinMe']))[0]] = 1
        
        
        # Indices with press conferences 
        indices_with_conference = df.trump_text.str.extractall(r'(press conference)|(conference)|(joint)',
                                                              re.IGNORECASE).index.get_level_values(0)

        # Create column, set all = 0
        df['Conference'] = 0

        # Set those with mentions = 1
        df.iloc[indices_with_conference, np.where(df.columns.isin(['Conference']))[0]] = 1

        
        # Indices with issues
        indices_with_rally = df.trump_text.str.extractall(r'(rally)',
                                                              re.IGNORECASE).index.get_level_values(0)

        # Create column, set all = 0
        df['Rally'] = 0

        # Set those with mentions of fake news = 1
        df.iloc[indices_with_rally, np.where(df.columns.isin(['Rally']))[0]] = 1


        # Indices with welcomes
        indices_with_welcomes = df.trump_text.str.extractall(r'(welcome)|(welcoming)',
                                                              re.IGNORECASE).index.get_level_values(0)

        # Create column, set all = 0
        df['Welcomes'] = 0

        # Set those with mentions of fake news = 1
        df.iloc[indices_with_welcomes, np.where(df.columns.isin(['Welcomes']))[0]] = 1
        
        
        # Indices with thank yous
        indices_with_violence = df.trump_text.str.extractall(r'(violence)|(violent)',
                                                              re.IGNORECASE).index.get_level_values(0)

        # Create column, set all = 0
        df['Violence'] = 0

        # Set those with mentions of fake news = 1
        df.iloc[indices_with_violence, np.where(df.columns.isin(['Violence']))[0]] = 1

        ####################
        # Preprocess text #
        ###################
        # Lowercase
        df.trump_text = df.trump_text.str.lower()

        # Remove punctuation
        df.trump_text = df.trump_text.str.replace(pat = '[^\w\s]', repl = '')

        # Remove stopwords
        df.trump_text = df.trump_text.apply(lambda x: ' '.join([word for word in x.split() if word not in swords]))

        # Remove most commonly occuring words 
        freq_words = list(pd.Series(' '.join(df['trump_text']).split()).value_counts()[:10].index)
        df.trump_text = df.trump_text.apply(lambda x: ' '.join([word for word in x.split() if word not in freq_words]))

        # Remove all words that were only used once 
        infreq_words = pd.Series(' '.join(df['trump_text']).split()).value_counts()
        infreq_words = infreq_words[infreq_words.values == 1]
        infreq_words = list(infreq_words.index)
        df.trump_text = df.trump_text.apply(lambda x: ' '.join([word for word in x.split() if word not in infreq_words]))

        # Lemmatize
        df.trump_text = df.trump_text.apply(lambda x: " ".join([Word(word).lemmatize() for word in x.split()]))
        
        
        ###############################
        # Algorithmic Text Processing #
        ###############################
        # TF
        df['tf'] = df.trump_text.apply(lambda x: self.avg_tf_rate(x))
        
        # IDF
        # Create tfidf vectorizer
        vectorizer = TfidfVectorizer(lowercase=True, analyzer='word', ngram_range=(1,1))
        # Load the training text and replace nulls to be empty 
        training_text = pd.read_csv('training_text.csv')
        training_text[training_text.isnull()] = ''
        # Append training text to test text 
        full_text = training_text.trump_text.append(df.trump_text, ignore_index=True)
        # Fit the vocabulary 
        idf_fit = vectorizer.fit(full_text)
        # Use the fit to find idf per phrase - save into a dataframe 
        idf_df = pd.DataFrame({'Phrase': idf_fit.get_feature_names(), 'IDF': idf_fit.idf_})
        # Create column
        df['idf'] = df.trump_text.apply(lambda x: self.avg_idf_rate(x, idf_df))
        
        # TF-IDF
        df['tfidf'] = df.tf * df.idf
        
        # Sentiment
        df['Sentiment'] = df.trump_text.apply(lambda x: TextBlob(x).sentiment[0])

        # Subjectivity 
        df['Subjectivity'] = df.trump_text.apply(lambda x: TextBlob(x).sentiment[1])
        
        # Remove irrelevant columns
        df.drop(columns=['trump_text', 'text', 'created_at', 'Date'], axis = 1, inplace = True)
        
        # Split 
        X = df.drop(columns=['favorite_count'], axis = 1)
        y = df.favorite_count
        
        return(X, y)
    
    # Predict tweets for test data using model.predict method
    def predict(self, X):
        pred = self.model.predict(X)
        # Have to back transform since we're using a BoxCox transformed model 
        pred = pred**(1/0.05777432)
        return(pred)

    # Output a report that includes the tweet, current number of likes, predicted number of likes, and error
    def GenerateReport(self, y_pred, y_true, text):
        report_df = pd.DataFrame({'Tweet': text,
                                  'Predictions': np.ceil(y_pred), 'Current Likes': y_true, 
                                  'Absolute Error': np.abs(np.round(y_pred) - y_true),
                                  'Percent Error': np.round((np.abs((y_pred - y_true)/y_true))*100)})
        return(report_df)

def main(model_file, consumer_key, consumer_secret, access_key, access_secret, num_tweets):
    
    # Initialize model
    tweet_model = TrumpTwitterPredictions(model_file)
    
    print('Gathering data...') 
    # Gather data
    df = tweet_model.CollectData(consumer_key, consumer_secret, access_key, access_secret, num_tweets)

    print('Engineering Features...')
    # Feature Engineering
    X, y = tweet_model.EngineerFeatures(df)
    
    print('Generating predictions...')
    # Predict
    pred = tweet_model.predict(X)

    print('Generating report...') 
    # Generate, display, and output report 
    report_df = tweet_model.GenerateReport(pred, y, df.text.values)
    report_df.to_csv(index=False, header = True, path_or_buf='PredictionReport.csv')
    print(report_df.head(10))
    print('Full report saved to hard drive.')
    print('Note: The actual number of likes is subject to change, and error is likely to be high for new tweets.') 

    
if __name__ == '__main__':
    main( *sys.argv[1:] )
