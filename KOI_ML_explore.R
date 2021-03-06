#' ---
#' title: "Kepler Space Telescope Exoplanet Search Data Machine Learning Classification Project"
#' subtitle: "Data Set Exploration and Preliminary Analysis"
#' author: "Timothy Drexler"
#' date: "August 2019"
#' ---


## ---- Setup ------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

# used to load large csv file
require(readr)
# used to manipulate data frame
require(dplyr)
# used for plots
require(ggplot2)
# used for plot colors
require(RColorBrewer)
# used to arrange plots
require(grid); require(gridExtra)
# used to melt data for plotting
require(data.table)
# used to plot correlation matrix
require(corrplot)
# used to test for multivariate normality
require(MVN)

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


## ---- Data Set Exploration ---------------------------------------------------

## boxplots --------------------------------------------------------------------

# overall distributions
melt(as.data.table(koi_df), id.vars= "koi_pdisposition") %>%
  select(variable, value) %>% 
  ggplot( aes(y=value, x=variable, fill=variable ) ) +
  geom_boxplot() +
  labs(title="Box Plots of Quantitative Variable Distributions", subtitle="Kepler data set", y="Value", x="") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none", axis.text.x = element_blank()) +
  facet_wrap(~variable, ncol=3, scales="free")

# distributions within each response category
melt(as.data.table(koi_df), id.vars= "koi_pdisposition") %>% 
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(y=value, x=koi_pdisposition, fill=koi_pdisposition ) ) +
  geom_boxplot() +
  labs(title="Box Plots of Quantitative Variable Distributions Within Categories of 'koi_pdisposition'", subtitle="Kepler data set", y="Value", x="") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), axis.text.x = element_blank() )+
  scale_x_discrete(limits=c("CANDIDATE","FALSE POSITIVE")) +
  facet_wrap(~variable, ncol=3, scales="free")

# most variables very right-skewed, except 'koi_slogg' (left-skewed) and 'koi_kepmag' (~normal, logarithmic scale)


## histograms ------------------------------------------------------------------

melt(as.data.table(koi_df), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(x=value, fill=variable) ) +
  geom_histogram(bins=15, color="black") +
  labs(title="Histograms of Quantitative Variable Distributions", subtitle="Kepler data set", y="Counts", x="") + 
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none") +
  facet_wrap(~variable, ncol=3, scales="free")

# most variables very right-skewed, except 'koi_slogg' (left-skewed) and 'koi_kepmag' (~normal, logarithmic scale)


## normal probability plots ----------------------------------------------------

melt(as.data.table(koi_df), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(sample=value, color=variable ) ) +
  stat_qq( size = 2, shape = 1 ) +
  stat_qq_line() +
  labs(title="Normal Probability Plots of Quantitative Variable Distributions", subtitle="Kepler data set", y="Sample Quantiles", x="Theoretical Quantiles") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none" ) +
  facet_wrap(~variable, ncol=3, scales="free")

# most variables very right-skewed, except 'koi_slogg' (left-skewed) and 'koi_kepmag' (~normal, logarithmic scale)


## overlapping density plots ---------------------------------------------------

melt(as.data.table(koi_df), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(x=value, color=koi_pdisposition  ) ) +
  geom_density(lwd=1) +
  labs(title="Overlapping Density Plots of Quantitative Variable Distributions Within Categories of 'koi_pdisposition'", subtitle="Kepler data set", y="Value", x="") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5) ) +
  facet_wrap(~variable, ncol=3, scales="free")

# 'koi_slogg', 'koi_steff', & 'koi_kepmag' appear to have ~equal variances between categories; 'koi_teq' appears to have unequal variances between categories; difficult to tell for other variables 


## linear correlations between response and predictor variables ----------------

pairs(koi_df[c(1,2:5)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)")
pairs(koi_df[c(1,6:9)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)") # 'koi_teq' and 'koi_insol' are correlated, but correlation is not linear
pairs(koi_df[c(1,10:13)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)") # 'koi_srad' correlated with 'koi_slogg', but correlation is not linear

cor(koi_df %>% mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) ))[ , 1] # no strong linear correlation between response and any predictors

# correlations between predictor variables
corrplot(
  cor( koi_df[ ,-1]),
  method="color", # squares instead of circles
  type = "upper", # upper half only
  addCoef.col="black", # add regression coefficient values
  order = "hclust", # hierarchical clustering order
  tl.col = "black", # text label color
  tl.srt = 45, # text label rotation
  tl.cex = 0.75, # text label size
  diag = FALSE, # remove correlation coefficients from principal diagonal
  number.cex=0.7 )# correlation coefficient text size (cex parameter)

# some linear correlations ('koi_slogg' & 'koi_srad', 'koi_prad' & 'koi_impact'), but all correlation coefficient magnitudes < 0.7, so won't eliminate any predictors


## ---- Variable Transformation ------------------------------------------------

# strong right-skew of most predictor variables suggests transformation may be appropriate
summary(koi_df)

# no variables have negative values, but there are some zeroes, so use ln(x+1) transformation on all variables other than 'koi_kepmag' (already approximately-normal), 'koi_slogg' (left-skewed), and 'koi_pdisposition' (binary response) 
koi_transform <- 
  koi_df %>% mutate_at(vars(-c(koi_pdisposition, koi_slogg, koi_kepmag) ), list(~log1p(.) ) )


## transformed variable boxplots -----------------------------------------------

# overall distributions
melt(as.data.table(koi_transform), id.vars= "koi_pdisposition") %>% 
  select(variable, value) %>% 
  ggplot( aes(y=value, x=variable, fill=variable ) ) +
  geom_boxplot() +
  labs(title="Box Plots of Quantitative Variable Distributions", subtitle="Kepler data set", y="Value", x="") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none", axis.text.x = element_blank()) +
  facet_wrap(~variable, ncol=3, scales="free")

# distributions within each response category
melt(as.data.table(koi_transform), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(y=value, x=koi_pdisposition, fill=koi_pdisposition ) ) +
  geom_boxplot() +
  labs(title="Box Plots of Quantitative Variable Distributions Within Categories of 'koi_pdisposition'", subtitle="Kepler data set", y="Value", x="") + 
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), axis.text.x = element_blank() )+
  scale_x_discrete(limits=c("CANDIDATE","FALSE POSITIVE")) +
  facet_wrap(~variable, ncol=3, scales="free")

