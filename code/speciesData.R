## --------------------------------------------------------------------------
## SOURCE AND PREP. SPECIES DATA

## code check: does the study area exist?
if (!exists("studyAreaRas")) {
  stop("Please supply a 'studyAreaRas' SpatRaster")
}

## download and prepare data
sppAbundURL <- paste0("https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/",
                      "canada-forests-attributes_attributs-forests-canada/",
                      "2011-attributes_attributs-2011/",
                      "NFI_MODIS250m_2011_kNN_Species_Pice_Gla_v1.tif")

## download and prep. data
## prepInputs does all the heavy-lifting of downloading and pre-processing the layer
## (crops and reprojects input data layer to match studyAreaRas) and caches operations
sppDataRas <- Cache(prepInputs,
                         targetFile = basename(sppAbundURL),
                         url = sppAbundURL,
                         to = studyAreaRas,
                         overwrite = TRUE,
                         cachePath = projPaths$cachePath)

## rename layer
names(sppDataRas) <- "year_2010"  ## use 2010 to match climate data

## convert to a data.table
sppDataDT <- as.data.table(as.data.frame(sppDataRas, xy = TRUE, cells = TRUE))
sppDataDT[, year := as.integer(sub("year_", "", names(sppDataRas)))]
setnames(sppDataDT, names(sppDataRas), "sppAbund")

rm(sppAbundURL)
gc(reset = TRUE)
