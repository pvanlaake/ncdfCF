#' Latitude CF axis object
#'
#' @description This class represents a latitude axis. Its values are numeric.
#' This class adds some logic that is specific to latitudes, such as their
#' range, orientation and meaning.
#'
#' @docType class
#' @export
CFAxisLatitude <- R6::R6Class("CFAxisLatitude",
  inherit = CFAxisNumeric,
  cloneable = FALSE,
  public = list(

    #' @description Create a new instance of this class.
    #'
    #'   Creating a new latitude axis is more easily done with the
    #'   [makeLatitudeAxis()] function.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the axis in a vector. The values
    #'   have to be numeric within the range (-90, 90) and monotonic. Ignored
    #'   when argument `var` is a NCVariable object.
    #' @param start Optional. Integer index where to start reading axis data
    #'   from file. The index may be `NA` to start reading data from the start.
    #' @param count Optional. Number of elements to read from file. This may be
    #'   `NA` to read to the end of the data.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   axis. When an empty `data.frame` (default) and argument `var` is an
    #'   NCVariable instance, attributes of the axis will be taken from the
    #'   netCDF resource.
    initialize = function(var, group, values, start = 1L, count = NA, attributes = data.frame()) {
      super$initialize(var, group, values = values, start = start, count = count, orientation =  "Y", attributes = attributes)
      self$set_attribute("standard_name", "NC_CHAR", "latitude")
      self$set_attribute("units", "NC_CHAR", "degrees_north")

      if (!missing(values) && !.check_latitude_domain(values))
        stop("Latitude coordinate values are not in the domain [-90, 90].", call. = FALSE) # nocov
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
        ax <- CFAxisLatitude$new(self$NC, group = group, values = self$values, start = private$.NC_map$start,
                                 count = private$.NC_map$count, attributes = self$attributes)
        if (nzchar(name))
          ax$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        ax <- CFAxisLatitude$new(name, group = group, values = self$values, attributes = self$attributes)
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
      CFAxisLatitude$new(name, group = group, values = values, attributes = self$attributes)
    },

    #' @description Return a latitude axis spanning a smaller coordinate range.
    #'   This method returns an axis which spans the range of indices given by
    #'   the `rng` argument.
    #' @param name The name for the new axis. If an empty string is passed
    #'   (default), will use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param rng The range of indices whose values from this axis to include in
    #'   the returned axis. If the value of the argument is `NULL`, return a
    #'   copy of the axis.
    #' @return A new `CFAxisLatitude` instance covering the indicated range of
    #'   indices. If the value of the argument `rng` is `NULL`, return a copy of
    #'   `self` as the new axis.
    subset = function(name = "", group, rng = NULL) {
      if (is.null(rng))
        self$copy(name, group)
      else {
        rng <- range(rng)
        if (self$has_resource) {
          nc <- private$to_nc_indices(rng[1L], rng[2L] - rng[1L] + 1L)
          ax <- CFAxisLatitude$new(private$.NCobj, group = group, start = nc$start,
                                   count = nc$count, attributes = self$attributes)
          if (nzchar(name))
            ax$name <- name
        } else {
          if (!nzchar(name))
            name <- self$name
          ax <- CFAxisLatitude$new(name, group = group, values = self$values[rng[1L]:rng[2L]], attributes = self$attributes)
        }
        private$copy_properties_into(ax, rng)
      }
    },

    #' @description Append a vector of values at the end of the current values
    #'   of the axis. Boundary values are appended as well but if either this
    #'   axis or the `from` axis does not have boundary values, neither will the
    #'   resulting axis.
    #' @param from An instance of `CFAxisLatitude` whose values to append to the
    #'   values of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return A new `CFAxisLatitude` instance with values from this axis and
    #'   the `from` axis appended.
    append = function(from) {
      if (super$can_append(from) && .c_is_monotonic(self$values, from$values)) {
        ax <- CFAxisLatitude$new(self$name, group = group, values = c(private$values, from$values),
                                 attributes = self$attributes)

        if (!is.null(private$.bounds)) {
          new_bnds <- private$.bounds$append(from$bounds, group)
          if (!is.null(new_bnds))
            ax$bounds <- new_bnds
        }

        ax
      } else
        stop("Axis values cannot be appended.", call. = FALSE)
    }
  ),
  active = list(
   #' @field friendlyClassName (read-only) A nice description of the class.
   friendlyClassName = function(value) {
     if (missing(value))
       "Latitude axis"
   }
  )
)

# ============ Helper functions

# This function checks if the supplied coordinates are within the domain of
# latitude values. The values have to be in the range [-90, 90]. Returns TRUE or
# FALSE.
.check_latitude_domain <- function(crds) {
  len <- length(crds)
  if (!len) TRUE
  else crds[len] >= -90 && crds[1L] >= -90 && crds[1L] <= 90 && crds[len] <= 90
}
