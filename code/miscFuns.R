## ---------------------------------------------------------------------
## Plotting functions

#' Function used to plot SpatRaster
#'
#' To be used with Plots
#'
#' @param ras a SpatRaster layer
#' @param title character. Plot title
#' @param xlab character. X-axis title
#' @param ylab character. Y-axis title
#'
#' @importFrom rasterVis gplot
#' @importFrom ggplot2 geom_tile scale_fill_brewer coord_equal theme_bw
plotSpatRaster <- function(ras, plotTitle = "", xlab = "x", ylab = "y") {
  gplot(ras) +
    geom_tile(aes(fill = value)) +
    scale_fill_distiller(palette = "Blues", direction = 1,
                         na.value = "grey90", limits = c(0,1) ) +
    theme_classic() +
    coord_equal() +
    labs(title = plotTitle, x = xlab, y = ylab)
}

#' Function used to plot SpatRaster Stacks
#'
#' To be used with Plots
#'
#' @param stk a SpatRaster stack.
#' @param title character. Plot title
#' @param xlab character. X-axis title
#' @param ylab character. Y-axis title
#'
#' @importFrom rasterVis gplot
#' @importFrom ggplot geom_tile facet_wrap scale_fill_brewer coord_equal
plotSpatRasterStk <-  function(stk, plotTitle = "", xlab = "x", ylab = "y") {
  gplot(stk) +
    geom_tile(aes(fill = value)) +
    scale_fill_distiller(palette = "Blues", direction = 1, na.value = "grey90") +
    theme_classic() +
    coord_equal() +
    facet_wrap(~ variable) +
    labs(title = plotTitle, x = xlab, y = ylab)
}


## ---------------------------------------------------------------------
## ANALYSIS FUNCTIONS

#' Title
#'
#' @param yr year value to subset in `data$year`
#' @param predVars character. Names of predictor columns in `data`
#' @param data `data.table` with predictors (`predVars`), `year` and `cell`
#'   columns.
#' @param model model object used to calculate predictions.
#' @param studyAreaRas a `SpatRaster` of the study area whose cell IDs correspond
#'   to `data$cell`.
#'
#' @return
#' @export
#'
#' @examples
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
