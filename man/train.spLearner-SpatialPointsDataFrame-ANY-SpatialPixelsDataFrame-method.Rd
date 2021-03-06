% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/train.spLearner.R
\docType{methods}
\name{train.spLearner,SpatialPointsDataFrame,ANY,SpatialPixelsDataFrame-method}
\alias{train.spLearner,SpatialPointsDataFrame,ANY,SpatialPixelsDataFrame-method}
\title{Train a spatial prediction and/or interpolation model using Ensemble Machine Learning}
\usage{

  \S4method{train.spLearner}{SpatialPointsDataFrame,ANY,SpatialPixelsDataFrame}(observations,
  formulaString, covariates, SL.library, family = gaussian(),
  method = "stack.cv", predict.type, super.learner = "regr.glm",
  subsets = 5, lambda = 0.5, cov.model = "exponential",
  subsample = 2000, parallel = "multicore", buffer.dist = FALSE,
  oblique.coords = TRUE, theta.list = seq(0, 180, length.out = 14) *
  pi/180, spc = TRUE, id = NULL, weights = NULL, ...)
}
\arguments{
\item{observations}{SpatialPointsDataFrame.}

\item{formulaString}{ANY.}

\item{covariates}{SpatialPixelsDataFrame.}

\item{SL.library}{List of learners,}

\item{family}{Family e.g. gaussian(),}

\item{method}{Ensemble stacking method (see makeStackedLearner) usually \code{stack.cv},}

\item{predict.type}{Prediction type 'prob' or 'response',}

\item{super.learner}{Ensemble stacking model usually \code{regr.glm},}

\item{subsets}{Number of subsets for repeated CV,}

\item{lambda}{Target variable transformation (0.5 or 1),}

\item{cov.model}{Covariance model for variogram fitting,}

\item{subsample}{For large datasets consider random subsetting training data,}

\item{parallel}{Initiate parellel processing,}

\item{buffer.dist}{Specify whether to use buffer distances to points as covariates,}

\item{oblique.coords}{Specify whether to use oblique coordinates as covariates,}

\item{theta.list}{List of angles (in radians) used to derive oblique coordinates,}

\item{id}{Id column name to control clusters of data,}

\item{weights}{Optional weights (per row) that learners will use to account for variable data quality,}

\item{...}{other arguments that can be passed on to \code{mlr::makeStackedLearner},}
}
\value{
object of class spLearner, which contains fitted model, variogram model and spatial grid
used for Cross-validation.
}
\description{
Automated spatial predictions and/or interpolation using Ensemble Machine Learning. Extends functionality of the \href{https://github.com/mlr-org/mlr}{mlr} package. Suitable for predicting numeric, binomial and factor-type variables.
}
\note{
By default uses oblique coordinates (rotated coordinates) as described in Moller et al. (2019) "Oblique Coordinates as Covariates for Digital Soil Mapping" to account for geographical distribution of values.
Buffer geographical distances can be added by setting \code{buffer.dist=TRUE}.
Using either oblique coordinates and/or buffer distances is not recommended for point data set with distinct spatial clustering.
Effects of adding geographical distances into modeling are explained in detail in \href{https://doi.org/10.7717/peerj.5518}{Hengl et al. (2018)}.
Default learners used for regression are \code{c("regr.ranger", "regr.ksvm", "regr.glmnet", "regr.cubist")}.
Default learners used for classification / binomial variables are \code{c("classif.ranger", "classif.svm", "classif.multinom")}, with \code{predict.type="prob"}.
When using \code{method = "stack.cv"} each training and prediction round could produce somewhat different results due to randomisation of CV.
}
\examples{
library(rgdal)
library(geoR)
library(plotKML)
library(raster)
library(parallelMap)
library(xgboost)
library(kernlab)
library(mlr)
library(deepnet)
library(Cubist)
demo(meuse, echo=FALSE)

## Regression:
m <- train.spLearner(meuse["lead"], covariates=meuse.grid[,c("dist","ffreq")], lambda = 1)
## Ensemble model (meta-learner):
m@spModel$learner.model$super.model$learner.model
meuse.lead <- predict(m)
plot(raster(meuse.lead$pred["response"]), col=R_pal[["rainbow_75"]][4:20], main="spLearner", axes=FALSE, box=FALSE)
points(meuse, pch="+")
plot(raster(meuse.lead$pred["model.error"]), col=rev(bpy.colors()), main="Model error", axes=FALSE, box=FALSE)
points(meuse, pch="+")

## Classification:
SL.library <- c("classif.ranger", "classif.xgboost", "classif.nnTrain")
mC <- train.spLearner(meuse["soil"], covariates=meuse.grid[,c("dist","ffreq")],
   SL.library = SL.library, super.learner = "classif.glmnet")
meuse.soil <- predict(mC)
spplot(meuse.soil$pred[grep("prob.", names(meuse.soil$pred))], col.regions=SAGA_pal[["SG_COLORS_YELLOW_RED"]], zlim=c(0,1))
spplot(meuse.soil$pred[grep("error.", names(meuse.soil$pred))], col.regions=rev(bpy.colors()))

\dontrun{
## SIC1997
data("sic1997")
X <- sic1997$swiss1km[c("CHELSA_rainfall","DEM")]
mR <- train.spLearner(sic1997$daily.rainfall, covariates=X, lambda=1)
rainfall1km <- predict(mR)
par(mfrow=c(1,2), oma=c(0,0,0,1), mar=c(0,0,4,3))
plot(raster(rainfall1km$pred["response"]), col=R_pal[["rainbow_75"]][4:20], main="spLearner", axes=FALSE, box=FALSE)
points(sic1997$daily.rainfall, pch="+")
plot(raster(rainfall1km$pred["model.error"]), col=rev(bpy.colors()), main="Model error", axes=FALSE, box=FALSE)
points(sic1997$daily.rainfall, pch="+")

## Ebergotzen data set
data(eberg_grid)
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
data(eberg)
eb.s <- sample.int(nrow(eberg), 1400)
eberg <- eberg[eb.s,]
coordinates(eberg) <- ~X+Y
proj4string(eberg) <- CRS("+init=epsg:31467")
## Binomial variable
summary(eberg$TAXGRSC)
eberg$Parabraunerde <- ifelse(eberg$TAXGRSC=="Parabraunerde", 1, 0)
X <- eberg_grid[c("PRMGEO6","DEMSRT6","TWISRT6","TIRAST6")]
mB <- train.spLearner(eberg["Parabraunerde"], covariates=X, family=binomial(), cov.model = "nugget")
eberg.Parabraunerde <- predict(mB)
plot(raster(eberg.Parabraunerde$pred["prob.1"]), col=SAGA_pal[["SG_COLORS_YELLOW_RED"]], zlim=c(0,1))
points(eberg["Parabraunerde"], pch="+")

## Factor variable:
data(eberg)
coordinates(eberg) <- ~X+Y
proj4string(eberg) <- CRS("+init=epsg:31467")
X <- eberg_grid[c("PRMGEO6","DEMSRT6","TWISRT6","TIRAST6")]
mF <- train.spLearner(eberg["TAXGRSC"], covariates=X)
TAXGRSC <- predict(mF)
plot(stack(TAXGRSC$pred[grep("prob.", names(TAXGRSC$pred))]), col=SAGA_pal[["SG_COLORS_YELLOW_RED"]], zlim=c(0,1))
}
}
\author{
\href{https://opengeohub.org/people/tom-hengl}{Tom Hengl}
}
