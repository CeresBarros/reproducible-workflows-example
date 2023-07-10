## --------------------------------------------------------------------------
## SOURCE AND PREP. SPECIES DATA

## code check: does the study area exist?
if (!exists("studyAreaRas")) {
  stop("Please supply a 'studyAreaRas' SpatRaster")
}

sppAbundURL <- paste0("https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/",
                      "canada-forests-attributes_attributs-forests-canada/",
                      "2011-attributes_attributs-2011/",
                      "NFI_MODIS250m_2011_kNN_Species_Pice_Gla_v1.tif")
sppAbundanceRas <- Cache(prepInputs,
                         targetFile = basename(sppAbundURL),
                         url = sppAbundURL,
                         to = studyAreaRas,
                         overwrite = TRUE,
                         cachePath = projPaths$cachePath)

## rename layer
names(sppAbundanceRas) <- "year_2010"  ## use 2010 to match climate data

## convert to a data.table
sppAbundanceDT <- as.data.table(as.data.frame(sppAbundanceRas, xy = TRUE, cells = TRUE))
sppAbundanceDT[, year := as.integer(sub("year_", "", names(sppAbundanceRas)))]
setnames(sppAbundanceDT, names(sppAbundanceRas), "sppAbund")

