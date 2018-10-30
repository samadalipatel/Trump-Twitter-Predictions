# Instructions

To run this code yourself, you must have the following packages: numpy, pandas, pickle, urllib, BeautifulSoup, tweepy, json, nltk, textblob, and sklearn. You will also need to have your own Twitter API keys (a consumer key, consumer secret, access key, and access secret).  


1. Download the entire Final_Product folder (should include fullholidays.csv, training_text.csv, predict_results.py, enet_model). 

2. In your terminal window/command line, navigate to the Final_Product folder and run the predict_results file. 

3. Enter the following arguments: enet_model consumer_key, consumer_secret, access_key, access_secret, num_tweets (where num_tweets represents the number of tweets you want to predict number of likes for - limit 200).


## Example:

    python twitter_model.py enet_model xKasd2fsQVxcmFKq Lt5dBPX0SUWa9asd14ilBqhu421IwoM623Y 101396asd212fvfqKU-SwmZvh9a HN3asdruth2t 15

Please see screenshots for example output. Please note that the screenshot displaying the terminal commands (naturally) has my Twitter authentication details partially redacted. Please also note that recent tweets are likely to have very high errors, as the number of likes won't yet have reached their final values.
