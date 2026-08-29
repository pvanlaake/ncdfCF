# #' @importFrom CFtime unit as_timestamp
# NULL

#' Time axis object
#'
#' @description This class represents a time axis. The functionality is provided
#' by the `CFTime` class in the `CFtime` package.
#'
#' @docType class
#' @export
CFAxisTime <- R6::R6Class("CFAxisTime",
  inherit = CFAxis,
  cloneable = FALSE,
  private = list(
    # The `CFTime` or `CFClimatology` instance to manage CF time.
    .tm = NULL,

    get_coordinates = function() {
      if (private$.active_coords == 1L)
        private$.tm$as_timestamp()
      else {
        crds <- private$.aux[[private$.active_coords - 1L]]$coordinates
        dim(crds) <- NULL
        crds
      }
    },

    dimvalues_short = function() {
      crds <- private$get_coordinates()
      nv <- length(crds)
      if (!nv) # it happens...
        "(no values)"
      else if (nv == 1L)
        paste0("[", crds[1L], "]")
      else
        sprintf("[%s ... %s]", crds[1L], crds[nv])
    },

    # Timestamps in argument ts may be a single one, abbreviated, a range, by
    # season/quarter/dekad, etc so rework to two proper timestamps.
    expand_timestamps = function(ts) {
      # Year as numeric: YYYY or YYYY:YYYY
      if (is.numeric(ts)) {
        ts <- range(as.integer(ts))
        return(c(paste0(ts[1L], "-01-01"), paste0(ts[2L] + 1L, "-01-01")))
      }

      if (!is.character(ts))
        stop("Bad format for timestamps.", call. = FALSE)

      if (length(ts) == 1L)
        ts <- c(ts, ts)
      else if (length(ts) != 2L)
        stop("Bad format for timestamps.", call. = FALSE)

      # Year as character string
      if (all(grepl("^[0-9]{4}$", ts)))
        return(c(paste0(ts[1L], "-01-01"), paste0(as.integer(ts[2L]) + 1L, "-01-01")))

      # Year-month as character string
      ym <- utils::strcapture("^([0-9]{4})-(0[1-9]|1[0-2])$", ts, data.frame(year = integer(), month = integer()))
      if (!any(is.na(ym))) {
        if (ym$month[2L] == 12L) {
          ym$year[2L] <- ym$year[2L] + 1L
          ym$month[2L] <- 1L
        } else
          ym$month[2L] <- ym$month[2L] + 1L
        return(sprintf("%04d-%02d-01", ym$year, ym$month))
      }

      # Year-season as character string
      ys <- utils::strcapture("^([0-9]{4})-S([1-4])$", ts, data.frame(year = integer(), season = integer()))
      if (!any(is.na(ys))) {
        if (ys$season[1L] == 1L) {
          ys$year[1L] <- ys$year[1L] - 1L
          ys$season[1L] <- 5L
        }
        ys$season[2L] <- ys$season[2L] + 1L
        return(sprintf("%04d-%02d-01", ys$year, (ys$season - 1L) * 3L))
      }

      # Year-quarter as character string
      yq <- utils::strcapture("^([0-9]{4})-Q([1-4])$", ts, data.frame(year = integer(), quarter = integer()))
      if (!any(is.na(yq))) {
        if (yq$quarter[2L] == 4L) {
          yq$year[2L] <- yq$year[2L] + 1L
          yq$quarter[2L] <- 1L
        } else
          yq$quarter[2L] <- yq$quarter[2L] + 1L
        return(sprintf("%04d-%02d-01", yq$year, (yq$quarter - 1L) * 3L + 1L))
      }

      # Year-dekad as character string
      yk <- utils::strcapture("^([0-9]{4})-D([0-2][1-9]|3[0-6])$", ts, data.frame(year = integer(), dekad = integer()))
      if (!any(is.na(yk))) {
        mod <- yk$dekad %% 3L # which dekad in the month: 1, 2, 0
        if (yk$dekad[2L] == 36L) {
          yk$year[2L] <- yk$year[2L] + 1L
          yk$dekad[2L] <- 1L
        } else if (mod[2L] == 0L) {
          yk$dekad[2L] <- yk$dekad[2L] + 1L
          mod[2L] <- 1L
        } else {
          yk$dekad[2L] <- yk$dekad[2L] + 1L
          mod[2L] <- mod[2L] + 1L
        }
        d <- ifelse(mod == 0L, 21L, (mod - 1L) * 10L + 1L)
        return(sprintf("%04d-%02d-%02d", yk$year, (yk$dekad - 1L) %/% 3L + 1L, d))
      }

      # Year-month-day - only if both dates are identical (so only a single day was specified)
      if (ts[1L] == ts[2L]) {
        ymd <- private$.tm$calendar$parse(ts[1L])
        if (is.na(ymd$year))
          stop("Bad format for timestamps: Date not valid calendar.", call. = FALSE)
        ymd <- rbind(ymd, private$.tm$calendar$add_day(ymd))
        return(sprintf("%04d-%02d-%02d", ymd$year, ymd$month, ymd$day))
      }

      # If all else fails, just return the passed-in argument
      ts
    }
  ),
  public = list(
    #' @description Create a new instance of this class, including its boundary
    #'   values. A `CFTime` or `CFClimatology` instance will also be created to
    #'   manage the time magic.
    #'
    #'   Creating a new time axis is more easily done with the [makeTimeAxis()]
    #'   function.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Either the numeric values of this axis, in which case
    #'   argument `var` must be a `NCVariable`, or an instance of `CFTime` or
    #'   `CFClimatology` with bounds set, and then argument `var` must be a name
    #'   for the axis.
    #' @param start Optional. Integer index where to start reading axis data
    #'   from file. The index may be `NA` to start reading data from the start.
    #' @param count Optional. Number of elements to read from file. This may be
    #'   `NA` to read to the end of the data.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   axis. When an empty `data.frame` (default) and argument `var` is an
    #'   NCVariable instance, attributes of the axis will be taken from the
    #'   netCDF resource.
    initialize = function(var, group, values, start = 1L, count = NA, attributes = data.frame()) {
      if (inherits(values, "CFTime")) {
        private$.tm <- values
        if (!is.null(bv <- values$bounds)) {
          if (length(att <- attributes[attributes$name %in% c("bounds", "climatology"), "value"]))
            nm <- att[[1L]]
          else {
            nm <- paste(var, "bnds", sep = "_")
            attributes <- rbind(attributes, data.frame(name = "bounds", type = "NC_CHAR", length = nchar(nm), value = nm))
          }
          private$.bounds <- CFBounds$new(nm, group, values = bv)
        }
        values <- private$.tm$offsets
      } else if (inherits(var, "NCVariable")) {
        # Make a CFTime or CFClimatology instance
        units <- var$attribute("units")
        if (is.na(units))
          stop("Could not create a CFTime object from the arguments", call. = FALSE)
        cal <- var$attribute("calendar")
        cal <- if (is.na(cal) || cal == "gregorian") "standard" else cal

        bnds <- NULL
        clim <- var$attribute("climatology")
        if (!is.na(clim)) {
          nc <- var$group$find_by_name(clim) # FIXME: Make this a FQN?
          if (is.null(nc)) {
            warning("Unmatched `climatology` value '", clim, "' found in variable '", var$name, "'", call. = FALSE)
            stop("Could not create a CFClimatology object from the arguments", call. = FALSE)
          } else {
            bnds <- CFBounds$new(nc, group, start = c(1L, start), count = c(2L, count))
            t <- try(CFtime::CFClimatology$new(units, cal, values, bnds$values), silent = TRUE)
            if (inherits(t, "try-error"))
              stop("Could not create a CFClimatology object from the arguments", call. = FALSE)
          }
        } else {
          t <- try(CFtime::CFTime$new(units, cal, values), silent = TRUE)
          if (inherits(t, "try-error"))
            stop("Could not create a CFTime object from the arguments", call. = FALSE)
          bounds <- var$attribute("bounds")
          if (!is.na(bounds)) {
            nc <- var$group$find_by_name(bounds) # FIXME: Make this a FQN?
            if (is.null(nc))
              warning("Unmatched `bounds` value '", bounds, "' found in variable '", var$name, "'", call. = FALSE)
            else {
              bnds <- CFBounds$new(nc, group, start = c(1L, start), count = c(2L, count))
              t$bounds <- bnds$values
            }
          }
        }
        private$.tm <- t
        private$.bounds <- bnds
      } else
        stop("When initializing by time axis name, must provide a `CFTime` instance as argument 'values'", call. = FALSE) # nocov

      super$initialize(var, group, values = values, start = start, count = count, orientation = "T", attributes = attributes)
      self$set_attribute("standard_name", "NC_CHAR", "time")
      if (!inherits(var, "NCVariable"))
        self$set_attribute("units", "NC_CHAR", private$.tm$calendar$definition)
      self$set_attribute("calendar", "NC_CHAR", private$.tm$calendar$name)

      private$.regular <- .is_regular(values)
    },

    #' @description Summary of the time axis printed to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    print = function(...) {
      super$print()

      time <- private$.tm
      if (private$.active_coords == 1L) {
        crds <- time$as_timestamp()
        units <- time$unit
      } else {
        crds <- private$.aux[[private$.active_coords - 1L]]$coordinates
        units <- private$.aux[[private$.active_coords - 1L]]$attribute("units")
      }
      len <- length(crds)
      rng <- if (len == 1L) crds[1L]
             else paste(crds[1L], "...", crds[len])
      if (!is.na(units)) rng <- paste0(rng, " (", units, ")")
      bndrng <- if (!is.null(time$get_bounds()))
        paste0(time$range(format = "", bounds = TRUE), collapse = " ... ")
      else "(not set)"
      cat("Calendar   :", time$calendar$name, "\n")
      cat("Range      :", rng, "\n")
      cat("Bounds     :", bndrng, "\n")

      self$print_attributes(...)
    },

    #' @description Some details of the axis.
    #'
    #' @return A 1-row `data.frame` with some details of the axis.
    brief = function() {
      out <- super$brief()
      out$values <- private$dimvalues_short()
      out
    },

    #' @description Tests if the axis passed to this method is identical to
    #'   `self`.
    #' @param axis The `CFAxisTime` instance to test.
    #' @return `TRUE` if the two axes are identical, `FALSE` if not.
    identical = function(axis) {
      super$identical(axis) &&
      private$.tm$cal$is_equivalent(axis$time$calendar) &&
      all(.near(private$.tm$offsets, axis$time$offsets))
    },

    #' @description Create a copy of this axis. The copy is completely separate
    #' from `self`, meaning that both `self` and all of its components are made
    #' from new instances.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return The newly created axis.
    copy = function(name = "", group) {
      time <- private$.tm$copy()
      if (self$has_resource) {
        ax <- CFAxisTime$new(self$NC, group = group, values = self$values, start = private$.NC_map$start,
                             count = private$.NC_map$count, attributes = self$attributes)
        if (nzchar(name))
          ax$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        ax <- CFAxisTime$new(name, group = group, values = time, attributes = self$attributes)
      }
      private$copy_properties_into(ax)
      ax
    },

    #' @description Create a copy of this axis but using the supplied values.
    #'   The attributes are copied to the new axis. Boundary values and
    #'   auxiliary coordinates are not copied.
    #'
    #'   After this operation the attributes of the newly created axes may not
    #'   be accurate, except for the "actual_range" attribute. The calling code
    #'   should set, modify or delete attributes as appropriate.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param values The values to the used with the copy of this axis. This can
    #'   be a `CFTime` instance, a vector of numeric values, a vector of
    #'   character timestamps in ISO8601 or UDUNITS format, or a vector of
    #'   `POSIXct` or `Date` values. If not a `CFTime` instance, the `values`
    #'   will be converted into a `CFTime` instance using the definition and
    #'   calendar of this axis.
    #' @return The newly created axis.
    copy_with_values = function(name = "", group, values) {
      if (!nzchar(name))
        name <- self$name

      if (!inherits(values, "CFTime")) {
        values <- try(CFtime::CFTime$new(self$attribute("units"), self$attribute("calendar"), values), silent = TRUE)
        if (inherits(values, "try-error"))
          stop("Invalid values for a 'time' axis.", call. = FALSE) # nocov
      }

      CFAxisTime$new(name, group = group, values = values, attributes = self$attributes)
    },

    #' @description Append a vector of time values at the end of the current
    #'   values of the axis.
    #' @param from An instance of `CFAxisTime` whose values to append to the
    #'   values of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return A new `CFAxisTime` instance with values from this axis and the
    #'   `from` axis appended.
    append = function(from, group) {
      if (!super$can_append(from))
        stop("Axis values cannot be appended.", call. = FALSE)

      new_time <- private$.tm + from$time
      ax <- CFAxisTime$new(self$name, group = group,
                           values = new_time, attributes = self$attributes)

      ax$bounds <- if (is.null(b <- new_time$bounds)) NULL
      else CFBounds$new(paste0(self$name, "_bnds"), group = group, values = b)

      ax
    },

    #' @description Retrieve the indices of supplied values on the time axis.
    #' @param x A vector of timestamps whose indices into the time axis to
    #' extract.
    #' @param method Extract index values without ("constant", the default) or
    #' with ("linear") fractional parts.
    #' @param rightmost.closed Whether or not to include the upper limit.
    #' Default is `FALSE`.
    #' @return A vector giving the indices in the time axis of valid
    #' values in `x`, or `NA` if the value is not valid.
    indexOf = function(x, method = "constant", rightmost.closed = FALSE) {
      idx <- private$.tm$indexOf(x, method, rightmost.closed)

      if (method == "constant")
        as.integer(idx)
      else
        idx
    },

    #' @description Retrieve the indices of the time axis falling between two
    #'   extreme values.
    #' @param x A vector of two timestamps in between of which all indices into
    #'   the time axis to extract.
    #' @param rightmost.closed Whether or not to include the upper limit.
    #'   Default is `FALSE`.
    #' @return An integer vector giving the indices in the time axis between
    #'   values in `x`, or `NULL` if none of the values are valid.
    slice = function(x, rightmost.closed = FALSE) {
      x <- private$expand_timestamps(x)
      time <- private$.tm
      idx <- suppressWarnings(time$slice(x, rightmost.closed))
      if (all(!idx)) NULL
      else range((1L:length(time))[idx])
    },

    #' @description Return an axis spanning a smaller coordinate range. This
    #'   method returns an axis which spans the range of indices given by the
    #'   `rng` argument.
    #' @param name The name for the new axis. If an empty string is passed
    #'   (default), will use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param rng The range of indices whose values from this axis to include in
    #'   the returned axis. If the value of the argument is `NULL`, return a
    #'   copy of the axis.
    #' @return A new `CFAxisTime` instance covering the indicated range of
    #'   indices. If the value of the argument `rng` is `NULL`, return a copy of
    #'   `self` as the new axis.
    subset = function(name = "", group, rng = NULL) {
      if (is.null(rng))
        self$copy(name, group)
      else {
        rng <- as.integer(range(rng))
        if (self$has_resource) {
          nc <- private$to_nc_indices(rng[1L], rng[2L] - rng[1L] + 1L)
          ax <- CFAxisTime$new(private$.NCobj, group = group, values = self$values[rng[1L]:rng[2L]],
                               start = nc$start, count = nc$count, attributes = self$attributes)
          if (nzchar(name))
            ax$name <- name
        } else {
          if (!nzchar(name))
            name <- self$name
          idx <- private$.tm$indexOf(seq(from = rng[1L], to = rng[2L], by = 1L))
          newtm <- attr(idx, "CFTime")
          ax <- CFAxisTime$new(name, group = group, values = newtm, attributes = self$attributes)
        }
        private$copy_properties_into(ax, rng)
      }
    },

    #' @description Create the GeoZarr coordinates for this time axis. If the
    #'   coordinate values are not regular and longer than a set minimum, write
    #'   the coordinates to the group as a new Zarr array if it does not yet
    #'   exist. This will also include boundary values.
    #' @param grp An instance of `zarr_group` where the coordinates will be
    #'   located in the Zarr store. The coordinates will be written to a new
    #'   Zarr array with the name based on the axis name if it is irregular and
    #'   long.
    #' @return An instance of [geozarr::CoordinatesTime].
    geozarr_coordinates = function(grp) {
      len <- self$length
      vals <- self$time$offsets
      dir <- if (len == 1L) "OTHER" else "FUTURE"

      unit <- private$.tm$unit
      cal <- private$.tm$calendar
      calendar <- cal$name
      epoch <- cal$origin_date
      epoch_time <- cal$origin_time
      if (epoch_time != "00:00:00")
        epoch <- paste(epoch, epoch_time, sep = "T")

      # Attributes that are structural are by the convention being used
      # so filter them out before writing. Add the reworked attributes.
      atts <- private$zarr_attributes(c("axis", "bounds", "climatology_bounds"))
      atts$units <- unit
      atts$epoch <- epoch

      # Boundary values
      bnds <- private$.bounds$values
      if (!is.null(bnds)) {
        if (.is_regular(vals - bnds[1L,]) && .is_regular(bnds[2L,] - vals))
          # Regular, get up and down interval
          bnds <- c(bnds[1L,1L] - vals[1L], bnds[2L,1L] - vals[1L])
        else
          # Irregular, write array to the Zarr group
          private$.bounds$write_geozarr(grp)
      }

      # Irregular
      if (!private$.regular && self$length > geozarr::geozarr_options()$max_explicit) {
        # Create a Zarr array for the axis coordinates if it does not already exist
        if (is.null(grp$children[[self$name]])) {
          ab <- zarr::array_builder$new()
          ab$shape <- len
          ab$data_type <- switch(storage.mode(vals),
                                 "double" = "float64",
                                 "integer" = "int32")
          ab$chunk_shape <- len
          if (len > zarr::zarr_options()$min_compress)
            ab$add_codec("blosc", list(clevel = 6L))
          meta <- ab$metadata()
          meta$attributes <- atts
          new_array <- try(grp$add_array(self$name, meta), silent = TRUE)
          if (inherits(new_array, "try-error"))
            stop("Could not create Zarr array with name", self$name, call. = FALSE)
          new_array$write(vals)
        }
      }

      # Filter some more attributes that we don't want inlined
      atts$units <- NULL
      atts$calendar <- NULL
      atts$epoch <- NULL

      geozarr::CoordinatesTime$new(self$name, dir, unit, epoch, calendar, vals, bnds, atts)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Time axis"
    },

    #' @field time (read-only) Retrieve the `CFTime` instance that manages the
    #'   values of this axis.
    time = function(value) {
      if (missing(value))
        private$.tm
    },

    #' @field dimnames (read-only) The coordinates of the axis as a character
    #'   vector.
    dimnames = function(value) {
      if (missing(value))
        format(private$.tm)
    }
  )
)
