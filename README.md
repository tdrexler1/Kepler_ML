# Finding Exoplanets with Machine Learning

Developing Classification Models for Kepler Mission Data

# Overview

In this project, I explored various machine learning techniques used to create and tune predictive classifier models. The primary project goal was to find a model that could accurately predict whether a star was likely to have planets based on properties of the stellar system measured by the Kepler Space Telescope. In addition to the model tuning and selection process, I applied "double" cross-validation to assess the potential accuracy of any model created using the procedure I developed.

I've included the project code in two RMarkdown files. [KOI_ML_explore.Rmd](KOI_ML_explore.Rmd) contains the code for my initial data set exploration and analysis, including plots of variable distributions for transformed and untransformed variables. [KOI_ML_model.Rmd](KOI_ML_model.Rmd) is the script I used for model training, parameter tuning, model selection, and selection process assessment.

I've included a brief outline of the project steps below, and I've added a [project summary report](Kepler%20Project%20Summary.pdf) with further details and explanations. More information about the Kepler Mission and the science behind it is [available from NASA](https://www.nasa.gov/mission_pages/kepler/overview/index.html), which also maintains the [Exoplanet Archive](https://exoplanetarchive.ipac.caltech.edu/index.html) with up-to-date information on confirmed and candidate exoplanets.

# Data Source & Preliminary Analysis

I downloaded the project data set from [Kaggle.com](https://www.kaggle.com/nasa/kepler-exoplanet-search-results), as posted by NASA (I've [included a copy](KOI_data.csv) in the project repository). The data set contained measurements of nearly 10,000 "Kepler Objects of Interest" across 50 dimensions. I used "koi_pdisposition" as the categorical response variable and selected 12 variables with continuous, numeric values as predictors. The data set did not require any significant data cleaning operations other than removing 364 incomplete records.

I explored the data set characteristics using the R packages `dplyr` to reformat the data and `ggplot2` to generate data visualizations. I created boxplots, histograms, normal probability plots, and overlapping density plots for each predictor variable to examine the distribution of the measurement values. These plots clearly showed heavily right-skewed distributions for 10 of the variables. I decided a *ln(x+1)* transformation would be appropriate for these predictors to reduce the data variance and render the distribution shapes closer to normal.

Before moving on to model selection, I first narrowed down the number of modeling methods I wanted to evaluate. The predictor variables failed a test of multivariate normality, indicating that linear discriminate analysis models and quadratic discriminate analysis models would likely perform poorly on the KOI data set. Likewise, a correlation test showed no substantial linear relationship between the koi_pdisposition response variable and any predictor, which could affect the performance of linear models. In addition, several pairs of predictor variables showed significant linear correlations after variable transformation, suggesting variance inflation could further reduce linear model accuracy. On this basis, I removed logistic regression models and penalized logistic regression models from the model selection process.  

# Classification Model Selection

The initial set of modeling techniques I selected included: support vector machines (SVMs) with a radial kernel, k-nearest neighbors, decision trees, boosted decision trees, random forests/bagging, and artificial neural nets. I used 10-fold cross-validation on the complete data set to create multiple versions of each model type over different value ranges of tunable modeling parameters. This process took considerable time to complete, so I decided to reduce the number of modeling methods further by measuring the performance of the optimally-tuned model for each model type. On this basis, I eliminated decision trees and decision tree boosting, each of which had classification error rates of more than one standard deviation higher than the minimum error rate found among all models.

After this preliminary selection process, I reconfigured my code to evaluate only the SVM, k-nearest neighbors, random forests/bagging, and artificial neural net modeling methods. Again using 10-fold cross-validation with the complete KOI data set, I found that an SVM with a radial kernel had the lowest classification error rate of 15.68%, obtained by using a cost penalty value of 1 and a radial kernel constant of 0.5. 

# Selection Process Assessment

