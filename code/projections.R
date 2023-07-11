## --------------------------------------------------------------------------
## PROJECT RANGE CHANGES (per year)

futureYears <- setdiff(sdmData$year, fittingYear)

futureProjStk <- Map(yr = futureYears,
                     MoreArgs = list(predVars = predVars,
                                     data = sdmData,
                                     model = rfOut,
                                     studyAreaRas = studyAreaRas),
                     f = SDMproj) |>
  rast()

png(filename = file.path(projPaths$figPath, "SDMprojections_future.png"),
    bg = "white", width = 5, height = 7, units = "in", res = 300)
plotSpatRasterStk(futureProjStk, plotTitle = "White spruce - future projections",
                  xlab = "Longitude", ylab = "Latitude", isDiscrete = TRUE)
dev.off()
