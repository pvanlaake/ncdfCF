#' @include ncdfObject.R
NULL

#' Base dimension object
#'
#' The 'dimension' is one of the key building blocks of a data set in an netCDF
#' resource. This virtual class contains the common functionality of all
#' dimension classes. Instantiable sub-classes include `ncdfDimensionNumeric` for
#' numeric dimension values, and `ncdfDimensionTime` for "time"
#' dimensions.
#'
#' @slot grp The `ncdfGroup` that this dimension belongs to.
#' @slot var_id The ID of the dimension variable if read from file.
#' @slot var_type The type of the dimension variable on file.
#' @slot length The number of elements in the dimension.
#' @slot unlim Flag to indicate whether this dimension is unlimited, e.g. can be
#' extended beyond the current 'length'.
#' @slot axis The axis of the dimension, if known.
setClass("ncdfDimension",
  contains = c("VIRTUAL", "ncdfObject"),
  slots = c(
    grp        = "ncdfObject",
    var_id     = "integer",
    var_type   = "character",
    length     = "integer",
    unlim      = "logical",
    axis       = "character"
  ),
  prototype = list(
    length     = -1L,
    unlim      = FALSE,
    axis       = ""
  )
)

#' @rdname showObject
#' @export
setMethod("shard", "ncdfDimension", function (object) {
  unlim <- if (object@unlim) "U" else ""
  bnds  <- if (has_bounds(object)) "B" else ""
  props <- paste0(object@axis, unlim, bnds)

  s <- paste0("[", object@id, ": ", object@name, " (", object@length)
  if (nzchar(props)) s <- paste0(s, "-", props)
  paste0(s, ')]')
})

#' @name dimnames
#' @title Dimnames of an `ncdfObject` instance
#'
#' @description Retrieve the dimension names of an `ncdfCF` object. The return
#' value differs depending on the type of object:
#' * `ncdfDataset`, `ncdfVariable`: The dimnames are returned as a vector of the
#' names of the dimensions of the dataset or variable. Note that this differs
#' markedly from the `base::dimnames()` functionality.
#' * `ncdfDimensionNumeric`: The values of the elements along the dimension as a
#' numeric vector.
#' * `ncdfDimensionCharacter`: The values of the elements along the dimension as
#' a character vector.
#' * `ncdfDimensionTime`: The values of the elements along the dimension as a
#' character vector containing timestamps in ISO8601 format. This could be dates
#' or date-times if time information is available in the dimension.
#' * `ncdfDimensionDiscrete`: The index values of the dimension, from 1 to the
#' length of the dimension.
#'
#' @param x An `ncdfObject` whose dimension names to retrieve. This could be
#' `ncdfDataset`, `ncdfVariable`, or a class descending from `ncdfDimension`.
#'
#' @returns A vector as described in the Description section.
#' @examples
#' fn <- system.file("extdata",
#'   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#'
#' # ncdfDataset
#' dimnames(ds)
#'
#' # ncdfVariable
#' pr <- ds[["pr"]]
#' dimnames(pr)
#'
#' # ncdfDimensionNumeric
#' lon <- ds[["lon"]]
#' dimnames(lon)
#'
#' # ncdfDimensionTime
#' t <- ds[["time"]]
#' dimnames(t)
NULL

#' Length of the dimension
#'
#' @param x The `ncdfDimension` to query.
#'
#' @returns Integer scalar of the length of the dimension.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' time <- ds[["time"]]
#' length(time)
setMethod("length", "ncdfDimension", function (x) x@length)

#' Retrieve the axis of a dimension
#'
#' This method retrieves the axis of the dimension.
#'
#' @param x The `ncdfDimension` to query.
#'
#' @returns A character to indicate which of axes "X", "Y", "Z", or "T" is
#'   associated with the dimension, or `NA` if no axis is assigned to the
#'   dimension.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' time <- ds[["time"]]
#' axis(time)
setGeneric("axis", function(x) standardGeneric("axis"), signature = "x")

#' @rdname axis
#' @export
setMethod("axis", "ncdfDimension", function (x) x@axis)

