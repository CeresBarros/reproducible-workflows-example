## --------------------------------------------------------------------------
## SOURCE AND PREP. CLIMATE DATA

## code check: does the study area exist?
if (!exists("studyAreaRas")) {
  stop("Please supply a 'studyAreaRas' SpatRaster")
}

climVars <- c("BIO1", "BIO4", "BIO12", "BIO15")

baselineClimateURLs <- data.table(
  vars = climVars,
  URL = c("https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_2.5m_bio.zip",
          "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_2.5m_bio.zip",
          "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_2.5m_bio.zip",
          "https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_2.5m_bio.zip"),
  targetFile = c("wc2.1_2.5m_bio_1.tif", "wc2.1_2.5m_bio_4.tif",
                 "wc2.1_2.5m_bio_12.tif", "wc2.1_2.5m_bio_15.tif"),
  year = rep(2010, 4)
)

projClimateURLs <- data.table(
  vars = rep(climVars, times = 4),
  URL = rep(c("https://geodata.ucdavis.edu/cmip6/2.5m/CanESM5/ssp585/wc2.1_2.5m_bioc_CanESM5_ssp585_2021-2040.tif",
              "https://geodata.ucdavis.edu/cmip6/2.5m/CanESM5/ssp585/wc2.1_2.5m_bioc_CanESM5_ssp585_2041-2060.tif",
              "https://geodata.ucdavis.edu/cmip6/2.5m/CanESM5/ssp585/wc2.1_2.5m_bioc_CanESM5_ssp585_2061-2080.tif",
              "https://geodata.ucdavis.edu/cmip6/2.5m/CanESM5/ssp585/wc2.1_2.5m_bioc_CanESM5_ssp585_2081-2100.tif"),
            each = 4),
  targetFile = rep(c("wc2.1_2.5m_bioc_CanESM5_ssp585_2021-2040.tif",
                     "wc2.1_2.5m_bioc_CanESM5_ssp585_2041-2060.tif",
                     "wc2.1_2.5m_bioc_CanESM5_ssp585_2061-2080.tif",
                     "wc2.1_2.5m_bioc_CanESM5_ssp585_2081-2100.tif"),
                   each = 4),
  year = rep(c(2030, 2050, 2070, 2090), each = 4)
)


archiveFiles <- sapply(baselineClimateURLs$URL, function(URL) {
  if (grepl("\\.zip$", basename(URL))) {
    basename(URL)
  } else {
    NULL
  }
}, USE.NAMES = FALSE)


if (length(unique(baselineClimateURLs$year)) != 1) {
  stop(paste("'baselineClimateURLs' should all have the same 'year' value,",
             "corresponding to the first year of the simulation"))
}

## download and prep. data
## prepInputs does all the heavy-lifting of downloading and pre-processing the layer
## (crops and reprojects input data layer to match studyAreaRas) and caches operations
baselineClimateRas <- Cache(Map,
                            f = prepInputs,
                            url = baselineClimateURLs$URL,
                            targetFile = baselineClimateURLs$targetFile,
                            archive = archiveFiles,
                            MoreArgs = list(
                              overwrite = TRUE,
                              to = studyAreaRas,
                              cachePath = projPaths$cache),
                            cachePath = projPaths$cache)

names(baselineClimateRas) <- paste0(baselineClimateURLs$vars, "_year", baselineClimateURLs$year)

## make a stack
baselineClimateRas <- rast(baselineClimateRas)

## make a data.table
baselineClimateData <- as.data.table(as.data.frame(baselineClimateRas, xy = TRUE, cells = TRUE))
setnames(baselineClimateData, sub("_year.*", "", names(baselineClimateData))) ## don't need year in names here
baselineClimateData[, year := unique(baselineClimateURLs$year)]

## GET PROJECTED DATA
## make a vector of archive (zip) file names if the url points to one.
archiveFiles <- lapply(projClimateURLs$URL, function(URL) {
  if (grepl("\\.zip$", basename(URL))) {
    basename(URL)
  } else {
    NULL
  }
})

## download data - prepInputs does all the heavy-lifting of downloading and pre-processing the layer and caches.
projClimateRas <- Cache(Map,
                        f = prepInputs,
                        url = projClimateURLs$URL,
                        targetFile = projClimateURLs$targetFile,
                        archive = archiveFiles,
                        MoreArgs = list(
                          overwrite = TRUE,
                          to = studyAreaRas,
                          cachePath = projPaths$cache),
                        cachePath = projPaths$cache)
if (any(sapply(projClimateRas, function(x) is(x, "RasterLayer") | is(x, "RasterStack")))){
  projClimateRas <- lapply(projClimateRas, terra::rast)
}

## These tif files contain all bioclimatic variables in different layers
## so, for each variable, we need to keep only the layer of interest
projClimateRas <- mapply(function(stk, var) {
  lyr <- which(sub(".*_", "BIO", names(projClimateRas[[1]])) == var)
  return(stk[[lyr]])
}, stk = projClimateRas, var = projClimateURLs$vars)
names(projClimateRas) <- paste0(projClimateURLs$vars, "_year", projClimateURLs$year)

## make a stack
projClimateRas <- rast(projClimateRas)

## make a data.table
projClimateData <- as.data.table(as.data.frame(projClimateRas, xy = TRUE, cells = TRUE))

## melt so that year is in a column
projClimateDataMolten <- lapply(unique(projClimateURLs$vars), function(var, projClimateData) {
  cols <- grep(paste0(var, "_year"), names(projClimateData), value = TRUE)
  idCols <- names(projClimateData)[!grepl("_year", names(projClimateData))]

  moltenDT <-  melt(projClimateData, id.vars = idCols, measure.vars = cols,
                    variable.name = "year", value.name = var)
  moltenDT[, year := sub(paste0(var, "_year"), "", year)]
  moltenDT[, year := as.integer(year)]
  return(moltenDT)
}, projClimateData = projClimateData)

idCols <- c(names(projClimateData)[!grepl("_year", names(projClimateData))], "year")
projClimateDataMolten <- lapply(projClimateDataMolten, function(DT, cols) {
  setkeyv(DT, cols = cols)
  return(DT)
}, cols = idCols)

projClimateData <- Reduce(merge, projClimateDataMolten)

## assertions
if (!identical(sort(names(baselineClimateData)), sort(names(projClimateData)))) {
  stop("Variable names in `projClimateURLs` differ from those in `baselineClimateURLs`")
}

## check
if (!compareGeom(baselineClimateRas, projClimateRas, res = TRUE, stopOnError = FALSE)) {
  stop("`baselineClimateRas` and `projClimateRas` do not have the same raster properties")
}

## now bind
climateDT <- rbindlist(list(baselineClimateData, projClimateData), use.names = TRUE)

## plots
Map(var = climVars,
    figFile = file.path(projPaths$figPath, paste0(climVars, ".png")),
    MoreArgs = list(climateRas = c(baselineClimateRas, projClimateRas)),
    f = plotClimateRas)

rm(baselineClimateURLs, projClimateURLs)
gc(reset = TRUE)