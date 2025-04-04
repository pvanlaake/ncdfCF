#' CF axis object
#'
#' @description This class is a basic ancestor to all classes that represent CF
#'   axes. More useful classes use this class as ancestor.
#'
#' @docType class
CFAxis <- R6::R6Class("CFAxis",
  inherit = CFObject,
  private = list(
    # A list of [CFLabel] instances, if any are defined for the axis.
    lbls = list(),

    # The active label set. Either an integer or a name. `NULL` if there are no
    # labels or when underlying axis coordinates should be used.
    active_label = NULL,

    # Get the coordinates of the axis. In most cases that is just the values
    # but CFAxisTime and CFAxisDiscrete override this method.
    get_coordinates = function() {
      private$get_values()
    },

    # Copy a subset of all the label sets to another axis. Argument ax will
    # receive the label sets subsetted by argument rng.
    copy_label_subset_to = function(ax, rng) {
      if (!length(private$lbls)) return(NULL)
      act <- private$active_label
      private$active_label <- NULL
      lapply(private$lbls, function(l) ax$create_label_set(l$name, l$subset(rng)))
      private$active_label <- act
    }
  ),
  public = list(
    #' @field NCdim The [NCDimension] that stores the netCDF dimension details.
    #' This is `NULL` for [CFAxisScalar] instances.
    NCdim = NULL,

    #' @field orientation A character "X", "Y", "Z" or "T" to indicate the
    #' orientation of the axis, or an empty string if not known or different.
    orientation = "",

    #' @field bounds The boundary values of this axis, if set.
    bounds = NULL,

    #' @description Create a new CF axis instance from a dimension and a
    #'   variable in a netCDF resource. This method is called upon opening a
    #'   netCDF resource by the `initialize()` method of a descendant class
    #'   suitable for the type of axis.
    #' @param grp The [NCGroup] that this axis is located in.
    #' @param nc_var The [NCVariable] instance upon which this CF axis is based.
    #' @param nc_dim The [NCDimension] instance upon which this CF axis is
    #'   based.
    #' @param orientation The orientation of the axis: "X", "Y", "Z" "T", or ""
    #'   when not known or relevant.
    #' @return A basic `CFAxis` object.
    initialize = function(grp, nc_var, nc_dim, orientation) {
      super$initialize(nc_var, grp)
      self$NCdim <- nc_dim
      self$orientation <- orientation
      self$delete_attribute("_FillValue")

      nc_var$CF <- self
    },

    #' @description  Prints a summary of the axis to the console. This method is
    #'   typically called by the `print()` method of descendant classes.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    #' @return `self`, invisibly.
    print = function(...) {
      cat("<", self$friendlyClassName, "> [", self$dimid, "] ", self$name, "\n", sep = "")
      if (self$group$name != "/")
        cat("Group    :", self$group$fullname, "\n")

      longname <- self$attribute("long_name")
      if (!is.na(longname) && longname != self$name)
        cat("Long name:", longname, "\n")

      cat("Length   :", self$NCdim$length)
      if (self$NCdim$unlim) cat(" (unlimited)\n") else cat("\n")
      cat("Axis     :", self$orientation, "\n")
      if (self$has_labels)
      cat("Labels   :", paste(self$label_set_names, collapse = ", "), "\n")
    },

    #' @description Some details of the axis.
    #' @return A 1-row `data.frame` with some details of the axis.
    brief = function() {
      longname <- self$attribute("long_name")
      if (is.na(longname) || longname == self$name) longname <- ""
      unlim <- if (self$NCdim$unlim) "U" else ""
      units <- self$attribute("units")
      if (is.na(units)) units <- ""
      if (units == "1") units <- ""

      data.frame(id = self$dimid, axis = self$orientation, group = self$group$fullname,
                 name = self$name, long_name = longname, length = self$NCdim$length,
                 unlim = unlim, values = "", unit = units)
    },

    #' @description Very concise information on the axis. The information
    #'   returned by this function is very concise and most useful when combined
    #'   with similar information from other axes.
    #' @return Character string with very basic axis information.
    shard = function() {
      self$NCdim$shard()
    },

    #' @description Retrieve interesting details of the axis.
    #' @param with_groups Should group information be included? The save option
    #' is `TRUE` (default) when the netCDF resource has groups because names may
    #' be duplicated among objects in different groups.
    #' @return A 1-row `data.frame` with details of the axis.
    peek = function(with_groups = TRUE) {
      out <- data.frame(class = class(self)[1L], id = self$id, axis = self$orientation)
      if (with_groups) out$group <- self$group$fullname
      out$name <- self$name
      out$long_name <- self$attribute("long_name")
      out$standard_name <- self$attribute("standard_name")
      out$units <- self$attribute("units")
      out$length <- self$NCdim$length
      out$unlimited <- self$NCdim$unlim
      out$values <- private$dimvalues_short()
      out$has_bounds <- inherits(self$bounds, "CFBounds")
      out$label_sets <- self$has_labels
      out
    },

    #' @description Return the `CFTime` instance that represents time. This
    #'   method is only useful for `CFAxisTime` instances and `CFAxisScalar`
    #'   instances having time information. This stub is here to make the call
    #'   to this method succeed with no result for the other axis descendants.
    #' @return `NULL`
    time = function() {
      NULL
    },

    #' @description Return an axis spanning a smaller coordinate range. This
    #'   method is "virtual" in the sense that it does not do anything other
    #'   than return `NULL`. This stub is here to make the call to this method
    #'   succeed with no result for the other axis descendants that do not
    #'   implement this method.
    #' @param group The group to create the new axis in.
    #' @param rng The range of values from this axis to include in the returned
    #'   axis. If the value of the argument is `NULL`, return the entire axis
    #'   (possibly as a scalar axis).
    #' @return `NULL`
    sub_axis = function(group, rng = NULL) {
      NULL
    },

    #' @description Find indices in the axis domain. Given a vector of
    #'   numerical, timestamp or categorical values `x`, find their indices in
    #'   the values of the axis. With `method = "constant"` this returns the
    #'   index of the value lower than the supplied values in `x`. With
    #'   `method = "linear"` the return value includes any fractional part.
    #'
    #'   If bounds are set on the numerical or time axis, the indices are taken
    #'   from those bounds. Returned indices may fall in between bounds if the
    #'   latter are not contiguous, with the exception of the extreme values in
    #'   `x`.
    #' @param x Vector of numeric, timestamp or categorial values to find axis
    #'   indices for. The timestamps can be either character, POSIXct or Date
    #'   vectors. The type of the vector has to correspond to the type of the
    #'   axis.
    #' @param method Single character value of "constant" or "linear".
    #' @return Numeric vector of the same length as `x`. If `method = "constant"`,
    #'   return the index value for each match. If `method = "linear"`, return
    #'   the index value with any fractional value. Values of `x` outside of the
    #'   range of the values in the axis are returned as `0` and
    #'   `.Machine$integer.max`, respectively.
    indexOf = function(x, method = "constant") {
      stop("`indexOf()` must be implemented by descendant CFAxis class.")
    },

    #' @description Retrieve a set of character labels from the active label
    #'   set, corresponding to the elements of an axis.
    #' @param n An integer value indicating which set of labels to retrieve.
    #'   Alternatively, this can be the name of the label set. When `NULL`
    #'   (default), the labels from the active label set are returned.
    #' @return A character vector of string labels with as many elements as the
    #'   axis has, or `NULL` when no labels have been set or when argument
    #'   `n` is not valid.
    label_set = function(n = NULL) {
      if (!length(private$lbls) ||
          (is.numeric(n) && (n < 1L || n > length(private$lbls)))) return(NULL)

      if (is.null(n))
        n <- private$active_label

      if (is.null(n)) NULL
      else private$lbls[[n]]$labels
    },

    #' @description Create a new label set for the axis from the vector of
    #' supplied labels. The [CFLabel] instance will be created in the group of
    #' this axis.
    #' @param name A name for this label set.
    #' @param labels Character vector of labels. The vector must have the same
    #' length as the axis.
    #' @return Self, invisibly.
    create_label_set = function(name, labels) {
      if (length(labels) != self$length)
        stop("Labels vector not the same length as the axis.", call. = FALSE)

      var <- NCVariable$new(-1L, name, self$group, "NC_STRING", 1L, NULL)
      self$labels <- CFLabel$new(self$group, var, self$NCdim, labels)
      invisible(self)
    },

    #' @description Write the axis to a netCDF file, including its attributes.
    #' @param nc The handle of the netCDF file opened for writing or a group in
    #'   the netCDF file. If `NULL`, write to the file or group where the axis
    #'   was read from (the file must have been opened for writing). If not
    #'   `NULL`, the handle to a netCDF file or a group therein.
    #' @return Self, invisibly.
    write = function(nc = NULL) {
      h <- if (inherits(nc, "NetCDF")) nc else self$group$handle

      if (inherits(self, "CFAxisScalar")) {
        RNetCDF::var.def.nc(h, self$name, self$NCvar$vtype, NA)
      } else {
        self$NCdim$write(h)
        RNetCDF::var.def.nc(h, self$name, self$NCvar$vtype, self$name)
      }

      if (self$orientation %in% c("X", "Y", "Z", "T"))
        self$set_attribute("axis", "NC_CHAR", self$orientation)
      self$write_attributes(h, self$name)

      RNetCDF::var.put.nc(h, self$name, private$get_values())

      if (!is.null(self$bounds))
        self$bounds$write(h, self$name)

      lapply(private$lbls, function(l) l$write(nc))

      invisible(self)
    }
  ),

  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Generic CF axis"
    },

    #' @field dimid (read-only) The netCDF dimension id of this axis.
    dimid = function(value) {
      if (missing(value)) {
        if (inherits(self$NCdim, "NCDimension")) self$NCdim$id
        else -1L
      }
    },

    #' @field length (read-only) The declared length of this axis.
    length = function(value) {
      if (missing(value))
        self$NCdim$length
    },

    #' @field values (read-only) Retrieve the raw values of the axis. In general
    #'   you should use the `coordinates` field rather than this one.
    values = function(value) {
      if (missing(value))
        private$get_values()
    },

    #' @field coordinates (read-only) Retrieve the coordinate values of the
    #' axis.
    coordinates = function(value) {
      if (missing(value))
        private$get_coordinates()
    },

    #' @field labels Set or retrieve the labels for the axis. On assignment, the
    #'   value must be an instance of [CFLabel], which is added to the end of
    #'   the list of label sets. On retrieval, the active `CFLabel` instance or
    #'   a `list` of all associated `CFLabel` instances is returned. (If there
    #'   is a label set active and you want to retrieve all label sets, call
    #'   `active_label_set <- NULL` on your axis object before calling this
    #'   method.)
    labels = function(value) {
      if (missing(value)) {
        if (is.null(private$active_label)) private$lbls
        else private$lbls[[private$active_label]]
      } else {
        if (inherits(value, "CFLabel") && value$length == self$length) {
          private$lbls <- append(private$lbls, value)
          names(private$lbls) <- sapply(private$lbls, function(l) l$name)
          if (length(private$lbls) == 1L)
            private$active_label <- 1L
        }
      }
    },

    #' @field has_labels (read-only) Number of label sets associated with the
    #'   axis. The labels can be retrieved with the `label_set()` method.
    has_labels = function(value) {
      if (missing(value))
        length(private$lbls)
    },

    #' @field label_set_names Set or retrieve the names of the label sets
    #'   defined for the axis. Note that the label sets need to have been
    #'   registered with the axis before you can change any names.
    label_set_names = function(value) {
      if (missing(value))
        names(private$lbls)
      else {
        if (!is.character(value) || length(value) != length(private$lbls))
          stop("Vector of label set names must have same length as number of label sets.", call. = FALSE)
        names(private$lbls) <- value
      }
    },

    #' @field active_label_set Set or retrieve the label set to use with the
    #'   axis for printing to the console as well as for processing methods such
    #'   as `subset()`. On assignment, either an integer value or a name of a
    #'   label set. If `NULL`, suppress use of labels. On retrieval, the value
    #'   that the label set was set with, so either an integer value or a name.
    active_label_set = function(value) {
      if (missing(value))
        private$active_label
      else {
        if (is.null(value) || (is.numeric(value) && (value < 1L || value > length(private$lbls))))
          private$active_label <- NULL
        else
          private$active_label <- value
      }
    },

    #' @field unlimited (read-only) Logical to indicate if the axis has an
    #'   unlimited dimension.
    unlimited = function(value) {
      if (missing(value))
        self$NCdim$unlim
    }
  )
)

# Public S3 methods ------------------------------------------------------------

#' Axis length
#'
#' This method returns the lengths of the axes of a variable or axis.
#'
#' @param x The `CFVariable` or a descendant of `CFAxis`.
#' @return Vector of axis lengths.
#' @export
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' t2m <- ds[["t2m"]]
#' dim(t2m)
dim.CFAxis <- function(x) {
  x$length
}

#' @export
dimnames.CFAxis <- function(x) {
  x$dimnames
}
