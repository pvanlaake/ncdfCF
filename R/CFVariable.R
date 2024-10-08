# A data variable has dimensions
# Defining attributes: ancillary_variables, cell_methods, coordinate_interpolation,
# coordinates, flag_masks, flag_meanings, flag_values, grid_mapping
# Forbidden attributes: "dimensions", "geometry_type"

#' CF data variable
#'
#' @description This class represents a CF data variable, the object that
#'   provides access to an array of data.
#'
#' @details The CF data variable instance provides access to the data array from
#' the netCDF resource, as well as all the details that have been associated
#' with the data variable, such as axis information, grid mapping parameters,
#' etc.
#'
#' @docType class
#' @export
CFVariable <- R6::R6Class("CFVariable",
  inherit = CFObject,
  private = list(
    llgrid = NULL,

    .varProperties = function() {
      unit <- self$attribute("units")
      if (!nzchar(unit)) unit <- ""
      longname <- self$attribute("long_name")
      if (!nzchar(longname)) longname <- ""
      if (longname == self$name) longname <- ""
      list(longname = longname, unit = unit)
    },

    # Turn the rng argument into index values into the axis.
    range2index = function(axis, rng, closed) {
      axl <- axis$length
      if (inherits(axis, "CFAxisTime")) {
        idx <- axis$indexOf(rng, method = "linear", closed)
        if (!length(idx)) return(NULL)
        idx <- range(idx)
      } else if (inherits(axis, "CFAxisCharacter")) {
        idx <- range(match(rng, axis$values))
      } else {
        if (length(rng) == 1L) closed <- TRUE
        rng <- range(rng)
        vals <- axis$values
        idx <- if (closed)
          which(vals >= rng[1L] & vals <= rng[2L], arr.ind = TRUE)
        else
          which(vals >= rng[1L] & vals < rng[2L], arr.ind = TRUE)
        if (!length(idx)) return(NULL)
        else idx <- range(idx)
        if (!closed && isTRUE(all.equal(vals[idx[2L]], rng[2L])))
          idx[2L] <- idx[2L] - 1L
      }
      as.integer(idx)
    },

    # Do the auxiliary grid interpolation. Argument "subset" is passed from the
    # subset() function. Argument "lonlat" is an AOI, if supplied by the caller
    # to subset(). Return a list of useful objects to subset().
    auxiliary_interpolation = function(subset, lonlat) {
      # This code assumes that the grid orientation of the data variable is the
      # same as that of the longitude-latitude grid

      private$llgrid$aoi <- if (is.null(lonlat)) {
        ext <- private$llgrid$extent
        Xrng <- if (length(subset$X)) range(subset$X) else ext[1:2]
        Yrng <- if (length(subset$Y)) range(subset$Y) else ext[3:4]
        aoi(Xrng[1L], Xrng[2L], Yrng[1L], Yrng[2L])
      } else lonlat

      index <- private$llgrid$grid_index()
      dim_index <- dim(index)

      # The below appears counter-intuitive (XY relationship to indices) but it
      # works for long-lat grids that use the recommended X-Y-Z-T axis ordering.
      # Report any problems to https://github.com/pvanlaake/ncdfCF/issues
      dim_ll <- private$llgrid$dim
      xyidx <- arrayInd(index, dim_ll)          # convert indices to row,column
      rx <- range(xyidx[, 2L], na.rm = TRUE)    # full range of columns
      xyidx[, 2L] <- xyidx[, 2L] - rx[1L] + 1L  # reduce columns to 1-based
      cols <- rx[2L] - rx[1L] + 1L              # no of columns in reduced grid
      ry <- range(xyidx[, 1L], na.rm = TRUE)    # full range of rows
      xyidx[, 1L] <- xyidx[, 1L] - ry[1L] + 1L  # reduce rows to 1-based
      rows <- ry[2L] - ry[1L] + 1L              # no of rows in reduced grid
      index <- rows * (xyidx[, 2L] - 1L) + xyidx[, 1L] # reduced index value

      # index = the index values into the reduced grid
      # X,Y = start and count values for data to read
      # aoi = the AOI that was used to index
      # box = the dim of the original index
      list(index = index, X = c(ry[1L], rows), Y = c(rx[1L], cols), aoi = private$llgrid$aoi, box = dim_index)
    },

    # Return the axis information from this variable to construct a WKT2 string
    # of the CRS of this variable. Returns a list with relevant information.
    # In the EPSG database, X and Y UOMs are always the same. Hence only one UOM
    # is reported back.
    # Furthermore, axis order is considered important only in the context of
    # providing coordinated tuples to a coordinate transformation engine,
    # something this package is not concerned with. Consequently, axis order is
    # always reported as the standard X,Y. R packages like terra and stars deal
    # with the idiosyncracies of R arrays. This has been tested with the
    # results of [CFData] functions.
    # This method may be extended in the future to inject more intelligence into
    # the WKT2 strings produced. Currently it just returns the "units" string of
    # the X axis (the Y axis has the same unit), and the Z axis, if present, in
    # a list.
    wkt2_axis_info = function() {
      # Horizontal axes unit
      x_attributes <- c("projection_x_coordinate", "grid_longitude", "projection_x_angular_coordinate")
      ax <- lapply(self$axes, function(x) {
        if (x$attribute("standard_name") %in% x_attributes) x
      })
      ax <- ax[lengths(ax) > 0L]
      horz <- if (length(ax) > 0L) list(LENGTHUNIT = ax[[1L]]$attribute("units"))
              else list()

      # Vertical axes unit
      z <- sapply(self$axes, function(x) x$orientation)
      ndx <- which(z == "Z")
      vert <- if (length(ndx)) {
        z <- self$axes[[ndx]]
        if (inherits(z, "CFAxis")) list(VERTINFO = z$attribute(c("standard_name", "positive", "units")))
        else list()
      } else list()
      c(horz, vert)
    }
  ),
  public = list(
    #' @field group The [NCGroup] that this variable is defined in.
    group = NULL,

    #' @field axes List of instances of classes descending from [CFAxis] that
    #'   are the axes of the variable.
    axes  = list(),

    #' @field grid_mapping The [CFGridMapping] of this variable. If this field
    #' is `NULL`, the horizontal component of the axes are in decimal degrees of
    #' longitude and latitude.
    grid_mapping = NULL,

    #' @description Create an instance of this class.
    #'
    #' @param grp The group that this CF variable lives in.
    #' @param nc_var The netCDF variable that defines this CF variable.
    #' @param axes List of [CFAxis] instances that describe the dimensions.
    #' @return An instance of this class.
    initialize = function(grp, nc_var, axes) {
      super$initialize(nc_var)
      self$group <- grp
      self$axes <- axes

      nc_var$CF <- self
    },

    #' @description Print a summary of the data variable to the console.
    print = function() {
      cat("<Variable>", self$name, "\n")
      if (self$group$name != "/")
        cat("Group    :", self$group$name, "\n")

      longname <- self$attribute("long_name")
      if (nzchar(longname) && longname != self$name)
        cat("Long name:", longname, "\n")

      if (!is.null(self$grid_mapping)) {
        cat("\nGrid mapping:\n")
        print(.slim.data.frame(self$grid_mapping$brief(), 50L), right = FALSE, row.names = FALSE)
      }

      cat("\nAxes:\n")
      axes <- do.call(rbind, lapply(self$axes, function(a) a$brief()))
      axes <- lapply(axes, function(c) if (all(c == "")) NULL else c)
      if (all(axes$group == "/")) axes$group <- NULL
      axes <- as.data.frame(axes[lengths(axes) > 0L])
      print(.slim.data.frame(axes, 50L), right = FALSE, row.names = FALSE)

      if (!is.null(private$llgrid)) {
        cat("\nAuxiliary longitude-latitude grid:\n")
        ll <- private$llgrid$brief()
        print(.slim.data.frame(ll, 50L), right = FALSE, row.names = FALSE)
      }

      self$print_attributes()
    },

    #' @description Some details of the data variable
    #'
    #' @return A 1-row `data.frame` with some details of the data variable.
    brief = function() {
      props <- private$.varProperties()
      ax <- sapply(self$axes, function(x) x$name)
      data.frame(group = self$group$fullname, name = self$name,
                 long_name = props$longname, units = props$unit,
                 data_type = self$NCvar$vtype, axes = paste(ax, collapse = ", "))
    },

    #' @description Very concise information on the variable
    #'
    #' The information returned by this function is very concise and most useful
    #' when combined with similar information from other variables.
    #'
    #' @return Character string with very basic variable information.
    shard = function() {
      self$NCvar$shard()
    },

    #' @description Retrieve all data of the variable. Scalar variables are not
    #' present in the result.
    #'
    #' @return A [CFData] instance with all data from this variable.
    data = function() {
      out_group <- MemoryGroup$new(-1L, "Memory_group", "/Memory_group", NULL,
                                   paste("Data copy of variable", self$name),
                                   paste0(format(Sys.time(), "%FT%T%z"), " R package ncdfCF(", packageVersion("ncdfCF"), ")::data()"))
      axes <- lapply(self$axes, function(ax) ax$clone())
      d <- RNetCDF::var.get.nc(self$NCvar$group$handle, self$name, collapse = FALSE, unpack = TRUE, fitnum = TRUE)
      atts <- self$attributes
      atts <- atts[!(atts$name == "coordinates"), ]

      CFData$new(self$name, out_group, d, axes, self$crs, atts)
    },

    #' @description Extract data from the variable
    #'
    #' @details
    #' The `subset()` method extracts a subset of values from the array of the
    #' variable, with the range along each axis to extract expressed in values
    #' of the domain of each axis.
    #'
    #' The range of values along each axis to be subset is expressed in values
    #' of the domain of the axis. Any axes for which no information is
    #' provided in the `subset` argument are extracted in whole. Values can be
    #' specified in a variety of ways that are specific to the nature of the
    #' axis. For numeric axes it should (resolve to) be a vector of real
    #' values. A range (e.g. `100:200`), a long vector (`c(23, 46, 3, 45, 17`),
    #' a sequence (`seq(from = 78, to = 100, by = 2`), all work. Note, however,
    #' that only a single range is generated from the vector so these examples
    #' resolve to `100:200`, `3:46`, and `78:100`, respectively. For time axes a
    #' vector of character timestamps, `POSIXct` or `Date` values must be
    #' specified. As with numeric values, only the two extreme values in the
    #' vector will be used.
    #'
    #' If the range of values for an axis in argument `subset` extend the valid
    #' range of the axis in `x`, the extracted slab will start at the beginning
    #' for smaller values and extend to the end for larger values. If the
    #' values envelope the valid range the entire axis will be extracted in
    #' the result. If the range of `subset` values for any axis are all either
    #' smaller or larger than the valid range of the axis in `x` then nothing
    #' is extracted and `NULL` is returned.
    #'
    #' The extracted data has the same dimensional structure as the data in the
    #' variable, with degenerate dimensions dropped. The order of the axes in
    #' argument `subset` does not reorder the axes in the result.
    #'
    #' As an example, to extract values of a variable for Australia for the year
    #' 2020, where the first axis in `x` is the longitude, the second
    #' axis is the latitude, both in degrees, and the
    #' third (and final) axis is time, the values are extracted by
    #' `x$subset(list(X = c(112, 154), Y = c(-9, -44), T = c("2020-01-01", "2021-01-01")))`.
    #' You could take the longitude-latitude values from `sf::st_bbox()` or
    #' `terra::ext()` if you have specific spatial geometries for whom you want to
    #' extract data. Note that this works equally well for projected coordinate
    #' reference systems - the key is that the specification in argument `subset`
    #' uses the same domain of values as the respective axes in `x` use.
    #'
    #' ## Auxiliary coordinate variables:
    #'
    #' A special case exists for variables where the horizontal dimensions (X
    #' and Y) are not in longitude and latitude values but in some other
    #' coordinate system. In this case the netCDF resource may have so-called
    #' *auxiliary coordinate variables* for longitude and latitude that are two
    #' grids with the same dimension as the horizontal axes of the data variable
    #' where each pixel gives the corresponding value for the longitude and
    #' latitude. If the variable has such *auxiliary coordinate variables* then
    #' they will be used automatically if, and only if, the axes are labeled in
    #' argument `subset` as `X` and `Y`. The resolution of the grid that is
    #' produced by this method is automatically calculated. If you want to
    #' subset those axes then specify values in decimal degrees; if you want to
    #' extract the full extent, specify `numeric(0)`. **Note** that if
    #' you want to extract the data in the original grid, you should use the
    #' horizontal axis names in argument `subset`.
    #'
    #' @param subset A list with the range to extract from each axis. The
    #' list should have elements for the axes to extract a subset from - if an
    #' axis is not present in the list the entire axis will be extracted
    #' from the array. List element names should be the axis designator `X`, `Y`,
    #' `Z` or `T`, or the name of the axis - axes without an axis designator
    #' and any additional axes beyond the four standard ones can only
    #' be specified by name. Axis designators and names are case-sensitive and
    #' can be specified in any order. If values for the range per axis fall
    #' outside of the extent of the axis, the range is clipped to the extent of
    #' the axis.
    #' @param lonlat Optional, an area-of-interest created with the [aoi()]
    #' function to indicate the horizontal area that should be extracted. The
    #' longitude and latitude coordinates must be included; the X and Y
    #' resolution will be calculated if not given. When provided, this argument
    #' will take precedence over the corresponding axis information for the X
    #' and Y axes in the `subset` argument.
    #' @param rightmost.closed Single logical value to indicate if the upper
    #' boundary of range in each axis should be included.
    #' @param ... Ignored. Included to avoid "unused argument" errors on
    #' argument `rightmost.closed`.
    #'
    #' @return An [CFData] instance, having an array with its axes and
    #' attributes of the variable, or `NULL` if one or more of the elements in
    #' the `subset` argument falls entirely outside of the range of the axis.
    #' Note that degenerate dimensions (having `length(.) == 1`) are dropped
    #' from the array but the corresponding axis is maintained in the result as
    #' a scalar axis.
    #'
    #' @aliases CFVariable$subset
    #'
    subset = function(subset, lonlat = NULL, rightmost.closed = FALSE, ...) {
      num_axes <- length(self$axes)
      if (!num_axes)
        stop("Cannot subset a scalar variable")
      if (!is.null(lonlat) && is.null(lonlat$lonMin))
        stop("Argument `lonlat` must have coordinates set")

      axis_names <- names(self$axes)
      orientations <- sapply(self$axes, function(a) a$orientation)
      axis_order <- match(c("X", "Y", "Z", "T"), orientations)
      names(axis_order) <- c("X", "Y", "Z", "T")

      sub_names <- names(subset)

      if (all(c("X", "Y") %in% sub_names) && inherits(private$llgrid, "CFAuxiliaryLongLat")) {
        aux <- private$auxiliary_interpolation(subset, lonlat)
        sub_names <- sub_names[!grepl("X|Y", sub_names)]
      } else aux <- NULL

      bad <- sub_names[!(sub_names %in% c(axis_names, orientations))]
      if (length(bad))
        stop("Argument `subset` contains elements not corresponding to an axis:", paste(bad, collapse = ", "))

      out_group <- MemoryGroup$new(-1L, "Memory_group", "/Memory_group", NULL,
                                   paste("Processing result of variable", self$name),
                                   paste0(format(Sys.time(), "%FT%T%z"), " R package ncdfCF(", packageVersion("ncdfCF"), ")::subset()"))

      start <- rep(1L, num_axes)
      count <- rep(NA_integer_, num_axes)
      ZT_dim <- vector("integer")
      out_axes_dim <- list()
      out_axes_other <- list()
      for (ax in 1:num_axes) {
        axis <- self$axes[[ax]]

        if (!is.null(aux) && orientations[ax] == "X") {
          start[ax] <- aux$X[1L]
          count[ax] <- aux$X[2L]
          var <- NCVariable$new(-1L, private$llgrid$varLong$name, out_group, "NC_DOUBLE", 1L, NULL)
          var$attributes <- private$llgrid$varLong$attributes
          out_axis <- if (aux$X[2L] == 1L)
            CFAxisScalar$new(out_group, var, "X", aux$aoi$dimnames[[2L]])
          else {
            dim <- NCDimension$new(-1L, private$llgrid$varLong$name, aux$aoi$dim[2L], FALSE)
            newax <- CFAxisLongitude$new(out_group, var, dim, aux$aoi$dimnames[[2L]])
            newax$bounds <- aux$aoi$bounds(out_group)$lon
            newax
          }
        } else if (!is.null(aux) && orientations[ax] == "Y") {
          start[ax] <- aux$Y[1L]
          count[ax] <- aux$Y[2L]
          var <- NCVariable$new(-1L, private$llgrid$varLat$name, out_group, "NC_DOUBLE", 1L, NULL)
          var$attributes <- private$llgrid$varLat$attributes
          out_axis <- if (aux$X[2L] == 1L)
            CFAxisScalar$new(out_group, var, "Y", aux$aoi$dimnames[[1L]])
          else {
            dim <- NCDimension$new(-1L, private$llgrid$varLat$name, aux$aoi$dim[1L], FALSE)
            newax <- CFAxisLatitude$new(out_group, var, dim, aux$aoi$dimnames[[1L]])
            newax$bounds <- aux$aoi$bounds(out_group)$lat
            newax
          }
        } else { # No auxiliary coordinates
          rng <- NULL
          if (!is.null(lonlat))
            rng <- if (orientations[ax] == "X") c(lonlat[1L], lonlat[2L])
                   else if (orientations[ax] == "Y") c(lonlat[3L], lonlat[4L])
          if (is.null(rng)) rng <- subset[[ axis_names[ax] ]]
          if (is.null(rng)) rng <- subset[[ orientations[ax] ]]
          if (is.null(rng)) {
            ZT_dim <- c(ZT_dim, axis$length)
            out_axis <- axis$sub_axis(out_group, NULL)
          } else {
            idx <- private$range2index(axis, rng, rightmost.closed)
            if (is.null(idx)) return(NULL)
            start[ax] <- idx[1L]
            count[ax] <- idx[2L] - idx[1L] + 1L
            ZT_dim <- c(ZT_dim, count[ax])
            out_axis <- axis$sub_axis(out_group, idx)
          }
        }

        # Collect axes for result
        if (inherits(out_axis, "CFAxisScalar"))
          out_axes_other <- append(out_axes_other, out_axis)
        else
          out_axes_dim <- append(out_axes_dim, out_axis)
      }

      # Read the data, index as required
      d <- RNetCDF::var.get.nc(self$NCvar$group$handle, self$name, start, count, unpack = TRUE, fitnum = TRUE)
      if (!is.null(aux)) {
        dim(d) <- c(aux$X[2L] * aux$Y[2L], prod(ZT_dim))
        d <- d[aux$index, ]
        dim(d) <- c(aux$box, ZT_dim)
      }
      d <- drop(d)

      # Sanitize the attributes for the result, as required
      atts <- self$attributes
      atts <- atts[!(atts$name == "coordinates"), ]     # drop: these have been set in axes

      # Get a proper CRS
      if (is.null(aux)) crs <- self$crs
      else {
        atts <- atts[!(atts$name == "grid_mapping"), ]  # drop: warped to lat-long
        crs <- .wkt2_crs_geo(4326L)
      }

      # Assemble the CFData instance
      axes <- c(out_axes_dim, out_axes_other)
      names(axes) <- sapply(axes, function(a) a$name)
      CFData$new(self$name, out_group, d, axes, crs, atts)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Variable"
    },

    #' @field gridLongLat The grid of longitude and latitude values of every
    #' grid cell when the main variable grid has a different coordinate system.
    gridLongLat = function(value) {
      if (missing(value))
        private$llgrid
      else {
        private$llgrid <- value
        dimids <- value$dimids
        ax1 <- sapply(self$axes, function(x) if (x$dimid == dimids[[1L]]) x$orientation)
        ax1 <- ax1[lengths(ax1) > 0L]
        ax2 <- sapply(self$axes, function(x) if (x$dimid == dimids[[2L]]) x$orientation)
        ax2 <- ax2[lengths(ax2) > 0L]
        c(ax1[[1L]], ax2[[1L]])
      }
    },

    #' @field crs (read-only) Retrieve the coordinate reference system
    #' description of the variable as a WKT2 string.
    crs = function(value) {
      if (missing(value)) {
        # Get the axis information to inform the CRS
        info <- private$wkt2_axis_info()

        if (is.null(self$grid_mapping)) {
          # If no grid_mapping has been set, return the default GEOGCRS unless
          # the axis coordinates fall out of range in which case an empty string
          # is returned.
          orient <- lapply(self$axes, function(x) x$orientation)
          X <- match("X", orient, nomatch = 0L)
          Y <- match("Y", orient, nomatch = 0L)
          if (X && Y) {
            X <- self$axes[[X]]$range()
            Y <- self$axes[[Y]]$range()
            if (Y[1L] >= -90 && Y[2L] <= 90 && ((X[1L] >= 0 && X[2L] <= 360) || (X[1L] >= -180 && X[2L] <= 180)))
              .wkt2_crs_geo(4326)
            else ""
          } else ""
        } else
          self$grid_mapping$crs(info)
      }
    }
  )
)

