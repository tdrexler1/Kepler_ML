#' ---
#' title: "Kepler Space Telescope Exoplanet Search Data Machine Learning Classification Project"
#' subtitle: "Model Selection and Selection Process Assessment"
#' author: "Timothy Drexler"
#' date: "August 2019"
#' ---


## ---- Setup ------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

# used to load large csv file
require(readr)
# used to manipulate data frame
require(dplyr)

# used for support vector machines
require(e1071)
# used for random forest / bagging
require(randomForest)
# used for artificial neural nets
require(nnet)
# used for k-nearest neighbors
require(class)

# prevent masking of 'dplyr' select by other packages
select <- dplyr::select


## ---- Data Import ------------------------------------------------------------

# import data set
koi_df <- 
  # load data set
  data.frame(read_csv("KOI_data.csv", n_max = 9564) ) %>% 
  # select response + useful predictors (exclude error columns, flags, ids, etc.)
  select(koi_pdisposition, koi_period, koi_impact, koi_duration, koi_depth, koi_prad, koi_teq, koi_insol, koi_model_snr, koi_steff, koi_slogg, koi_srad, koi_kepmag ) %>% 
  # code response as factor
  mutate( koi_pdisposition = as.factor(koi_pdisposition) )

# examine observations with missing values
koi_df_missing <- 
  koi_df %>% 
  filter(!complete.cases(.)) 

# filter data set to include only complete cases
koi_df <- 
  koi_df %>% 
  filter(complete.cases(.)) 

# no variables have negative values, but there are some zeroes, so use ln(x+1) transformation on all variables other than 'koi_kepmag' (already approximately-normal), 'koi_slogg' (left-skewed), and 'koi_pdisposition' (binary response) 
koi_transform <- 
  koi_df %>% mutate_at(vars(-c(koi_pdisposition, koi_slogg, koi_kepmag) ), list(~log1p(.) ) )


## ----Model Selection & Selection Process Assessment --------------------------

## Cross-validation group selection --------------------------------------------
cv_group_select <- function(n, m=10, seed=NULL){
  # Creates randomly-sampled groups for cross-validation folds.
  # Args: n : # of observations in data frame, m : # of CV folds, seed : initialization value for random-number generator
  # Returns: vector of length n of numbers 1 to m in random order

  # vector (size n) of group labels
  groups_select <- c( rep(1:m, n%/%m) )
  if(n%%m!=0){groups_select <- c(groups_select, 1:(n%%m) )}
  
  # initialize random number generator
  set.seed(seed)
  
  # return randomly sampled groups
  return( sample( groups_select, size = n ) )
}


## Model selection function ----------------------------------------------------

model_select <- function(select_df, modeling_formula){
  # Uses 10-fold cross-validation and ranges of model tuning parameters to select classification model with lowest error rate on input data set
  # Args: select_df : data set, modeling_formula : formula object (of form x~y) used by the modeling methods
  # Returns: list object containing: 'model_name' : character string of selected modeling method (abbreviated), 'model_er' : classification error rate of selected model, model '_params' : tuned values of 1-2 parameters used to fit selected model
  
  # data frames with binary and factor response for use by modeling functions
  select_factor <- select_df %>% mutate( koi_pdisposition = as.factor(koi_pdisposition) )
  select_bin <- select_df %>% mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) )
  
  # number of folds used for selection process cross-validation
  CVFOLDS_SELECT <- 10
  
  # create CV sample groups
  model_select_cvgroups <- cv_group_select(n = dim(select_df)[1], m = CVFOLDS_SELECT, seed = 21)
  