# log(x+1) transformation produces more-symmetrical distributions to some degree for all variables
# no obvious differences in distribution by response category for any variable  


## transformed variable histograms ---------------------------------------------

melt(as.data.table(koi_transform), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(x=value, fill=variable) ) +
  geom_histogram(bins=15, color="black") +
  labs(title="Histograms of Quantitative Variable Distributions", subtitle="Kepler data set", y="Counts", x="") + 
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none") +
  facet_wrap(~variable, ncol=3, scales="free")

# log(x+1) transformation produces more-symmetrical distributions to some degree for all variables
# some variables still very right skewed ('koi_impact', 'koi_prad', 'koi_srad')


## transformed variable normal probability plots -------------------------------

melt(as.data.table(koi_transform), id.vars= "koi_pdisposition") %>%
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(sample=value, color=variable ) ) +
  stat_qq( size = 2, shape = 1 ) +
  stat_qq_line() +
  labs(title="Normal Probability Plots of Quantitative Variable Distributions", subtitle="Kepler data set", y="Sample Quantiles", x="Theoretical Quantiles") + 
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5), legend.position = "none" ) +
  facet_wrap(~variable, ncol=3, scales="free")

# log(x+1) transformation produces more-symmetrical distributions to some degree for all variables
# some variables still very right skewed ('koi_impact', 'koi_prad', 'koi_srad')


## transformed variable overlapping density plots ------------------------------

melt(as.data.table(koi_transform), id.vars= "koi_pdisposition") %>% 
  select(koi_pdisposition, variable, value) %>% 
  ggplot( aes(x=value, color=koi_pdisposition  ) ) +
  geom_density(lwd=1) +
  labs(title="Overlapping Density Plots of Quantitative Variable Distributions Within Categories of 'koi_pdisposition'", subtitle="Kepler data set", y="Value", x="") +
  theme(plot.title = element_text(hjust = 0.5), plot.subtitle = element_text(hjust=0.5) ) +
  facet_wrap(~variable, ncol=3, scales="free")

# after transformation, can now observe unequal distributions by response category for some variables ('koi_period', 'koi_depth', 'koi_insol', etc.); distinct classes may help with model predictions


## linear correlations between response and transformed predictor variables ----

pairs(koi_transform[c(1,2:5)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)")
pairs(koi_transform[c(1,6:9)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)") # transformed 'koi_teq' and 'koi_insol' linearly correlated
pairs(koi_transform[c(1,10:13)], main="Scatterplot Matrices - Quantitative Variables (Kepler data set)") # transformed 'koi_srad' and 'koi_slogg' linearly correlated

cor(koi_transform %>% mutate( koi_pdisposition = ifelse(koi_pdisposition=="CANDIDATE", 1, 0) ))[,1] # no strong linear correlation between response and any predictors

# correlations between transformed predictor variables
corrplot(
  cor( koi_transform[ , -1]),
  method="color", # squares instead of circles
  type = "upper", # upper half only
  addCoef.col="black", # add regression coefficient values
  order = "hclust", # hierarchical clustering order
  tl.col = "black", # text label color
  tl.srt = 45, # text label rotation
  tl.cex = 0.75, # text label size
  diag = FALSE, # remove correlation coefficients from principal diagonal
  number.cex=0.7 )# correlation coefficient text size (cex parameter)

# transformed predictor variables have much higher linear correlations, both positive and negative; variance inflation could be an issue for linear models


## test for multivariate normality of predictors within each response category ----
x_cd_transform = koi_transform[koi_transform$koi_pdisposition == "CANDIDATE", -1]
x_fp_transform = koi_transform[koi_transform$koi_pdisposition == "FALSE POSITIVE", -1]
x_cd_notransform = koi_df[koi_df$koi_pdisposition == "CANDIDATE", -1]
x_fp_notransform = koi_df[koi_df$koi_pdisposition == "FALSE POSITIVE", -1]

mvn(x_cd_transform, mvnTest = "hz")$multivariateNormality
mvn(x_fp_transform, mvnTest = "hz")$multivariateNormality
mvn(x_cd_notransform, mvnTest = "hz")$multivariateNormality
mvn(x_fp_notransform, mvnTest = "hz")$multivariateNormality

# results show predictor variables are not multivariate normal; linear discriminant analysis and quadratic discriminate analysis would not be appropriate for model selection