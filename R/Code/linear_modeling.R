library(readr)
library(car)
library(dplyr)
library(glmnet)

# Read data
df <- read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/final_abt.csv')
# Remove year < 2017
df <- df %>% filter(Year > 2016)
# Change boolean variables to factors 
df[,c(10,12,16,18, 21, 23:33)] <- apply(X = df[,c(10,12,16,18, 21, 23:33)],MARGIN = 2,FUN = as.factor)

# Create X, y
X = df[,2:ncol(df)]
X$Followers <- as.integer(X$Followers)
X$Follower_Change <- as.integer(X$Follower_Change)
y = df$favorite_count

# Full model 
m1 <- lm(y~., data = X)
# Backward BIC Search
step(m1, direction = 'backward', k = log(ncol(df)))
mbic <- lm(formula = y ~ Followers + Follower_Change + Num_Tweets + Year + 
              Month + Day + Hour + Holiday + Any_urls + Character_Count + 
              Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
              Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
              tfidf + Subjectivity, data = X)
summary(mbic)
vif(mbic)

# Remove Year to improve vif
mbic2 <- lm(formula = y ~ Followers + Follower_Change + Num_Tweets + 
               Month + Day + Hour + Holiday + Any_urls + Character_Count + 
               Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
               Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
               tfidf + Subjectivity, data = X)
vif(mbic2)
plot(mbic2)

# Not great normality - check if a power transformaion helps 
lambda <- powerTransform(mbic2)$lambda

mbic3 <- lm(formula = y^lambda ~ Followers + Follower_Change + Num_Tweets + 
                Month + Day + Hour + Holiday + Any_urls + Character_Count + 
                Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
                Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
                tfidf + Subjectivity, data = X)
plot(mbic3)

# Test on 2018 data
x.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/X_test.csv')
y.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/y_test.csv')
y.test = y.test$favorite_count

# Factors
x.test[,c(9,11,15,17, 20, 22:32)] <- apply(X = x.test[,c(9,11,15,17, 20, 22:32)],MARGIN = 2,FUN = as.factor)
# Predict
pred <- predict(object = mbic3, x.test)
pred <- pred^(1/lambda)
mean(abs(pred - y.test))
results <- tibble(pred, y.test)
results$percerr <- abs(round(((pred - y.test)/y.test)*100))
head(results)
plot(pred, y.test)


###########
## Lasso ##
###########
# Read data
df <- read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/final_abt.csv')
# Remove year < 2017
df <- df %>% filter(Year > 2016)
# Change boolean variables to factors 
df[,c(10,12,16,18, 21, 23:33)] <- apply(X = df[,c(10,12,16,18, 21, 23:33)],MARGIN = 2,FUN = as.factor)

# Create X, y
X = df[,2:ncol(df)]
X$Followers <- as.integer(X$Followers)
X$Follower_Change <- as.integer(X$Follower_Change)
y = df$favorite_count
# Standardize numeric variables 
X[,c(1:8,10,12:14,16,18:19,21,33:37)] <- apply(X[,c(1:8,10,12:14,16,18:19,21,33:37)], 2, scale)

# Test on 2018 data
x.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/X_test.csv')
y.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/y_test.csv')
y.test = y.test$favorite_count

# Factors
x.test[,c(9,11,15,17, 20, 22:32)] <- apply(X = x.test[,c(9,11,15,17, 20, 22:32)],MARGIN = 2,FUN = as.factor)
# Standardize
x.test[,c(1:8,10,12:14,16,18:19,21,33:37)] <- scale(x.test[,c(1:8,10,12:14,16,18:19,21,33:37)])
x.test$Year <- X$Year[1]
x.test$Month <- (10 - mean(df$Month))/sd(df$Month)
lasso <- cv.glmnet(y = data.matrix(y)^(1/20), x = data.matrix(X), family = 'gaussian', alpha = 1)
pred2 <- predict(lasso, data.matrix(x.test))
pred2 <- pred2^20
mean(abs(pred2 - y.test))
# Check assumptions 
residuals <- y - predict(lasso, data.matrix(X))
std_resid <- scale(residuals)
plot(lm(std_resid~predict(lasso, data.matrix(X))))


###########
## Ridge ##
###########
# Read data
df <- read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/final_abt.csv')
# Remove year < 2017
df <- df %>% filter(Year > 2016)
# Change boolean variables to factors 
df[,c(10,12,16,18, 21, 23:33)] <- apply(X = df[,c(10,12,16,18, 21, 23:33)],MARGIN = 2,FUN = as.factor)

