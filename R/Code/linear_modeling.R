library(car)
library(read_csv)
library(glmnet)
df <- read_csv('~/Documents/GitHub/Trump-Twitter-Predictions/Data/abt.csv')

indices <- sample(1:nrow(df), 2376)

x.test <- df[indices, ]
y.test <- df$favorite_count[indices]
x.train <- df[-indices, ]
y.train <- df$favorite_count[-indices]

m1 <- lm(y.train~Followers+Follower_Change+Num_Tweets+Month+Hour+Holiday, data = x.train)
summary(m1)
plot(m1)
lambda <- powerTransform(m1)$lambda
m2 <- lm(y.train^lambda~Followers+Follower_Change+Num_Tweets+Month+Hour+Holiday, data = x.train)
summary(m2)
plot(m2)

vif(m2)

# MAE
pr <- predict(m2, x.test)
mean(abs(y.test - pr))

pr2 <- predict(m1, x.test)
mean(abs(y.test - pr2))

lasso <- glmnet(y = as.matrix(y.train), x=as.matrix(x.train[,c(6:14)]), family = 'gaussian', alpha = 1)
pr3 <- predict(lasso, as.matrix(x.test[,c(6:14)]))
mean(abs(y.test - pr3))
