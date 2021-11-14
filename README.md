# Finding Exoplanets with Machine Learning

Developing Classification Models for Kepler Mission Data

# Overview

In this project, I explored various machine learning techniques to create and tune classification models. I attempted to create a model that could accurately predict whether a star was likely to have planets based on properties of the stellar system measured by the Kepler Space Telescope. In addition, I applied "double" cross-validation procedures to assess the modeling process.

The project code is split into two RMarkdown files. [KOI_ML_explore.Rmd](KOI_ML_explore.Rmd) contains the code for my initial data set exploration and analysis, including the plots of variable distributions. [KOI_ML_model.Rmd](KOI_ML_model.Rmd) is the script I used for model training, parameter tuning, model selection, and selection process assessment.

I outline the project steps briefly below, and I've added a [project summary report](Kepler%20Project%20Summary.pdf) with expanded explanations and further details. More information on the Kepler Mission is [available from NASA](https://www.nasa.gov/mission_pages/kepler/overview/index.html). NASA also maintains the [Exoplanet Archive](https://exoplanetarchive.ipac.caltech.edu/index.html) with up-to-date information on confirmed and candidate exoplanets.  

# Data Source & Preliminary Analysis

The dataset I used was posted by [NASA on Kaggle.com](https://www.kaggle.com/nasa/kepler-exoplanet-search-results) and contained data on nearly 10,000 "Kepler Objects of Interest" across 50 data dimensions (I've [included a copy](KOI_data.csv) in the repository). I chose "koi_pdisposition" as the response variable for classification and selected 12 variables as predictors. The dataset required only minimal cleaning to filter out incomplete records.

I explored the data set characteristics using the `dplyr` and `ggplot2` packages in R to create boxplots, histograms, normal probability plots, and overlapping density plots for each predictor variable.
