# Finding Exoplanets with Machine Learning

Developing Classification Models for Kepler Mission Data

# Overview

In this project, I explored various machine learning techniques to create and tune classification models. I attempted to create a model that could accurately predict whether a star was likely to have planets based on properties of the stellar system measured by the Kepler Space Telescope. In addition, I applied "double" cross-validation procedures to assess the modeling process.

The project code is split into two RMarkdown files. [KOI_ML_explore.Rmd](KOI_ML_explore.Rmd) contains the code for my initial data set exploration and analysis, including the plots of variable distributions. [KOI_ML_model.Rmd](KOI_ML_model.Rmd) is the script I used for model training, parameter tuning, model selection, and selection process assessment.

I outline the project steps briefly below, and I've added a [project summary report](Kepler%20Project%20Summary.pdf) with expanded explanations and further details. More information on the Kepler Mission is [available from NASA](https://www.nasa.gov/mission_pages/kepler/overview/index.html). NASA also maintains the [Exoplanet Archive](https://exoplanetarchive.ipac.caltech.edu/index.html) with up-to-date information on confirmed and candidate exoplanets.  

# Data Source & Preliminary Analysis

The data set I used was posted by [NASA on Kaggle.com](https://www.kaggle.com/nasa/kepler-exoplanet-search-results) and contained data on nearly 10,000 "Kepler Objects of Interest" across 50 data dimensions (I've [included a copy](KOI_data.csv) in the repository). I chose "koi_pdisposition" as the response variable for classification and selected 12 variables as predictor, all with continuous, numeric values. The only significant data cleaning operation necessary was to filter out incomplete records.

I explored the data set characteristics using the `dplyr` and `ggplot2` packages in R to shape and plot the data. I created boxplots, histograms, normal probability plots, and overlapping density plots for each predictor variable. The plots showed that the distribution of observation measurements was heavily right-skewed for 10 of the variables. To reduce the variance of the data and render the distributions closer to normal, I applied a *ln(x+1)* transformation to these variable values.

Before starting the model selection process, I first narrowed down the number of modeling methods I wanted to evaluate. For example, a test of multivariate normality indicated that the predictor variables were not multivariate normal, so linear discriminate analysis models and quadratic discriminate analysis models would likely perform poorly when tested on the KOI data set. Likewise, a test of linear correlation showed no strong linear relationship between the koi_pdisposition response variable and any predictor. In addition, several pairs of predictor variables showed significant linear correlations after transformation, suggesting variance inflation could decrease the accuracy of linear models. As a result, I chose to exclude logistic regression models and penalized logistic regression models from the selection process.  

# Classification Model Selection

The modeling techniques I selected included support vector machines (SVMs) with a radial kernal, k-nearest neighbors, decision trees, boosted decision trees, random forests/bagging, and artificial neural nets. For each approach, I trained multiple models using 10-fold cross-validation and a range of values for 1-3 tunable modeling parameters. This process took considerable time to complete, so I decided to reduce the number of modeling methods further by measuring the performance of the optimally-tuned model for each method. On this basis, I eliminated decision trees and boosted decision trees, both of which had classification error rates more than one standard deviation greater than the overall minimum error rate produced by an SVM model.

After this initial selection process, I "reset" my code to select only from among SVM, k-nearest neighbors, random forests/bagging, and artificial neural net modeling methods. Again using 10-fold cross-validation with the full KOI data set, an SVM with a radial kernal had the lowest classification error rate of 15.68%, obtained by using a cost penalty value of 1 and a radial kernal constant of 0.5. 

# Selection Process Assessment