### SUPPORT VECTOR MACHINE

  # define parameter testing ranges
  gamma_values <- c(0.5, 1, 2, 3, 4)
  cost_values <- c(0.01, 0.1, 1, 10, 100, 1000)

  # objects to store model output
  svm_predictions <- rep(NA, dim(select_df)[1])
  svm_er_matrix <- matrix(NA, nr=length(gamma_values), nc=length(cost_values) )

  for (g in 1:length(gamma_values) ){ # iterate over all values of gamma parameter
    for (c in 1:length(cost_values) ){ # iterate over all values of cost parameter
      for (i in 1:CVFOLDS_SELECT){ # iterate over CV folds

        groupi <- model_select_cvgroups == i

        # fit support vector machine to CV-fold data
        svm_fit <- svm(modeling_formula, data = select_bin[!groupi, ], kernel = "radial", cost = cost_values[c], gamma = gamma_values[g], type = "C-classification")

        # predict classifications for non-CV-fold data
        svm_predictions[groupi] <- predict(svm_fit, select_bin[groupi, ])

      } # end iteration over CV folds

    # confusion matrix of predicted responses vs. observed responses
    svm_conf_mtrx <- table(svm_predictions, select_bin$koi_pdisposition)

    # store classification error rate
    svm_er_matrix[g, c] <- sum(svm_conf_mtrx[row(svm_conf_mtrx) != col(svm_conf_mtrx)]) / sum(svm_conf_mtrx)

    } # end iteration over values of cost parameter
  } # end iteration over values of gamma parameter

  # matrix indices of model with lowest classification error rate
  svm_min_er_indices = which(svm_er_matrix==min(svm_er_matrix, na.rm = T), arr.ind = T)

  # lowest support vector machine classification error rate
  svm_min_er <- svm_er_matrix[svm_min_er_indices][1]

  # model parameters for best-performing model
  svm_gamma_best <- gamma_values[svm_min_er_indices[1, 1] ]
  svm_cost_best <- cost_values[svm_min_er_indices[1, 2] ]
  
### RANDOM FOREST / BAGGING
  
  # define parameter testing range
  mtry_values <- 1:12

  # objects to store model output
  rf_predictions <- rep(NA, dim(select_df)[1])
  rf_er_vector <- rep(NA, length(mtry_values) )

  # set random number generator for reproducible results
  set.seed(21)

  for (p in 1:length(mtry_values) ){ # iterate over all values of 'mtry'
    for (i in 1:CVFOLDS_SELECT){ # iterate over all CV folds

      groupi <- model_select_cvgroups == i

      # fit random forest model to CV-fold data
      rf_fit <- randomForest(modeling_formula, data = select_factor[!groupi, ], mtry=mtry_values[p], strata = koi_pdisposition)

      # predict classifications for non-CV-fold data
      rf_predictions[groupi] <- predict(rf_fit, newdata = select_factor[groupi, ], type="response")

    } # end iteration over CV folds

    # confusion matrix of predicted responses vs. observed responses
    rf_conf_mtrx <- table(rf_predictions, select_factor$koi_pdisposition)

    # store classification error rate
    rf_er_vector[p] <- sum(rf_conf_mtrx[row(rf_conf_mtrx) != col(rf_conf_mtrx)]) / sum(rf_conf_mtrx)

  } # end iteration over values of 'mtry'

  # lowest random forest classification error rate
  rf_min_er = min(rf_er_vector)

  # model parameter for best-performing model
  rf_mtry_best = mtry_values[which.min(rf_er_vector)]
  
### ARTIFICIAL NEURAL NET

  # define parameter testing range
  node_values <- 1:20

  # objects to store model output
  ann_predictions <- rep(NA, dim(select_df)[1])
  ann_er_vector <- rep(NA, length(node_values) )

  # set random number generator for reproducible results
  set.seed(42)

  for (n in 1:length(node_values) ){ # iterate over all values of 'size'
    for (i in 1:CVFOLDS_SELECT){ # iterate over all CV folds

      groupi <- model_select_cvgroups == i

      # fit ann model to CV-fold data
      ann_fit <- nnet(modeling_formula, data = select_factor[!groupi, ], size = node_values[n], maxit = 200, trace = F)
      # predict classifications for non-CV-fold data
      ann_predictions[groupi] <- predict(ann_fit, select_factor[groupi, ], type = "class")

    } # end iteration over CV folds

    # confusion matrix of predicted responses vs. observed responses
    ann_conf_mtrx <- table(ann_predictions, select_factor$koi_pdisposition)

    # store classification error rate
    ann_er_vector[n] <- sum(ann_conf_mtrx[row(ann_conf_mtrx) != col(ann_conf_mtrx)]) / sum(ann_conf_mtrx)

  } # end iteration over values of 'size'

  # lowest artificial neural net classification error rate
  ann_min_er = min(ann_er_vector)

  # model parameter for best-performing model
  ann_nodes_best = node_values[which.min(ann_er_vector)]
  
