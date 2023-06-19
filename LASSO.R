library(hdm)
library(glmnet)
library(caret)


# load colombia conflict dataset by Bazzi etc. (2022)
load("conflict_colombia.RData")
Y <- conflict$dv_violenceDUM  # binary variable of whether violence occurred 
X <- as.matrix(subset(conflict, select = grepl("^rhs_", names(conflict))))	# predictors of violence

# Split the data into training and testing set

# Index for test observations
set.seed(123)
test.fraction <- 1/4
test.size <- floor(test.fraction * length(Y))
test.ind <- sample(1:length(Y), size=test.size)

# Create training and test data
X.train <- X[-test.ind,]
X.test <- X[test.ind,]
Y.train <- Y[-test.ind]
Y.test <- Y[test.ind]



# ------- OLS

# Fit OLS model
fit.ols <- lm(Y.train ~ X.train)
summary(fit.ols)



# ------- LASSO

# Perform LASSO model training and tuning
train_labels <- as.numeric(Y.train)
fit.lasso <- cv.glmnet(x = X.train, y = train_labels, alpha = 1)

# Choose the best lambda value
best_lambda <- fit.lasso$lambda.min

# Fit the final LASSO model with the selected lambda
fit.lasso.final <- glmnet(x = X.train, y = train_labels, alpha = 1, lambda = best_lambda)
print(fit.lasso.final)



# ------- out-of-sample prediction

# (a) OLS

# predict on test data
X.test_df <- as.data.frame(X.test)
Y.pred.ols <- predict(fit.ols, newdata = X.test_df)

# compute out-of-sample MSE and R^2
mse.ols <- mean((Y.test - Y.pred.ols)^2)
R2.ols <- 1 - mse.ols / var(Y.test)

# (b) LASSO

# predict on test data
Y.pred.lasso <- predict(fit.lasso.final, newx=X.test)

# compute out-of-sample MSE and R^2
mse.lasso <- mean((Y.test - Y.pred.lasso)^2)
R2.lasso <- 1 - mse.lasso / var(Y.test)

# summary

res <- matrix(c(mse.ols, R2.ols, mse.lasso, R2.lasso), ncol=2, byrow=TRUE)
colnames(res) <- c("MSE", "R2")
rownames(res) <- c("OLS", "LASSO")
res