#' Does the dimension have bounds?
#'
#' This method indicates if the dimension has bounds set.
#'
#' @param x An instance of an `ncdfDimension` descendant class.
#'
#' @returns `TRUE` if bounds are set, `FALSE` otherwise
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' time <- ds[["time"]]
#' has_bounds(time)
setGeneric("has_bounds", function(x) standardGeneric("has_bounds"), signature = "x")

#' @rdname has_bounds
#' @export
setMethod("has_bounds", "ncdfDimension", function(x) FALSE)

#' Get the full time specification of the dimension
#'
#' This method returns `NULL`. Class `ncdfDimensionTime` implements this method
#' more usefully.
#'
#' @param x A `ncdfDimension` instance.
#'
#' @returns `NULL`
#' @export
#'
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' time(ds[["lon"]])
setMethod("time", "ncdfDimension", function(x) NULL)

#' @name indexOf
#' @title Find indices in the dimension domain
#'
#' @description
#' Given a vector of numerical, timestamp or categorical values `x`, find their
#' indices in the values of dimension `y`. With `method = "constant"` this
#' returns the index of the value lower than the supplied values in `x`. With
#' `method = "linear"` the return value includes any fractional part.
#'
#' If bounds are set on the numerical or time dimension, the indices are taken
#' from those bounds. Returned indices may fall in between bounds if the latter
#' are not contiguous, with the exception of the extreme values in `x`.
#'
#' @param x Vector of numeric, timestamp or categorial values to find dimension
#' indices for. The timestamps can be either character, POSIXct or Date vectors.
#' The type of the vector has to correspond to the type of `y`.
#' @param y An instance of `ncdfDimensionNumeric`, `ncdfDimensionTime` or
#' `ncdfDimensionCharacter`.
#' @param method Single value of "constant" or "linear".
#'
#' @returns Numeric vector of the same length as `x`. If `method = "constant"`,
#'   return the index value for each match. If `method = "linear"`, return the
#'   index value with any fractional value. Values of `x` outside of the range
#'   of the values in `y` are returned as `0` and `.Machine$integer.max`,
#'   respectively.
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' lon <- ds[["lon"]]
#' indexOf(c(8.5, 8.9, 9.3, 9.7, 10.1), lon)
#' indexOf(c(8.5, 8.9, 9.3, 9.7, 10.1), lon, "linear")
#'
#' time <- ds[["time"]]
#' indexOf(c("2024-03-01", "2024-03-02"), time)
NULL