# Public S3 methods ------------------------------------------------------------

#' @export
dim.CFVariable <- function(x) {
  sapply(x$axes, function(z) z$NCdim$length)
}

#' @export
dimnames.CFVariable <- function(x) {
  ax <- x$axes
  if (length(ax)) names(ax)
  else NULL
}

#' Extract data for a variable
#'
#' Extract data from a `CFVariable` instance, optionally sub-setting the
#' axes to load only data of interest.
#'
#' If all the data of the variable in `x` is to be extracted, simply use `[]`
#' (unlike with regular arrays, this is required, otherwise the details of the
#' variable are printed on the console).
#'
#' The indices into the axes to be subset can be specified in a variety of
#' ways; in practice it should (resolve to) be a vector of integers. A range
#' (e.g. `100:200`), an explicit vector (`c(23, 46, 3, 45, 17`), a sequence
#' (`seq(from = 78, to = 100, by = 2`), all work. Note, however, that only a
#' single range is generated from the vector so these examples resolve to
#' `100:200`, `3:46`, and `78:100`, respectively. It is also possible to use a
#' custom function as an argument.
#'
#' This method works with "bare" indices into the axes of the array. If
#' you want to use domain values of the axes (e.g. longitude values or
#' timestamps) to extract part of the variable array, use the `CFVariable$subset()`
#' method.
#'
#' Scalar axes should not be included in the indexing as they do not represent a
#' dimension into the data array.
#'
#' @param x An `CFVariable` instance to extract the data of.
#' @param i,j,... Expressions, one for each axis of `x`, that select a
#'   number of elements along each axis. If any expressions are missing,
#'   the entire axis is extracted. The values for the arguments may be an
#'   integer vector or a function that returns an integer vector. The range of
#'   the values in the vector will be used. See examples, below.
#' @param drop Logical, ignored. Axes are never dropped. Any degenerate
#'   dimensions of the array are returned as such, with dimnames and appropriate
#'   attributes set.
#'
#' @return An array with dimnames and other attributes set.
#' @export
#' @aliases [,CFVariable-method
#' @docType methods
#' @examples
#' fn <- system.file("extdata",
#'   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc",
#'   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' pr <- ds[["pr"]]
#'
#' # How are the dimensions organized?
#' dimnames(pr)
#'
#' # Precipitation data for March for a single location
#' x <- pr[5, 12, 61:91]
#' str(x)
#'
#' # Summer precipitation over the full spatial extent
#' summer <- pr[, , 173:263]
#' str(summer)
"[.CFVariable" <- function(x, i, j, ..., drop = FALSE) {
  numaxes <- sum(!sapply(x$axes, inherits, "CFAxisScalar"))
  t <- vector("list", numaxes)
  names(t) <- dimnames(x)[1:numaxes]

  sc <- sys.call()
  if (numaxes == 0L && length(sc) == 3L) { # Variable is a scalar value
    start <- 1L
    count <- NA_integer_
  } else {
    sc <- sc[-(1L:2L)] # drop [ and x
    if ((length(sc) == 1L) && (identical(sc[[1L]], quote(expr = )))) {
      # [] specified, read whole array
      start <- rep(1L, numaxes)
      count <- rep(NA_integer_, numaxes)
      dnames <- lapply(x$axes, dimnames)
      t <- lapply(x$axes, function(z) z$time())
    } else if (length(sc) != numaxes) {
      stop("Indices specified are not equal to the number of axes of the variable")
    } else {
      start <- vector("integer", numaxes)
      count <- vector("integer", numaxes)
      dnames <- vector("list", numaxes)
      for (d in seq_along(sc)) {
        ax <- x$axes[[d]]
        if (identical(sc[[d]], quote(expr = ))) {
          # Axis not subsetted, read the whole thing
          start[d] <- 1L
          count[d] <- NA_integer_
          dnames[[d]] <- dimnames(ax)
          tm <- ax$time()                 # Direct assignment of NULL in last
          if (!is.null(tm)) t[[d]] <- tm  # dimension drops t[[last]]
        } else {
          # Subset the axis
          v <- eval(sc[[d]])
          ex <- range(v)
          start[d] <- ex[1L]
          count[d] <- ex[2L] - ex[1L] + 1L
          dnames[[d]] <- dimnames(ax)[seq(ex[1], ex[2])]
          if (!is.null(ax$time())) {
            idx <- indexOf(ex[1L]:ex[2L], ax$time(), "constant")
            t[[d]] <- attr(idx, "CFtime")
          }
        }
      }
    }
  }
  data <- RNetCDF::var.get.nc(x$NCvar$group$handle, x$name, start, count, collapse = FALSE, unpack = TRUE, fitnum = TRUE)

  # Apply dimension data and other attributes
  time <- t[lengths(t) > 0L]
  if (length(x$axes) && length(dim(data)) == length(dnames)) { # dimensions may have been dropped automatically, e.g. NC_CHAR to character string
    dimnames(data) <- dnames
    attr(data, "axis") <- sapply(x$axes, function(x) x$orientation)
    if (length(time))
      attr(data, "time") <- time
  }
  data
}
