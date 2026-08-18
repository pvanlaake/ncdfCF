#' CF label object
#'
#' @description This class represent CF labels, i.e. a variable of character
#' type that provides a textual label for a discrete or general numeric axis.
#' See also [CFAxisCharacter], which is an axis with character labels.
#'
#' @docType class
#' @export
CFLabel <- R6::R6Class("CFLabel",
  inherit = CFData,
  cloneable = FALSE,
  private = list(
    .dimid = -1L,     # The NC dimension identifier or -1L when virtual

    # Always FALSE because not relevant for character strings
    .regular = FALSE
  ),
  public = list(
    #' @description Create a new instance of this class.
    #' @param var The [NCVariable] instance upon which this CF object is based
    #'   when read from a netCDF resource, or the name for the object new CF
    #'   object to be created.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The labels of the CF object. Ignored when
    #'   argument `var` is a `NCVariable` object.
    #' @param start Optional. Integer index value indicating where to start
    #'   reading data from the file. The value may be `NA` (default) to read all
    #'   data, otherwise it must not be larger than the number of labels.
    #'   Ignored when argument `var` is not an `NCVariable` instance.
    #' @param count Optional. Integer value indicating the number of labels to
    #'   read from file. The value may be `NA` to read to the end of the labels,
    #'   otherwise its value must agree with the corresponding `start` value and
    #'   the number of labels on file. Ignored when argument `var` is not an
    #'   `NCVariable` instance.
    #' @return A `CFLabel` instance.
    initialize = function(var, group, values = NA, start = NA, count = NA) {
      super$initialize(var, group, values = values, start = start, count = count)
      if (inherits(var, "NCVariable"))
        private$.dimid <- var$dimids
      if (is.null(values) || (length(values) == 1L && is.na(values)))
        self$read_data()
    },

    #' @description  Prints a summary of the labels to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    print = function(...) {
      cat("<Label set> ", self$name, "\n", sep = "")

      longname <- self$attribute("long_name")
      if (!is.na(longname) && longname != self$name)
        cat("Long name:", longname, "\n")

      cat("Length   :", self$length, "\n")
      cat("Data type:", self$data_type, "\n")
      self$print_attributes(...)
    },

    #' @description Tests if the object passed to this method is identical to
    #'   `self`.
    #' @param lbl The `CFLabel` instance to test.
    #' @return `TRUE` if the two label sets are identical, `FALSE` if not.
    identical = function(lbl) {
      class(lbl)[1L] == "CFLabel" && self$length == lbl$length &&
      self$name == lbl$name && self$attributes_identical(lbl$attributes) &&
      all(self$coordinates == lbl$coordinates)
    },

    #' @description Create a copy of this label set. The copy is completely
    #'   separate from `self`, meaning that both `self` and all of its
    #'   components are made from new instances.
    #' @param name The name for the new label set. If an empty string is passed,
    #'   will use the name of this label set.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return The newly created label set.
    copy = function(name = "", group) {
      if (self$has_resource) {
        lbl <- CFLabel$new(self$NC, group = group, start = private$.NC_map$start, count = private$.NC_map$count)
        if (nzchar(name))
          lbl$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        lbl <- CFLabel$new(name, group = group, values = self$values)
      }
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

    #' @description Retrieve a subset of the labels.
    #' @param name The name for the new label set, optional.
    #' @param group The [CFGroup] where the copy of this label set will live.
    #' @param rng The range of indices whose values from this axis to include in
    #'   the returned axis.
    #' @return A `CFLabel` instance, or `NULL` if the `rng` values are invalid.
    subset = function(name, group, rng) {
      if (is.null(rng))
        self$copy(name, group)
      else {
        if (missing(name)) name <- self$name
        rng <- as.integer(range(rng))
        if (rng[1L] < 1L || rng[2L] > self$length)
          NULL
        else {
          if (self$has_resource) {
            l <- CFLabel$new(private$.NCobj, group = group, values = self$values[rng[1L]:rng[2L]],
                             start = rng[1L], count = rng[2L] - rng[1L] + 1L)
            l$name <- name
            l
          } else
            CFLabel$new(name, group = group, values = self$coordinates[rng[1L]:rng[2L]])
        }
      }
    },

    #' @description Write the labels to a netCDF file, including its attributes.
    #' @return Self, invisibly.
    write = function() {
      if (is.null(private$.NCobj)) {
        # Try to find a NC variable
        ncobj <- private$.group$NC$find_by_name(self$fullname)
        private$.NCobj <- if (is.null(ncobj))
          # Create a new NC variable
          NCVariable$new(id = NA, name = self$name, group = private$.group$NC,
                         vtype = "NC_STRING", dimids = private$.dimid)
        else ncobj

        private$.data_dirty <- TRUE
        private$write_data()
      }

      self$write_attributes()
    },

    #' @description Create the GeoZarr coordinates for this label set. If the
    #'   label set is longer than a set minimum, write the label values to the
    #'   group as a new Zarr array if it does not yet exist.
    #' @param grp An instance of `zarr_group` where the label values will be
    #'   located in the Zarr store. The label values will be written to a new
    #'   Zarr array with the name based on the name of this label set if it is
    #'   irregular and long.
    #' @return An instance of [geozarr::CoordinatesString].
    geozarr_coordinates = function(grp) {
      len <- self$length
      vals <- self$values
      atts <- private$zarr_attributes()

      # Labels are always irregular
      if (self$length > geozarr_options()$max_explicit) {
        # Create a Zarr array for the axis coordinates if it does not already exist
        if (is.null(grp$children[[self$name]])) {
          ab <- zarr::array_builder$new()
          ab$shape <- len
          ab$data_type <- "string"
          ab$chunk_shape <- len
          if (len > zarr::zarr_options()$min_compress)
            ab$add_codec("blosc", list(clevel = 6L))
          meta <- ab$metadata()
          meta$attributes <- atts
          new_array <- try(grp$add_array(self$name, meta), silent = TRUE)
          if (inherits(new_array, "try-error"))
            stop("Could not create Zarr array with name", self$name, call. = FALSE)
          new_array$write(vals)
          new_array$dirty <- TRUE
          new_array$save()
        }
      }

      geozarr::CoordinatesString$new(self$name, "OTHER", "1", vals, atts)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Label set"
    },

    #' @field values Set or retrieve the labels of this object. In general you
    #'   should use the `coordinates` field rather than this one. Upon setting
    #'   values, if there is a linked netCDF resource, this object will be
    #'   detached from it.
    values = function(value) {
      if (missing(value)) {
        self$read_data()
      } else if (length(value) == length(private$.values)) {
        private$set_values(value)
        private$.regular <- if (is.numeric(value)) .is_regular(value) else FALSE
        self$detach()
      }
    },

    #' @field coordinates (read-only) Retrieve the labels of this object. Upon
    #'   retrieval, label values are read from the netCDF resource, if there is
    #'   one, upon first access and cached thereafter.
    coordinates = function(value) {
      if (missing(value))
        self$values
    },

    #' @field length (read-only) The number of labels in the set.
    length = function(value) {
      if (missing(value)) {
        if (!is.null(self$values))
          length(self$values)
        else self$dim(1L)
      }
    },

    #' @field dimid The netCDF dimension id of this label set. Setting this
    #'   value to anything other than the correct value will lead to disaster.
    dimid = function(value) {
      if (missing(value))
        private$.dimid
      else
        private$.dimid <- value
    }
  )
)