#' Read a dimension from a resource
#'
#' Depending on the type of the dimension, either an `ncdfDimensionNumeric` is
#' returned, for numerical dimensions, or a `ncdfDimensionTime` for "time"
#' dimensions.
#'
#' @param grp The `ncdfGroup` that this dimension belongs to.
#' @param did Dimension ID value within the group.
#'
#' @returns Either a `ncdfDimension` instance of the appropriate subclass, or an
#' error.
#' @noRd
.readDimension <- function (grp, did) {
  err <- try({
    h <- handle(grp)
    dmeta <- RNetCDF::dim.inq.nc(h, did)

    # Get some dimension variable metadata
    dvar <- try(RNetCDF::var.inq.nc(h, dmeta$name), silent = TRUE)
    if (inherits(dvar, "try-error"))
      return(methods::new("ncdfDimensionDiscrete", id = as.integer(dmeta$id),
                          name = dmeta$name, grp = grp,
                          length = as.integer(dmeta$length), unlim = dmeta$unlim,
                          var_id = -1L, var_type = "NC_INT"))

    # Dimension values
    vals <- as.vector(RNetCDF::var.get.nc(h, dmeta$name))

    # If no attributes, then nothing more to do
    if (!dvar$natts)
      if (dvar$type %in% c("NC_CHAR", "NC_STRING"))
        return(methods::new("ncdfDimensionCharacter", id = as.integer(dmeta$id),
                            name = dmeta$name, grp = grp,
                            length = as.integer(dmeta$length), unlim = dmeta$unlim,
                            var_id = dvar$id, var_type = dvar$type, values = vals))
      else
        return(methods::new("ncdfDimensionNumeric", id = as.integer(dmeta$id),
                            name = dmeta$name, grp = grp,
                            length = as.integer(dmeta$length), unlim = dmeta$unlim,
                            var_id = dvar$id, var_type = dvar$type, values = round(vals, 5)))

    # Get the attributes and interpret the type of dimension
    atts <- do.call(rbind, lapply(0L:(dvar$natts - 1L), function (a) as.data.frame(RNetCDF::att.inq.nc(h, dmeta$name, a))))
    atts$value <- sapply(0L:(dvar$natts - 1L), function (a) RNetCDF::att.get.nc(h, dmeta$name, a))

    # See if we have a "units" attribute that makes time
    units <- atts[which(atts$name == "units"), ]$value
    if (length(units)) {
      cal <- atts[which(atts$name == "calendar"), ]$value
      if (!length(cal)) cal <- "standard"
      cf <- try(CFtime::CFtime(units, cal, vals), silent = TRUE)
    } else cf <- NA

    # Get the bounds, if set
    bv <- atts[which(atts$name == "bounds"), ]$value
    if (length(bv)) {
      bnds <- try(RNetCDF::var.get.nc(h, bv), silent = TRUE)
      if (length(dim(bnds)) == 3L) bnds <- bnds[, , 1] # Sometimes there is a 3rd dimension
      if (inherits(bnds, "try-error")) bnds <- NULL
    } else bnds <- NULL

    # Create the dimension
    if (methods::is(cf, "CFtime")) {
      if (!is.null(bnds)) CFtime::bounds(cf) <- bnds
      return(methods::new("ncdfDimensionTime", id = as.integer(dmeta$id),
                          name = dmeta$name, grp = grp,
                          length = as.integer(dmeta$length), unlim = dmeta$unlim,
                          var_id = dvar$id, var_type = dvar$type,
                          attributes = atts, values = cf, axis = "T"))
    }

    if (dvar$type %in% c("NC_CHAR", "NC_STRING")) {
      dim <- methods::new("ncdfDimensionCharacter", id = as.integer(dmeta$id),
                          name = dmeta$name, grp = grp,
                          length = as.integer(dmeta$length), unlim = dmeta$unlim,
                          var_id = dvar$id, var_type = dvar$type,
                          attributes = atts, values = vals)
    } else {
      dim <- methods::new("ncdfDimensionNumeric", id = as.integer(dmeta$id),
                          name = dmeta$name, grp = grp,
                          length = as.integer(dmeta$length), unlim = dmeta$unlim,
                          var_id = dvar$id, var_type = dvar$type,
                          attributes = atts, values = round(vals, 5))
      if (!is.null(bnds)) dim@bounds <- bnds
    }

    # Axis
    axis <- attribute(dim, "axis")
    if (length(axis)) dim@axis <- axis
    else {
      if (length(units)) {
        if (grepl("^degree(s?)(_?)(east|E)$", units)) dim@axis <- "X"
        else if (grepl("^degree(s?)(_?)(north|N)$", units)) dim@axis <- "Y"
      }
    }
    if (dim@axis == "") {
      # Last option: standard_name
      # Only X and Y as Z too broad to automatically interpret, needs operator knowledge
      standard <- attribute(dim, "standard_name")
      if (length(standard)) {
        if (standard == "longitude") dim@axis <- "X"
        else if (standard == "latitude") dim@axis <- "Y"
      }
    }
  }, silent = TRUE)

  if (inherits(err, "try-error")) err else dim
}

#' Bare bones shared dimension details
#' @noRd
str_dimension <- function(object, ...) {
  cat("  ..@ id        :"); str(object@id)
  cat("  ..@ name      :"); str(object@name)
  cat("  ..@ var_id    :"); str(object@var_id)
  cat("  ..@ var_type  :"); str(object@var_type)
  cat("  ..@ length    :"); str(object@length)
  cat("  ..@ unlim     :"); str(object@unlim)
  cat("  ..@ axis      :"); str(object@axis)
}
