
## general options
options("reproducible.useGDAL" = FALSE,
        "reproducible.destinationPath" = projPaths$dataPath,
        "reproducible.cachePath" = projPaths$cachePath)

## dismo needs a few tweaks to run MaxEnt
## Download maxent.jar
maxentFile <- preProcess(targetFile = "maxent.jar",
                         url = "https://github.com/mrmaxent/Maxent/blob/master/ArchivedReleases/3.4.4/maxent.jar?raw=true",
                         destinationPath = projPaths$dataPath,
                         fun = NA)
## copy it to the dismo library.
file.copy(from = maxentFile$targetFilePath,
          to = file.path(system.file("java", package = "dismo"), "maxent.jar"))


## use British Columbia as a study area
canada <- prepInputs(url = "https://www12.statcan.gc.ca/census-recensement/2021/geo/sip-pis/boundary-limites/files-fichiers/lpr_000b21a_e.zip",
                     destinationPath = projPaths$dataPath)
studyArea <- canada[canada$PRENAME == "British Columbia",]
studyArea <- aggregate(studyArea, by = "PRENAME")

## rasterize
tempRas <- rast(res = 1000, crs = crs(studyArea, proj = TRUE), extent = ext(studyArea))
studyAreaRas <- rasterize(studyArea, tempRas)
plot(studyAreaRas)

rm(tempRas)
