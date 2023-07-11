## --------------------------------------------------------------------------
## FIT SDM

## assertions and preparatory steps -----------------------------------------
if (!exists("climateDT")) {
  stop("climateDT is missing. Please run 'climateData.R'.")
}

if (!exists("sppDataDT")) {
  stop("sppDataDT is missing. Please run 'climateData.R'.")
}

if (!identical(sort(names(sppDataDT)), sort(c("cell", "x", "y", "sppAbund", "year")))) {
  stop(paste("sppDataDT can only have the following columns before fitting the SDM:\n",
             paste(c("cell", "x", "y", "sppAbund", "year"), collapse = ", ")))
}

if (length(setdiff(climateDT$cell, sppDataDT$cell)) > 0 ||
    length(setdiff(sppDataDT$cell, climateDT$cell)) > 0) {
  warning("Species and climate data differ in cell IDs with data. This could be due to post re-projection mismatches")
}

## a few data cleaning steps to make sure we have presences and absences:
if (min(range(sppDataDT$sppAbund)) < 0) {
  sppDataDT[sppAbund < 0, sppAbund := 0]
}

if (!all(unique(sppDataDT$sppAbund) %in% c(0,1))) {
  message("Species data is not binary. Converting to presence/absence")
  sppDataDT[sppAbund > 0, sppAbund := 1]
}

## join the two datasets - note that there are no input species abundances beyond year 1
sdmData <- merge(climateDT, sppDataDT[, .(cell, sppAbund, year)],
                 by = c("cell", "year"), all = TRUE)
setnames(sdmData, "sppAbund", "presAbs")

predVars <- setdiff(names(sdmData), c("cell", "x","y", "year", "presAbs"))
fittingYear <- min(sdmData$year)   ## first year is the baseline

## fit SDM ------------------------------------------------------------------
## subset fitting data
dataForFitting <- sdmData[year == fittingYear]
dataForFitting <- dataForFitting[complete.cases(dataForFitting)]

## break data into training and testing subsets
set.seed(123)
group <- kfold(dataForFitting, 5)
## save the the split datasets as internal objects to this module
trainData <- dataForFitting[group != 1, ]
testData <-  dataForFitting[group == 1, ]

cols <- c(predVars, "presAbs")

message("Tunning and fitting random forest model on 4/5 of the data...")
rfOut <- Cache(tuneRF,
               x = as.data.frame(trainData[, ..predVars]),
               y = as.factor(trainData$presAbs),
               doBest = TRUE,
               cachePath = projPaths$cachePath)
message("Done!")

## evaluate the model
message("Evaluating the model on 1/5 of the data")
predVals <- predict(rfOut, newdata = as.data.frame(testData[, ..predVars]))
presIDs <- which(testData$presAbs == 1)
absIDs <- which(testData$presAbs == 0)

rfEval <- Cache(evaluate,
                p = as.numeric(as.character(predVals[presIDs])),
                a = as.numeric(as.character(predVals[absIDs])),
                cachePath = projPaths$cachePath)
message("Done!")
print(rfEval)

## baseline projection
basineProjRas <- Cache(SDMproj,
                       yr = 2010,
                       predVars = predVars,
                       model = rfOut,
                       data = sdmData,
                       studyAreaRas = studyAreaRas,
                       cachePath = projPaths$cachePath)

png(filename = file.path(projPaths$figPath, "SDMprojections_baseline.png"),
    bg = "white", width = 5, height = 7, units = "in", res = 300)
plotSpatRaster(basineProjRas, plotTitle = "White spruce - baseline projection",
               xlab = "Longitude", ylab = "Latitude", isDiscrete = TRUE)
dev.off()

## save outputs
saveRDS(rfOut, file.path(projPaths$outputsPath, "RFmodel.rds"))

sink(file.path(projPaths$outputsPath, "RFmodel_eval.txt"))
rfEval
sink()

## clear environment of unnecessary objects
rm(dataForFitting, predVals, presIDs, absIDs, cols)
gc(reset = TRUE)
