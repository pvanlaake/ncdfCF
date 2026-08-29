#' CF character axis object
#'
#' @description This class represent CF axes that use categorical character
#' labels as coordinate values. Note that this is different from a [CFLabel],
#' which is associated with an axis but not an axis itself.
#'
#' This is an extension to the CF Metadata Conventions. As per CF, axes are
#' required to have numerical values, which is relaxed here.
#'
#' @docType class
#' @export
CFAxisCharacter <- R6::R6Class("CFAxisCharacter",
  inherit = CFAxis,
  cloneable = FALSE,
  private = list(
    dimvalues_short = function() {
      crds <- self$values
      nv <- length(crds)
      if (nv == 1L)
        paste0('["', crds[1L], '"]')
      else
        paste0('["', crds[1L], '" ... "', crds[nv], '"]')
    }
  ),
  public = list(
    #' @description Create a new instance of this class.
    #'
    #'   Creating a new character axis is more easily done with the
    #'   [makeCharacterAxis()] function.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the axis in a vector. These must be
    #'   character values. Ignored when argument `var` is a NCVariable object.
    #' @param start Optional. Integer index where to start reading axis data
    #'   from file. The index may be `NA` to start reading data from the start.
    #' @param count Optional. Number of elements to read from file. This may be
    #'   `NA` to read to the end of the data.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   axis. When an empty `data.frame` (default) and argument `var` is an
    #'   NCVariable instance, attributes of the axis will be taken from the
    #'   netCDF resource.
    initialize = function(var, group, values, start = 1L, count = NA, attributes = data.frame()) {
      if (!missing(values) && !is.character(values))
        stop("Must pass character coordinates to a character axis.", call. = FALSE) # nocov

      super$initialize(var, group, values = values, start = start, count = count, attributes = attributes)
    },

    #' @description Some details of the axis.
    #'
    #' @return A 1-row `data.frame` with some details of the axis.
    brief = function() {
      out <- super$brief()
      out$values <- private$dimvalues_short()
      out
    },

    #' @description Create a copy of this axis. The copy is completely separate
    #'   from this axis, meaning that the new axis and all of its components are
    #'   made from new instances. If this axis is backed by a netCDF resource,
    #'   the copy will retain the reference to the resource.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return The newly created axis.
    copy = function(name = "", group) {
      if (self$has_resource) {
        ax <- CFAxisCharacter$new(self$NC, group = group, start = private$.NC_map$start,
                                  count = private$.NC_map$count, attributes = self$attributes)
        if (nzchar(name))
          ax$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        ax <- CFAxisCharacter$new(name, group = group, values = self$values, attributes = self$attributes)
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
      CFAxisCharacter$new(name, group = group, values = values, attributes = self$attributes)
    },

    #' @description Given a range of domain coordinate values, returns the
    #'   indices into the axis that fall within the supplied range.
    #' @param rng A character vector whose extreme (alphabetic) values indicate
    #'   the indices of coordinates to return.
    #' @return An integer vector of length 2 with the lower and higher indices
    #'   into the axis that fall within the range of coordinates in argument
    #'   `rng`. Returns `NULL` if no values of the axis fall within the range of
    #'   coordinates.
    slice = function(rng) {
      res <- range(match(rng, self$coordinates, nomatch = 0L), na.rm = TRUE)
      if (all(res == 0L)) NULL
      else if (res[1L] == 0L) c(res[2L], res[2L])
      else if (res[2L] == 0L) c(res[1L], res[1L])
      else res
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
    #' @return A new `CFAxisCharacter` instance covering the indicated range of
    #'   indices. If the value of the argument `rng` is `NULL`, return a copy of
    #'   this axis as the new axis.
    subset = function(name = "", group, rng = NULL) {
      if (is.null(rng))
        self$copy(name, group)
      else {
        rng <- range(rng)
        if (self$has_resource) {
          nc <- private$to_nc_indices(rng[1L], rng[2L] - rng[1L] + 1L)
          ax <- CFAxisCharacter$new(private$.NCobj, group = group, start = nc$start,
                                    count = nc$count, attributes = self$attributes)
          if (nzchar(name))
            ax$name <- name
        } else {
          if (!nzchar(name))
            name <- self$name
          ax <- CFAxisCharacter$new(name, group = group, values = self$values[rng[1L]:rng[2L]],
                                    attributes = self$attributes)
        }
        private$copy_properties_into(ax, rng)
      }
    },

    #' @description Tests if the axis passed to this method is identical to
    #'   `self`.
    #' @param axis The `CFAxisCharacter` instance to test.
    #' @return `TRUE` if the two axes are identical, `FALSE` if not.
    identical = function(axis) {
      super$identical(axis) &&
      all(self$values == axis$values)
    },

    #' @description Append a vector of values at the end of the current values
    #'   of the axis.
    #' @param from An instance of `CFAxisCharacter` whose values to append to
    #'   the values of `self`.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return A new `CFAxisCharacter` instance with values from `self` and the
    #'   `from` axis appended.
    append = function(from, group) {
      if (super$can_append(from) && !any(from$values %in% self$values)) {
        CFAxisCharacter$new(self$name, group = group, values = c(self$values, from$values), attributes = self$attributes)
      } else
        stop("Axis values are not unique after appending.", call. = FALSE)
    },

    #' @description Find indices in the axis domain. Given a vector of character
    #'   strings `x`, find their indices in the coordinates of the axis.
    #'
    #' @param x Vector of character strings to find axis indices for.
    #' @param method Ignored.
    #' @param rightmost.closed Ignored.
    #'
    #' @return Numeric vector of the same length as `x`. Values of `x` that are
    #'   not equal to a coordinate of the axis are returned as `NA`.
    indexOf = function(x, method = "constant", rightmost.closed = TRUE) {
      match(x, self$values)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value)) "Character axis"
    },

    #' @field dimnames (read-only) The coordinates of the axis as a character
    #' vector.
    dimnames = function(value) {
    if (missing(value))
      self$values
    }
  )
)
