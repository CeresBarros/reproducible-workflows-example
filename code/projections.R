## --------------------------------------------------------------------------
## PROJECT RANGE CHANGES (per year)

futureYears <- setdiff(sdmData$year, fittingYear)

projStk <- Map(yr = futureYears,
               MoreArgs = list(predVars = predVars,
                               data = sdmData,
                               model = rfOut,
                               studyAreaRas = studyAreaRas),
               f = SDMproj) |>
  rast()