### K NEAREST NEIGHBORS

  # define parameter testing range
  k_values <- 1:30

  # objects to store model output
  knn_predictions <- rep(NA, dim(select_df)[1])
  knn_er_vector <- rep(NA, length(k_values) )

  for (k in 1:length(k_values) ){ # iterate over all values of 'k'
    for (i in 1:CVFOLDS_SELECT){ # iterate over all CV folds

      groupi <- model_select_cvgroups == i

      # matrix of training set predictors
      knn_train_obs <- scale(select_bin[!groupi, -1])

      # vector of training set response
      knn_train_response <- select_bin[!groupi, 1]

      # matrix of validation set predictors
      knn_valid_obs <- scale(select_bin[groupi, -1],
                             center = attr(knn_train_obs, "scaled:center"),
                             scale = attr(knn_train_obs, "scaled:scale")
                             )

      # vector of validation set response
      knn_valid_response <- select_bin[groupi, 1]

      # k-nearest neighbors predictions on validation set
      knn_predictions[groupi] <- knn(knn_train_obs, knn_valid_obs, knn_train_response, k = k_values[k])

    } # end iteration over CV folds

    # confusion matrix of predicted responses vs. observed responses
    knn_conf_mtrx <- table(knn_predictions, select_bin$koi_pdisposition)

    # store classification error rate
    knn_er_vector[k] <- sum(knn_conf_mtrx[row(knn_conf_mtrx) != col(knn_conf_mtrx)]) / sum(knn_conf_mtrx)

  } # end iteration over values of 'k'

  # lowest k-nearest neighbors classification error rate
  knn_min_er = min(knn_er_vector)

  # model parameter for best-performing model
  knn_k_best = k_values[which.min(knn_er_vector)]
  
### SELECT MODELING METHOD WITH LOWEST CLASSIFICATION ERROR RATE
  
  # vector of minimum error rates for each model type
  model_er_vector <- setNames( c(svm_min_er, rf_min_er, ann_min_er, knn_min_er), c("SVM", "RF", "ANN", "KNN") )
  
  # name of best modeling method
  selected_model <- names(which.min(model_er_vector) )
  
  # return selected model name, error rate, & parameters as list
  if(selected_model == "SVM"){
    
    return(list( model_name = selected_model, model_er = svm_min_er, cost_param = svm_cost_best, gamma_param = svm_gamma_best))
    
  }else if(selected_model == "RF"){
    
    return(list( model_name = selected_model, model_er = rf_min_er, mtry_param = rf_mtry_best))
    
  }else if(selected_model == "ANN"){
    
    return(list( model_name = selected_model, model_er = ann_min_er, node_param = ann_nodes_best))
    
  }else if(selected_model == "KNN"){
    
    return(list ( model_name = selected_model, model_er = knn_min_er, k_param = knn_k_best))
    
  }
  
}


## Model selection using full data set -----------------------------------------

## NOTE: the function call in this chunk can take 2+ hours to run; the pre-processed result is included in the commented line below the call

# modeling formula including all available predictors
fullfit_formula <- koi_pdisposition ~ .

# call function to select model best fit for full data set
fullfit_selection_results <- model_select(koi_transform, fullfit_formula)
#fullfit_selection_results <- list(model_name = "SVM", model_er = 0.157, cost_param = 1, gamma_param = 0.5)

# data frames with binary and factor response for use by modeling functions below
fullfit_factor <- koi_transform %>% mutate( koi_pdisposition = as.factor(koi_pdisposition) )
fullfit_bin <- koi_transform %>% mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) )
  
# fit selected model to full data set using selected model tuning parameters
if(fullfit_selection_results$model_name == "SVM"){
  
  selected_fit <- svm(fullfit_formula, data = fullfit_bin, kernel = "radial", cost = fullfit_selection_results$cost_param, gamma = fullfit_selection_results$gamma_param, type = "C-classification")
  
}else if(fullfit_selection_results$model_name == "RF"){
  
  selected_fit <- randomForest(fullfit_formula, data = fullfit_factor, mtry = fullfit_selection_results$mtry_param, strata = koi_pdisposition)
  
}else if(fullfit_selection_results$model_name == "ANN"){
  
  selected_fit <- nnet(fullfit_formula, data = fullfit_factor, size = fullfit_selection_results$node_param, maxit = 200, trace = F)
  
}else if(fullfit_selection_results$model_name == "KNN"){
  # make knn predictions using LOOCV
  knn_predictions <- rep(NA, dim(fullfit_bin)[1])
  
  for (i in 1:dim(fullfit_bin)){ # iterate over all data points
    
    # matrix of training set predictors
    knn_train_obs <- scale(fullfit_bin[-i, -1])
    
    # vector of training set response
    knn_train_response <- fullfit_bin[-i, 1]
    
    # matrix of validation set predictors
    knn_valid_obs <- scale(fullfit_bin[i, -1],
                           center = attr(knn_train_obs, "scaled:center"),
                           scale = attr(knn_train_obs, "scaled:scale")
                           )

    # vector of validation set response 
    knn_valid_response <- fullfit_bin[i, 1]
    
    # k-nearest neighbors predictions on validation set
    knn_predictions[i] <- knn(knn_train_obs, knn_valid_obs, knn_train_response, k = fullfit_selection_results$k_param)
    
  } # end iteration over all data points
  
  # knn doesn't have a generalized fit - returns model predictions instead
  selected_fit <- cat("K-nearest neighbor predictions; ", k_param, " nearest neighbors.\n", knn_predictions, sep = "")
} # end if...else if...

