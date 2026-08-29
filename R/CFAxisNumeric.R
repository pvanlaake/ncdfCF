#' Numeric CF axis object
#'
#' @description This class represents a numeric axis. Its values are numeric.
#' This class is used for axes with numeric values but without further
#' knowledge of their nature. More specific classes descend from this class.
#'
#' @docType class
#' @export
CFAxisNumeric <- R6::R6Class("CFAxisNumeric",
  inherit = CFAxis,
  cloneable = FALSE,
  private = list(
    # Coordinate values of the axis. This may be a label set. Double values are
    # rounded to the standard number of digits.
    get_coordinates = function() {
      crds <- super$get_coordinates()
      if (any(is.double(crds))) round(crds, CF.options$digits)
      else crds
    },

    dimvalues_short = function() {
      crds <- private$get_coordinates()
      nv <- length(crds)
      if (nv == 1L)
        paste0("[", crds[1L], "]")
      else
        paste0("[", crds[1L], " ... ", crds[nv], "]")
    },

    # This function allows descendant classes to print more detail. This stub
    # does nothing but satisfy the call to it from print()
    print_details = function(...) {
    }
  ),
  public = list(
    #' @description Create a new instance of this class.
    #'
    #'   Creating a new axis is more easily done with the [makeAxis()] function.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the axis in a vector. The values
    #'   have to be numeric with the maximum value no larger than the minimum
    #'   value + 360, and monotonic. Ignored when argument `var` is a
    #'   `NCVariable` object.
    #' @param start Optional. Integer index where to start reading axis data
    #'   from file. The index may be `NA` to start reading data from the start.
    #' @param count Optional. Number of elements to read from file. This may be
    #'   `NA` to read to the end of the data.
    #' @param orientation Optional. The orientation of the axis: "X", "Y", "Z"
    #'   "T", or "" (default) when not known or relevant.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   axis. When an empty `data.frame` (default) and argument `var` is an
    #'   `NCVariable` instance, attributes of the axis will be taken from the
    #'   netCDF resource.
    initialize = function(var, group, values, start = 1L, count = NA, orientation = "", attributes = data.frame()) {
      # Check monotonicity if not an auxiliary coordinate variable
      is_cv <- if (inherits(var, "NCVariable")) {
        dim <- var$group$find_dim_by_id(var$dimids)
        !is.null(dim) && var$name == dim$name
      } else TRUE
      if (is_cv && !missing(values) && is.numeric(values)) {
        if (!.monotonicity(values))
          stop("Numeric axis must have numeric monotonic coordinates", call. = FALSE) # nocov
        private$.regular <- .is_regular(values)
      }

      super$initialize(var, group, values = values, start = start, count = count, orientation = orientation, attributes = attributes)
    },

    #' @description Summary of the axis printed to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    #' @return `self`, invisibly.
    print = function(...) {
      super$print()
      if (private$.active_coords == 1L) {
        crds <- private$get_coordinates()
        units <- self$attribute("units")
      } else {
        crds <- private$.aux[[private$.active_coords - 1L]]$coordinates
        units <- private$.aux[[private$.active_coords - 1L]]$attribute("units")
      }
      if (is.na(units)) units <- ""
      if (units == "1") units <- ""

      len <- length(crds)
      if (len < 8L)
        cat("Coordinates: ", paste(crds, collapse = ", "), sep = "")
      else
        cat("Coordinates: ", crds[1L], ", ", crds[2L], ", ", crds[3L], " ... ", crds[len - 2L], ", ", crds[len - 1L], ", ", crds[len], sep = "")
      if (units == "") cat("\n") else cat(" (", units, ")\n", sep = "")

      if (!is.null(private$.bounds))
        private$.bounds$print_boundary_values()
      else cat("Bounds     : (not set)\n")

      private$print_details(...)

      self$print_attributes(...)
      invisible(self)
    },

    #' @description Some details of the axis.
    #'
    #' @return A 1-row `data.frame` with some details of the axis.
    brief = function() {
      out <- super$brief()
      out$values <- private$dimvalues_short()
      out
    },

    #' @description Retrieve the range of coordinate values in the axis.
    #' @return A numeric vector with two elements with the minimum and maximum
    #' values in the axis, respectively.
    range = function() {
      range(self$values)
    },

    #' @description Retrieve the indices of supplied coordinates on the axis. If
    #'   the axis has boundary values then the supplied coordinates must fall
    #'   within the boundaries of an axis coordinate to be considered valid.
    #' @param x A numeric vector of coordinates whose indices into the axis to
    #'   extract.
    #' @param method Extract index values without ("constant", the default) or
    #'   with ("linear") fractional parts.
    #' @param rightmost.closed Whether or not to include the upper limit. This
    #'   parameter is ignored for this class, it always is `TRUE`.
    #' @return A vector giving the indices in `x` of valid coordinates provided.
    #'   Values of `x` outside of the range of the coordinates in the axis are
    #'   returned as `NA`. If the axis has boundary values, then values of `x`
    #'   that do not fall on or between the boundaries of an axis coordinate are
    #'   returned as `NA`.
    indexOf = function(x, method = "constant", rightmost.closed = TRUE) {
      vals <- self$values
      if (is.null(vals)) return(rep(NA, length(x)))
      len <- length(vals)
      bnds <- self$bounds$values

      # Single coordinate value
      if (len == 1L) {
        valid <- if (is.null(bnds)) .near(x, vals)
                 else x >= bnds[1L, 1L] & x <= bnds[2L, 1L]
        valid[!valid] <- NA
        return(as.integer(valid))
      }

      # Multiple coordinate values
      if (is.null(bnds)) {
        # No bounds so get the closest value
        idx <- stats::approx(vals, 1L:length(vals), x, method = method)$y
      } else {
        # Axis has bounds so check that x is clamped in between bounds
        idx <- stats::approx(bnds[1L,], 1L:len, x, method = method, rule = 1:2)$y
        # Invalidate `x`s that exceed the upper boundary at that index
        idx[x > bnds[2L, idx]] <- NA
      }

      if (method == "constant")
        as.integer(idx)
      else
        idx
    },

    #' @description Given a range of domain coordinate values, returns the
    #'   indices into the axis that fall within the supplied range. If the axis
    #'   has bounds, any coordinate whose boundary values fall entirely or
    #'   partially within the supplied range will be included in the result.
    #' @param rng A numeric vector whose extreme values indicate the indices of
    #'   coordinates to return.
    #' @return An integer vector of length 2 with the lower and higher indices
    #'   into the axis that fall within the range of coordinates in argument
    #'   `rng`. Returns `NULL` if no (boundary) values of the axis fall within
    #'   the range of coordinates.
    slice = function(rng) {
      if (private$.active_coords > 1L)
        private$.aux[[private$.active_coords - 1L]]$slice(rng)
      else {
        vals <- self$values
        if (is.null(vals)) return(NULL)
        bnds <- self$bounds$values
        rng <- range(rng)

        if (is.null(bnds)) {
          idx <- which(vals >= rng[1L] & vals <= rng[2L])
        } else {
          lo <- pmin(bnds[1L, ], bnds[2L, ])
          hi <- pmax(bnds[1L, ], bnds[2L, ])
          idx <- which(hi >= rng[1L] & lo <= rng[2L])
        }

        if (!length(idx)) NULL else as.integer(range(idx))
      }
    },

    #' @description Create a copy of this axis. The copy is completely separate
    #' from `self`, meaning that both `self` and all of its components are made
    #' from new instances.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return The newly created axis.
    copy = function(name = "", group) {
      if (self$has_resource) {
        ax <- CFAxisNumeric$new(self$NC, group = group, start = private$.NC_map$start,
                                count = private$.NC_map$count,
                                orientation = private$.orient, attributes = self$attributes)
        if (nzchar(name))
          ax$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        ax <- CFAxisNumeric$new(name, group = group, values = self$values, orientation = private$.orient, attributes = self$attributes)
      }
      private$copy_properties_into(ax)
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
    #' @param values The values to the used with the copy of this axis.
    #' @return The newly created axis.
    copy_with_values = function(name = "", group, values) {
      if (!nzchar(name))
        name <- self$name
      CFAxisNumeric$new(name, group = group, values = values, orientation = private$.orient, attributes = self$attributes)
    },

    #' @description Tests if the axis passed to this method is identical to
    #'   `self`.
    #' @param axis The `CFAxisNumeric` or sub-class instance to test.
    #' @return `TRUE` if the two axes are identical, `FALSE` if not.
    identical = function(axis) {
      super$identical(axis) &&
      all(.near(self$values, axis$values))
    },

    #' @description Append a vector of values at the end of the current values
    #'   of the axis. Boundary values are appended as well but if either this
    #'   axis or the `from` axis does not have boundary values, neither will the
    #'   resulting axis.
    #' @param from An instance of `CFAxisNumeric` whose values to append to the
    #'   values of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return A new `CFAxisNumeric` instance with values from this axis and the
    #'   `from` axis appended.
    append = function(from, group) {
      if (super$can_append(from) && .c_is_monotonic(self$values, from$values)) {
        ax <- CFAxisNumeric$new(self$name, group = group, values = c(private$values, from$values),
                                orientation = self$orientation, attributes = self$attributes)

        if (!is.null(private$.bounds)) {
          new_bnds <- private$.bounds$append(from$bounds, group)
          if (!is.null(new_bnds))
            ax$bounds <- new_bnds
        }

        ax
      } else
        stop("Axis values cannot be appended", call. = FALSE)
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
    #' @return A new `CFAxisNumeric` instance covering the indicated range of
    #'   indices. If the value of the argument `rng` is `NULL`, return a copy of
    #'   this axis as the new axis.
    subset = function(name = "", group, rng = NULL) {
      if (is.null(rng))
        self$copy(name, group)
      else {
        rng <- range(rng)
        if (self$has_resource) {
          nc <- private$to_nc_indices(rng[1L], rng[2L] - rng[1L] + 1L)
          ax <- CFAxisNumeric$new(private$.NCobj, group = group, start = nc$start,
                                  count = nc$count, orientation = private$.orient,
                                  attributes = self$attributes)
          if (nzchar(name))
            ax$name <- name
        } else {
          if (!nzchar(name))
            name <- self$name
          ax <- CFAxisNumeric$new(name, group = group, values = self$values[rng[1L]:rng[2L]],
                                  orientation = private$.orient, attributes = self$attributes)
        }
        private$copy_properties_into(ax, rng)
      }
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Numeric axis"
    },

    #' @field dimnames (read-only) The coordinates of the axis as a vector.
    #'   These are by default the values of the axis, but it could also be a set
    #'   of auxiliary coordinates, if they have been set.
    dimnames = function(value) {
      if (missing(value)) {
        self$coordinates
      }
    }
  )
)
