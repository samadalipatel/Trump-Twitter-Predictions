# Trump-Twitter-Predictions
Using ML models to try and predict how popular any given Trump Tweet is going to be. 

Donald Trump, according to himself via Bob Woodward's book Fear, is "the Ernest Hemingway of Twittter." While most certainly not matching Hemingway in wit or intelligence, he is undoubtedly the most famous twitter user of all time. Trump himself studies tweets that do very well to try and take advantage of certain patterns that might improve his future tweets, and so the goal of this project is to see if we can do this via ML. 


I will continuously update this README with information regarding what steps I have taken and what steps I am on, in addition to the dilemmas I face along the way. 


## Part One: Data Collection 

Part one will center all around collecting the data concerning Trump's tweet and twitter account. One option to gather data is to simply download from http://www.trumptwitterarchive.com. However, there are numerous issues with this approach as will be documented in the Part One jupyter notebook. Another is to scrape the tweets using the twitter or tweepy python package, which could be more painstaking but also offer more information to be used for feature engineering. 

Additionally, information from the www.trackalytics.com offers helpful features regarding Trump's followers. 

## Part Two: Data Cleaning

There's not much (if anything) to clean from the trump twitter archive. However, the data collected from trackalytics needs extensive cleaning. This will most likely all be conducted in R. 

I will need to be mindful of how I clean and wrangle my data in R and what preprocessing I conduct in Python, as I will be conducting all the ML there. My plan is to simply create respective scripts to handle each portion and then tie those all into a larger executable file. 