# report selection results
cat("Best model type: ", fullfit_selection_results$model_name, "\nClassification error rate of best model: ", fullfit_selection_results$model_er, "\n", sep = "")

selected_fit


## Selection process assessment ------------------------------------------------

## NOTE: this chunk takes > 12 hours to run; pre-processed assessment results are included in the chunk below

# start timer
start_time <- Sys.time()

assess_df <- koi_transform # data frame to use for selection process assessment

CVFOLDS_ASSESS <- 10 # number of folds used for cross-validation in selection process assessment

# modeling formula as object
full_formula <- koi_pdisposition ~ .

# create CV sample groups for assessment
model_assess_cvgroups <- cv_group_select(n = dim(assess_df)[1], m = CVFOLDS_ASSESS, seed = 7)

# vectors to store selection results of each assessment CV fold
jfold_model <- rep(NA, CVFOLDS_ASSESS)
jfold_model_er <- rep(NA, CVFOLDS_ASSESS)

for(j in 1:CVFOLDS_ASSESS){ # iterate over all assessment CV folds
  
  groupj <- model_assess_cvgroups == j
  
  # split full data set into training and testing sets for each fold
  # response variable as factor
  assess_train_factor <- assess_df[!groupj, ] %>% 
    mutate( koi_pdisposition = as.factor(koi_pdisposition) )
  assess_test_factor <- assess_df[groupj, ] %>% 
    mutate( koi_pdisposition = as.factor(koi_pdisposition) )
  
  # response variable as binary
  assess_train_bin <- assess_df[!groupj, ] %>% 
    mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) )
  assess_test_bin <- assess_df[groupj, ] %>% 
    mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) )
  
  # pass assessment training data to 'inner' selection loop
  select_df <- assess_df[!groupj, ]
  
  cat("Working on fold ", j, "...\n", sep = "") # progress message
  
#####  MODEL SELECTION 

  # call function to select best-fit model
  jfold_selection_results <- model_select(select_df, full_formula)
  
