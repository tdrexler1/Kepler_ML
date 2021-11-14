# Finding Exoplanets with Machine Learning

Developing Classification Models for Kepler Mission Data

# Overview

In this project, I explored various machine learning techniques to create and tune classification models. I attempted to create a model that could accurately predict whether a star was likely to have planets based on properties of the stellar system measured by the Kepler Space Telescope. In addition, I applied "double" cross-validation procedures to assess the modeling process.

links to data files, summary, kepler mission, project code

# Data Source

The dataset I used was posted by [NASA on Kaggle.com](https://www.kaggle.com/nasa/kepler-exoplanet-search-results) and contained data on nearly 10,000 "Kepler Objects of Interest" across 50 data dimensions. I chose "koi_pdisposition" as the response variable for classification and selected 12 variables as predictors. The dataset required only minimal cleaning to filter out incomplete records.

# Preliminary Analysis

I explored the data set characteristics using the `dplyr` and `ggplot2` packages in R to create boxplots, histograms, normal probability plots, and overlapping density plots for each predictor variable.
