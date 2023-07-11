## ---------------------------------------------------------------------
## Plotting functions

#' Plot a `SpatRaster` as a `ggplot`
#'
#'
#' @param ras a SpatRaster layer
#' @param title character. Plot title
#' @param xlab character. X-axis title
#' @param ylab character. Y-axis title
#' @param isDiscrete logical. Should raster data be treated as discrete
#'   or continuous for plotting? If `TRUE` plots will be accompanied with
#'   a colour legend and only existing values. Otherwise, a continuous
#'   colourbar is shown (default).
#'
#' @return a `ggplot`.
#'
#' @importFrom rasterVis gplot
#' @importFrom ggplot2 geom_tile scale_fill_brewer coord_equal theme_bw
plotSpatRaster <- function(ras, plotTitle = "", xlab = "x", ylab = "y", isDiscrete = FALSE) {
  plotOut <- gplot(ras) +
    geom_tile(aes(fill = value))
  plotOut <- if (isDiscrete) {
    vals <- na.omit(unique(as.vector(ras[])))
    plotOut +
      scale_fill_distiller(palette = "Blues", direction = 1,
                           na.value = "grey90", guide = "legend",
                           breaks = vals, limits = vals)
  } else {
    plotOut +
      scale_fill_distiller(palette = "Blues", direction = 1, na.value = "grey90")
  }
  plotOut +
    theme_classic() +
    coord_equal() +
    labs(title = plotTitle, x = xlab, y = ylab, fill = "")
}

#' Plot a `SpatRaster` stack as a `ggplot`
#'
#' @param stk a SpatRaster stack.
#' @param title character. Plot title
#' @param xlab character. X-axis title
#' @param ylab character. Y-axis title
#' @param isDiscrete logical. Should raster data be treated as discrete
#'   or continuous for plotting? If `TRUE` plots will be accompanied with
#'   a colour legend and only existing values. Otherwise, a continuous
#'   colourbar is shown (default).
#'
#' @return a `ggplot`.
#'
#' @importFrom rasterVis gplot
#' @importFrom ggplot geom_tile facet_wrap scale_fill_brewer coord_equal
plotSpatRasterStk <-  function(stk, plotTitle = "", xlab = "x", ylab = "y", isDiscrete = FALSE) {
  plotOut <- gplot(stk) +
    geom_tile(aes(fill = value))
  plotOut <- if (isDiscrete) {
    vals <- na.omit(unique(as.vector(stk[])))
    plotOut +
      scale_fill_distiller(palette = "Blues", direction = 1,
                           na.value = "grey90", guide = "legend",
                           breaks = vals, limits = vals)
  } else {
    plotOut +
      scale_fill_distiller(palette = "Blues", direction = 1, na.value = "grey90")
  }
  plotOut +
    theme_classic() +
    coord_equal() +
    facet_wrap(~ variable) +
    labs(title = plotTitle, x = xlab, y = ylab, fill = "")
}


#' Title
#'
#' @param var character. Climate variable layers to search in
#'   `names(projClimateRas)` and subset.
#' @param projClimateRas SpatRaster. Named tack of climate layers
#'   where names follow the form "^var_"
#' @param figFile character. Path to figure file to save.
#'   Must be .png
#'
#' @return NULL. Saves SpatRaster plots to `figFile`
#' @export
plotClimateRas <- function(var, climateRas, figFile = paste0(var, ".png")){
  ## subset variable layers
  var2 <- paste0("^", var, "_")
  climateRas <- climateRas[[grep(var2, names(climateRas))]]

  ## keep only years in layer names
  names(climateRas) <- sub(var2, "", names(climateRas))
  png(filename = figFile, bg = "white", width = 5, height = 7,
      units = "in", res = 300)
  plotSpatRasterStk(climateRas, plotTitle = var,
                    xlab = "Longitude", ylab = "Latitude") |>
    print()
  dev.off()
}

## ---------------------------------------------------------------------
## ANALYSIS FUNCTIONS

#' Project species distributions to a `SpatRaster`
#'
#' @param yr year value to subset in `data$year`
#' @param predVars character. Names of predictor columns in `data`
#' @param data `data.table` with predictors (`predVars`), `year` and `cell`
#'   columns.
#' @param model model object used to calculate predictions.
#' @param studyAreaRas a `SpatRaster` of the study area whose cell IDs correspond
#'   to `data$cell`.
#'
#' @return a `SpatRaster` with the same properties as `studyAreaRas`
#' @export
SDMproj <- function(yr, predVars, data, model, studyAreaRas) {
  data2 <- data[year == yr]

  if (nrow(data2) == 0) {
    stop(paste("No data for year", yr, "provided to calculate predictions"))
  }

  preds <- predict(model, as.data.frame(data2[, ..predVars]),
                   progress = '')
  studyAreaRas[data2$cell] <- as.numeric(as.character(preds))
  names(studyAreaRas) <- paste0("year", yr)

  return(studyAreaRas)
}