##### END MODEL SELECTION 

  # object to store predictions on assessment process test data
  selected_predictions <- rep(NA, dim(assess_test_factor)[1])
  
  if(jfold_selection_results$model_name == "SVM"){
    
    # fit support vector machine model to full available data
    selected_fit <- svm(full_formula, data = assess_train_bin, kernel = "radial", cost = jfold_selection_results$cost_param, gamma = jfold_selection_results$gamma_param, type = "C-classification")
    
    # predictions on assessment process test data
    selected_predictions <- predict(selected_fit, assess_test_bin)
    
    # confusion matrix of predicted responses vs. observed responses
    jfold_conf_mtrx <- table(selected_predictions, assess_test_bin$koi_pdisposition)
    
  }else if(jfold_selection_results$model_name == "RF"){
      
    # fit random forest model to full available data
    selected_fit <- randomForest(full_formula, data = assess_train_factor, mtry = jfold_selection_results$mtry_param, strata = koi_pdisposition)
      
    # predictions on assessment process test data
    selected_predictions <- predict(selected_fit, newdata = assess_test_factor, type="response")
    
    # confusion matrix of predicted responses vs. observed responses
    jfold_conf_mtrx <- table(selected_predictions, assess_test_factor$koi_pdisposition)
    
  }else if(jfold_selection_results$model_name == "ANN"){
  
    # fit artificial neural net model to full available data
    selected_fit <- nnet(full_formula, data = assess_train_factor, size = jfold_selection_results$node_param, maxit = 200, trace = F)
    
    # predictions on assessment process test data
    selected_predictions <- predict(selected_fit, newdata = assess_test_factor, type = "class")
    
    # confusion matrix of predicted responses vs. observed responses
    jfold_conf_mtrx <- table(selected_predictions, assess_test_factor$koi_pdisposition)
  
  }else if(jfold_selection_results$model_name == "KNN"){
    
      # matrix of training set predictors
      knn_train_obs <- scale(assess_train_bin[, -1])
      
      # vector of training set response
      knn_train_response <- assess_train_bin[, 1]
      
      # matrix of validation set predictors
      knn_valid_obs <- scale(assess_test_bin[, -1],
                             center = attr(knn_train_obs, "scaled:center"),
                             scale = attr(knn_train_obs, "scaled:scale")
                             )

      # vector of validation set response 
      knn_valid_response <- assess_test_bin[, 1]
      
      # k-nearest neighbors predictions on validation set
      selected_predictions <- knn(knn_train_obs, knn_valid_obs, knn_train_response, k = jfold_selection_results$k_param)
      
      # confusion matrix of predicted responses vs. observed responses
      jfold_conf_mtrx <- table(selected_predictions, assess_test_bin$koi_pdisposition)
      
  } # end if...else if...
    
  # classification error rate of selected model predictions for fold j
  jfold_model_er[j] <- sum(jfold_conf_mtrx[row(jfold_conf_mtrx) != col(jfold_conf_mtrx)]) / sum(jfold_conf_mtrx)
  
  # store name of selected modeling method for fold j
  jfold_model[j] <- jfold_selection_results$model_name

} # end iteration over assessment CV folds

# proportion of responses incorrectly classified
cv_10 <- mean(jfold_model_er)

# proportion of responses able to be (honestly) correctly classified by selected model
p_cv <- 1 - cv_10

# report selection process assessment results
cat("Cross-validated Measures for Assessment\n\nProportion of responses incorrectly classified: ", cv_10, "\nProportion of responses able to be (honestly) correctly classified by selected model: ", p_cv, "\n\n", sep = "")

# stop timer
end_time <- Sys.time()
assessment_process_time <- end_time - start_time
cat("\n\nTime to run assessment process: ", assessment_process_time, "\n", sep = "")


## Pre-processed assessment results --------------------------------------------

# error rate vectors for individual modeling methods across assessment folds
jfold_model_er_knn <- c(0.1652174, 0.1793478, 0.1836957, 0.1706522, 0.1532609, 0.1750000, 0.1706522, 0.1543478, 0.1608696, 0.1706522)
jfold_model_er_rf <- c(0.1543478, 0.1728261, 0.1641304, 0.1532609, 0.1347826, 0.1586957, 0.1750000, 0.1456522, 0.1565217, 0.1739130)
jfold_model_er_svm <- c(0.1478261, 0.1695652, 0.1532609, 0.1510870, 0.1456522, 0.1739130, 0.1586957, 0.1456522, 0.1510870, 0.1684783)
jfold_model_er_ann <- c(0.1619565, 0.1771739, 0.1728261, 0.1576087, 0.1565217, 0.1641304, 0.1717391, 0.1586957, 0.1619565, 0.1869565)

# matrix of modeling method error rates
jfold_model_er_matrix <- matrix( c(jfold_model_er_knn, jfold_model_er_rf, jfold_model_er_svm, jfold_model_er_ann), nr = 4, nc = 10, byrow = T)
rownames(jfold_model_er_matrix) <- c("KNN", "RF", "SVM", "ANN")

# vector of minimum error rates for each assessment fold
jfold_model_er <- apply(jfold_model_er_matrix, 2, min)

# simulated vector of model names with minimum error rate in each assessment fold
jfold_model <- rownames(jfold_model_er_matrix)[apply(jfold_model_er_matrix, 2, which.min )]

# proportion of responses incorrectly classified
cv_10 <- mean(jfold_model_er)

# proportion of responses able to be (honestly) correctly classified by selected model
p_cv <- 1 - cv_10

# report selection process assessment results
cat("Cross-validated Measures for Assessment\n\nProportion of responses incorrectly classified: ", cv_10, "\nProportion of responses able to be (honestly) correctly classified by selected model: ", p_cv, "\n\n", sep = "")
