# Trump-Twitter-Predictions

Donald Trump is is undoubtedly the most famous twitter user of all time. In "Fear: Trump in the White House," Bob Woodward reports that Trump himself studies tweets that do very well to try and take advantage of certain patterns that might improve his future tweets. The goal of this project is to see if we can do this via ML. 

## Part One: Data Collection 

Training data is collected from http://www.trumptwitterarchive.com. Data concerning Trump's followers is collected from www.trackalytics.com. Testing data is acquired via the Twitter API, and thus, running this program requires the user to have their own Twitter API credentials. I chose to use Trump's tweets from 2017 and 2018 as the basis to predict his future number of likes, as 2016 and prior aren't great representations for the future. 

## Part Two: Data Cleaning
The data from trackalytics requires some basic cleaning. I utilized the Twitter API to remove any deleted tweets from my training set. 

## Part Three: Feature Engineering
Feature engineering focused heavily on Natural Language Processing techniques, as well as having insight into Trump's general behavior and mannerisms. 

## Part Four: Machine Learning
Six models were considered - OLS, LASSO, Ridge, and Elastic Net Linear Regression, as well as Random Forest and Gradient Boosted Trees. Linear Models actually outperformed all tree-based models here. I took great concern to be sure that the data met the assumptions for linear models, and they surprisingly did. 

## Conclusions
In the end, I selected a BoxCox Transformed Elastic Net model - it had the second lowest mean absolute error rate with the highest R^2 value. 

In the end, the model wasn't revolutionarily effective. It can't predict Trump's success to a high degree of certainty, and certainly not better than a human eye could. But that is expected - part of what makes Trump's twitter (and his persona, in fact) so interesting (regardless of your political affiliation) is that he truly *is* unpredictable. It is impossible to pythonically recreate the circumstances and political environment surrounding what goes into each tweet - from the vitriol of the Kavanaugh hearings to the uncertainty surrounding the 2018 Midterms. 

I would certainly say that this model still *did* accomplish a lot, but for it to really make the leap into consistently accurate predictions, there needs to be a way to measure the national importance surrounding the content of his messages. That being said, I am proud of the work I have completed here, and think it's a great basis for something more powerful. 

# To Implement: 
If you would like to use this model for yourself, please look into the Final_Results folder. There, you will see a file detailing the simple instructions to deploy it on your own computer. 


