
## general options
options("reproducible.useGDAL" = FALSE,
        "reproducible.destinationPath" = projPaths$dataPath,
        "reproducible.cachePath" = projPaths$cachePath)


## use British Columbia as a study area
canada <- prepInputs(url = "https://www12.statcan.gc.ca/census-recensement/2021/geo/sip-pis/boundary-limites/files-fichiers/lpr_000b21a_e.zip",
                     destinationPath = projPaths$dataPath)
studyArea <- canada[canada$PRENAME == "British Columbia",]

## rasterize
tempRas <- rast(res = 1000, crs = crs(studyArea, proj = TRUE), extent = ext(studyArea))
studyAreaRas <- rasterize(studyArea, tempRas)
plot(studyAreaRas)

rm(tempRas, studyArea)
gc(reset = TRUE)