# Create X, y
X = df[,2:ncol(df)]
X$Followers <- as.integer(X$Followers)
X$Follower_Change <- as.integer(X$Follower_Change)
y = df$favorite_count
# Standardize numeric variables 
X[,c(1:8,10,12:14,16,18:19,21,33:37)] <- apply(X[,c(1:8,10,12:14,16,18:19,21,33:37)], 2, scale)

# Test on 2018 data
x.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/X_test.csv')
y.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/y_test.csv')
y.test = y.test$favorite_count

# Factors
x.test[,c(9,11,15,17, 20, 22:32)] <- apply(X = x.test[,c(9,11,15,17, 20, 22:32)],MARGIN = 2,FUN = as.factor)
# Standardize
x.test[,c(1:8,10,12:14,16,18:19,21,33:37)] <- scale(x.test[,c(1:8,10,12:14,16,18:19,21,33:37)])
x.test$Year <- X$Year[1]
x.test$Month <- (10 - mean(df$Month))/sd(df$Month)
ridge <- cv.glmnet(y = data.matrix(y)^(1/20), x = data.matrix(X), family = 'gaussian', alpha = 0)
pred2 <- predict(ridge, data.matrix(x.test))
pred2 <- pred2^20
mean(abs(pred2 - y.test))
# Check assumptions 
residuals <- y - predict(ridge, data.matrix(X))
std_resid <- scale(residuals)
plot(lm(std_resid~predict(ridge, data.matrix(X))))

# Not perfectly constant variance, but generally speaking it looks fairly good. 

# Not perfectly constant variance, but generally speaking it looks fairly good. 



######################
### StandardScaler ###
######################
# Read data
df <- read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/final_abt.csv')
# Remove year < 2017
df <- df %>% filter(Year > 2016)
# Change boolean variables to factors 
df[,c(10,12,16,18, 21, 23:33)] <- apply(X = df[,c(10,12,16,18, 21, 23:33)],MARGIN = 2,FUN = as.factor)

# Create X, y
X = df[,2:ncol(df)]
X$Followers <- as.integer(X$Followers)
X$Follower_Change <- as.integer(X$Follower_Change)
y = df$favorite_count
# Standardize numeric variables 
X[,c(1:8,10,12:14,16,18:19,21,33:37)] <- apply(X[,c(1:8,10,12:14,16,18:19,21,33:37)], 2, scale)

# Full model 
m1 <- lm(y~., data = X)

# BackBIC search 
step(m1, direction = 'backward', k = log(ncol(df)))
mbic <- lm(formula = y ~ Followers + Follower_Change + Num_Tweets + Year + 
              Month + Day + Hour + Holiday + Any_urls + Character_Count + 
              Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
              Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
              tfidf + Subjectivity, data = X)
vif(mbic)

mbic2 <- lm(formula = y ~ Followers + Follower_Change + Num_Tweets + 
               Month + Day + Hour + Holiday + Any_urls + Character_Count + 
               Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
               Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
               tfidf + Subjectivity, data = X)
vif(mbic2)
plot(mbic2)

# Not great normality - check if a power transformaion helps 
lambda <- powerTransform(mbic2)$lambda

mbic3 <- lm(formula = y^lambda ~ Followers + Follower_Change + Num_Tweets + 
               Month + Day + Hour + Holiday + Any_urls + Character_Count + 
               Num_Stopwords + Any_Hashtags + Any_Mentions + Num_Upper + 
               Upper + Num_Exclaim + Any_Clinton + FakeNews + JoinMe + Violence + 
               tfidf + Subjectivity, data = X)
plot(mbic3)
# Decent fit 

# Test on 2018 data
x.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/X_test.csv')
y.test = read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/y_test.csv')
y.test = y.test$favorite_count

# Factors
x.test[,c(9,11,15,17, 20, 22:32)] <- apply(X = x.test[,c(9,11,15,17, 20, 22:32)],MARGIN = 2,FUN = as.factor)
# Standardize
x.test[,c(1:8,10,12:14,16,18:19,21,33:37)] <- scale(x.test[,c(1:8,10,12:14,16,18:19,21,33:37)])
x.test$Year <- X$Year[1]
x.test$Month <- (10 - mean(df$Month))/sd(df$Month)
   
# Predict
pred <- predict(object = mbic3, x.test)
pred <- pred^(1/lambda)
mean(abs(pred - y.test))
results <- tibble(pred, y.test)
results$percerr <- abs(round(((pred - y.test)/y.test)*100))
head(results)
plot(pred, y.test)
