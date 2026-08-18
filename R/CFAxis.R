#' CF axis object
#'
#' @description This class is a basic ancestor to all classes that represent CF
#'   axes. More useful classes use this class as ancestor.
#'
#'   This super-class does manage the "coordinates" of the axis, i.e. the values
#'   along the axis. This could be the values of the axis as stored on file, but
#'   it can also be the values from an auxiliary coordinate set, in the form of
#'   a [CFLabel] instance. The coordinate set to use in display, selection and
#'   processing is selectable through methods and fields in this class.
#'
#' @docType class
CFAxis <- R6::R6Class("CFAxis",
  inherit = CFData,
  cloneable = FALSE,
  private = list(
    # A character "X", "Y", "Z" or "T" to indicate the
    # orientation of the axis, or an empty string if not known or different.
    .orient = "",

    # A flag to indicate if the axis is unlimited. Always FALSE for in-memory
    # objects upon creation but can be changed. For netCDF files, follow the
    # setting.
    .unlimited = FALSE,

    # The dimension id of the axis. This is set upon initialization.
    .dimid = -1L,

    # The CFBounds instance of this axis, if set, NULL otherwise.
    .bounds = NULL,

    # A list of auxiliary coordinate instances, if any are defined for the axis.
    .aux = list(),

    # The active coordinates set. Either an integer or a name. If there are no
    # auxiliary coordinates or when underlying axis coordinates should be used,
    # it should be 1L.
    .active_coords = 1L,

    # Flag if the axis coordinates are regular. Difference should not be 0.
    .regular = FALSE,

    # Get the names of the auxiliary coordinate instances.
    aux_names = function() {
      sapply(private$.aux, function(aux) aux$name)
    },

    # Get the values of the active coordinate set. In most cases that is just
    # the values but it could be a label set. Most sub-classes override or
    # extend this method.
    get_coordinates = function() {
      crds <- if (private$.active_coords == 1L) {
        self$values
      } else
        private$.aux[[private$.active_coords - 1L]]$coordinates
      dim(crds) <- NULL
      crds
    },

    # Copy a subset of all the auxiliary coordinates to another axis. Argument
    # ax will receive the auxiliary coordinates subsetted by argument rng.
    subset_coordinates = function(ax, rng) {
      if (length(private$.aux)) {
        lapply(private$.aux, function(x) ax$auxiliary <- x$subset(x$name, group = ax$group, rng))
      }
    },

    # When copying, the descendant class makes the new instance, then calls this
    # method to copy details common to all axes. Argument ax is the new copy of
    # this axis, rng is the range of coordinates the new copy uses, use all
    # coordinates when NULL. Returns the new axis.
    copy_properties_into = function(ax, rng = NULL) {
      ax$orientation <- private$.orient
      ax$unlimited <- private$.unlimited

      if (inherits(private$.bounds, "CFBounds"))
        ax$bounds <- private$.bounds$subset(group = ax$group, rng)

      private$subset_coordinates(ax, rng)
      ax$active_coordinates <- self$active_coordinates

      ax
    }
  ),
  public = list(
    #' @description Create a new CF axis instance from a dimension and a
    #'   variable in a netCDF resource. This method is called upon opening a
    #'   netCDF resource by the `initialize()` method of a descendant class
    #'   suitable for the type of axis.
    #'
    #'   Creating a new axis is more easily done with the [makeAxis()] function.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the axis in a vector. Ignored when
    #'   argument `var` is a `NCVariable` object.
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
    #' @return A basic `CFAxis` object.
    initialize = function(var, group, values, start = 1L, count = NA, orientation = "", attributes = data.frame()) {
      orientation <- orientation[1L]
      if (!(orientation %in% c("X", "Y", "Z", "T", "")))
        stop("Invalid orientation for the axis", call. = FALSE) # nocov

      # Scalar axes don't have .NC_map, so catch NULL values from $copy() etc
      if (is.null(start)) start <- 1L
      if (is.null(count)) count <- NA

      super$initialize(var, group = group, values = values, start = start, count = count, attributes = attributes)
      if (inherits(var, "NCVariable")) {
        private$.unlimited <- if (private$.NCobj$ndims) private$.NCobj$dimension(1L)$unlim else FALSE
        private$.dimid <- private$.NCobj$dimids[1L]
      }

      private$.orient <- orientation
      if (orientation != "")
        self$set_attribute("axis", "NC_CHAR", orientation)

      if (missing(values) || is.null(values))
        self$read_data()

      self$delete_attribute("_FillValue")
    },

    #' @description  Prints a summary of the axis to the console. This method is
    #'   typically called by the `print()` method of descendant classes.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    #' @return `self`, invisibly.
    print = function(...) {
      cat("<", self$friendlyClassName, "> [", private$.id, "] ", private$.name, "\n", sep = "")

      fullname <- self$fullname
      if (fullname != paste0("/", self$name))
        cat("Path name  :", fullname, "\n")

      longname <- self$attribute("long_name")
      if (!is.na(longname) && longname != self$name)
        cat("Long name  :", longname, "\n")

      cat("Length     :", self$length)
      if (self$unlimited) cat(" (unlimited)\n") else cat("\n")
      cat("Axis       :", private$.orient, "\n")
      if (length(private$.aux))
        cat("Label sets :", paste(self$coordinate_names, collapse = ", "), "\n")
    },

    #' @description Some details of the axis.
    #' @return A 1-row `data.frame` with some details of the axis.
    brief = function() {
      nm <- if (!is.null(ds <- self$group$data_set) && ds$has_subgroups())
        self$fullname
      else
        self$name

      if (private$.active_coords > 1L) {
        longname <- private$.aux[[private$.active_coords - 1L]]$name
        units <- private$.aux[[private$.active_coords - 1L]]$attribute("units")
      } else {
        longname <- self$attribute("long_name")
        if (is.na(longname) || longname == nm) longname <- ""
        units <- self$attribute("units")
      }
      len <- if (self$unlimited) paste0(self$length, "-U") else self$length
      if (is.na(units)) units <- ""
      else if (units == "1") units <- ""

      data.frame(axis = private$.orient, name = nm, long_name = longname,
                 length = len, values = "", unit = units)
    },

    #' @description Very concise information on the axis. The information
    #'   returned by this function is very concise and most useful when combined
    #'   with similar information from other axes.
    #' @return Character string with very basic axis information.
    shard = function() {
      unlim <- if (self$unlimited) "-U" else ""
      if (self$length == 1L)
        paste0("[", self$name, " (", self$length, unlim, "): ", self$coordinates, "]")
      else {
        crds <- self$coordinate_range
        paste0("[", self$name, " (", self$length, unlim, "): ", crds[1L], " ... ", crds[2L], "]")
      }
    },

    #' @description Retrieve interesting details of the axis.
    #' @return A 1-row `data.frame` with details of the axis.
    peek = function() {
      out <- data.frame(class = class(self)[1L], id = self$id, axis = private$.orient)
      out$name <- self$name
      out$long_name <- self$attribute("long_name")
      out$standard_name <- self$attribute("standard_name")
      out$units <- self$attribute("units")
      out$length <- self$length
      out$unlimited <- self$unlimited
      out$values <- private$dimvalues_short()
      out$has_bounds <- inherits(private$.bounds, "CFBounds")
      out$coordinate_sets <- length(private$.aux) + 1L
      out
    },

    #' @description Detach the axis from its underlying netCDF resource,
    #'   including any dependent CF objects.
    #' @return Self, invisibly.
    detach = function() {
      if (!is.null(private$.bounds))
        private$.bounds$detach()
      lapply(private$.aux, function(x) x$detach())
      super$detach()
      invisible(self)
    },

    #' @description Copy the parametric terms of a vertical axis. This method is
    #'   only useful for `CFAxisVertical` instances having a parametric
    #'   formulation. This stub is here to make the call to this method succeed
    #'   with no result for the other descendant classes.
    #' @param from A CFAxisVertical instance that will receive references to the
    #' parametric terms.
    #' @param original_axes List of `CFAxis` instances from the CF object that
    #'   these parametric terms are copied from.
    #' @param new_axes List of `CFAxis` instances to use with the formula term
    #'   objects.
    #' @return `NULL`
    copy_terms = function(from, original_axes, new_axes) {
      NULL
    },

    #' @description Configure the function terms of a parametric vertical axis.
    #'   This method is only useful for `CFAxisVertical` instances having a
    #'   parametric formulation. This stub is here to make the call to this
    #'   method succeed with no result for the other descendant classes.
    #' @param axes List of `CFAxis` instances.
    #' @return `NULL`
    configure_terms = function(axes) {
      NULL
    },

    #' @description Tests if the axis passed to this method is identical to
    #'   `self`. This only tests for generic properties - class, length, name
    #'   and attributes - with further assessment done in sub-classes.
    #' @param axis The `CFAxis` instance to test.
    #' @param with_attributes Logical that indicates if the attributes are
    #'   assessed for equality too. Default is `FALSE`.
    #' @return `TRUE` if the two axes are identical, `FALSE` if not.
    identical = function(axis, with_attributes = FALSE) {
      class(self)[1L] == class(axis)[1L] &&
      self$length == axis$length &&
      self$name == axis$name &&
      (!with_attributes || self$attributes_identical(axis$attributes))
    },

    #' @description Tests if the axis passed to this method can be appended to
    #'   `self`. This only tests for generic properties - class, mode of the
    #'   values and name - with further assessment done in sub-classes.
    #' @param axis The `CFAxis` descendant instance to test.
    #' @return `TRUE` if the passed axis can be appended to `self`, `FALSE` if
    #'   not.
    can_append = function(axis) {
      all(class(self) == class(axis)) &&
      mode(self$values) == mode(axis$values) &&
      self$name == axis$name
    },

    #' @description Create a copy of this axis. This method is "virtual" in the
    #'   sense that it does not do anything other than return `NULL`. This stub
    #'   is here to make the call to this method succeed with no result for the
    #'   `CFAxis` descendants that do not implement this method.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return `NULL`
    copy = function(name = "", group) {
      NULL
    },

    #' @description Create a copy of this axis but using the supplied values.
    #'   This method is "virtual" in the sense that it does not do anything
    #'   other than return `NULL`. This stub is here to make the call to this
    #'   method succeed with no result for the `CFAxis` descendants that do not
    #'   implement this method.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param values The values to the used with the copy of this axis.
    #' @return `NULL`
    copy_with_values = function(name = "", group, values) {
      NULL
    },

    #' @description Return an axis spanning a smaller coordinate range. This
    #'   method is "virtual" in the sense that it does not do anything other
    #'   than return `self`. This stub is here to make the call to this method
    #'   succeed with no result for the  `CFAxis` descendants that do not
    #'   implement this method.
    #' @param name The name for the new axis if the `rng` argument is provided.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param rng The range of indices whose values from this axis to include in
    #'   the returned axis. If the value of the argument is `NULL`, return a
    #'   copy of the axis.
    #' @return `NULL`
    subset = function(name = "", group, rng = NULL) {
      NULL
    },

    #' @description Find indices in the axis domain. Given a vector of
    #'   numerical, timestamp or categorical coordinates `x`, find their indices
    #'   in the coordinates of the axis.
    #'
    #'   This is a virtual method. For more detail, see the corresponding method
    #'   in descendant classes.
    #' @param x Vector of numeric, timestamp or categorial coordinates to find
    #'   axis indices for. The timestamps can be either character, POSIXct or
    #'   Date vectors. The type of the vector has to correspond to the type of
    #'   the axis values.
    #' @param method Single character value of "constant" or "linear".
    #' @param rightmost.closed Whether or not to include the upper limit.
    #' Default is `TRUE`.
    #' @return Numeric vector of the same length as `x`.
    indexOf = function(x, method = "constant", rightmost.closed = TRUE) {
      stop("`indexOf()` must be implemented by descendant CFAxis class.")
    },

    #' @description Attach this axis to a group. If there is another object with
    #'   the same name in this group an error is thrown. For associated objects
    #'   (such as bounds, etc), if another object with the same name is
    #'   otherwise identical to the associated object then that object will be
    #'   linked from the variable, otherwise an error is thrown.
    #' @param grp An instance of [CFGroup].
    #' @param locations Optional. A `list` whose named elements correspond to
    #'   the names of objects associated with this axis, possibly including the
    #'   axis itself. Each list element has a single character string indicating
    #'   the group in the hierarchy where the object should be stored. As an
    #'   example, if the variable has axes "lon" and "lat" and they should be
    #'   stored in the parent group of `grp`, then specify `locations = list(lon
    #'   = "..", lat = "..")`. Locations can use absolute paths or relative
    #'   paths from group `grp`. The axis and associated objects that are not in
    #'   the list will be stored in group `grp`. If the argument `locations` is
    #'   not provided, all associated objects will be stored in this group.
    #' @return Self, invisibly.
    attach_to_group = function(grp, locations = list()) {
      # Boundary values and auxiliary coordinates first
      if (!is.null(private$.bounds))
        private$.bounds$attach_to_group(grp, locations)
      lapply(private$.aux, function(aux) aux$attach_to_group(grp, locations))

      # Now add the axis to the group
      super$attach_to_group(grp, locations)
    },

    #' @description Write the axis to a netCDF file, including its attributes.
    #' @return Self, invisibly.
    write = function() {
      if (is.null(private$.NCobj)) {
        grp <- private$.group$NC
        if (is.null(grp))
          stop("Axis ", self$name, " has no netCDF group.")

        # Try to find a NC variable and its associated dimension
        ncobj <- grp$find_by_name(self$fullname)
        if (is.null(ncobj)) {
          # Create a new NC dimension and variable on file.
          if (self$length == 1L && !private$.unlimited)
            private$.NCobj <- NCVariable$new(id = NA, name = self$name, group = grp,
                                             vtype = private$.data_type, dimids = NA)
          else {
            private$.dimid <- NCDimension$new(id = NA, name = self$name, length = self$length,
                                              unlim = private$.unlimited, group = grp)$id
            private$.NCobj <- NCVariable$new(id = NA, name = self$name, group = grp,
                                             vtype = private$.data_type, dimids = private$.dimid)
          }
        } else if (inherits(ncobj, "NCDimension")) {
          # NC dimension was found so NC variable does not exist
          if (self$length == ncobj$length && private$.unlimited == ncobj$unlim) {
            private$.dimid <- ncobj$id
            private$.NCobj <- NCVariable$new(id = NA, name = self$name, group = grp,
                                             vtype = private$.data_type, dimids = private$.dimid)
          } else
            stop("Incompatible dimension by this name already exists.", call. = FALSE)
        } else {
          # NC variable was found
          if (private$.data_type == ncobj$vtype && ncobj$ndims == 1L &&
              self$length == ncobj$dimension(1L)$length &&
              private$.unlimited == ncobj$dimension(1L)$unlim) {
            private$.NCobj <- ncobj
            private$.dimid <- ncobj$dimids
          } else
            stop("Incompatible object by this name already exists.", call. = FALSE)
        }
        private$.id <- private$.NCobj$id
        private$.data_dirty <- TRUE
        private$write_data()
      }

      if (private$.orient %in% c("X", "Y", "Z", "T"))
        self$set_attribute("axis", "NC_CHAR", private$.orient)
      self$write_attributes()

      # Bounds
      if (!is.null(private$.bounds))
        private$.bounds$write(private$.dimid)

      # Auxiliary coordinates
      lapply(private$.aux, function(l) {l$dimid <- private$.dimid; l$write()})

      invisible(self)
    },

    #' @description Create the GeoZarr coordinate system axis for this axis,
    #'   inclusive of auxiliary coordinates. This will also include boundary
    #'   values.
    #' @param grp An instance of `zarr_group` where the axis will be located in
    #'   the Zarr store. The axis will be written to a new Zarr array with the
    #'   name of the axis if it is irregular and long.
    #' @return An instance of [geozarr::CoordinateSystemAxis].
    geozarr_axis = function(grp) {
      # parametric vertical, discrete?
      all_crds <- lapply(c(self, private$.aux), function(crd) {
        crd$geozarr_coordinates(grp)
      })
      orient <- private$.orient
      if (!nzchar(orient)) orient <- " "
      geozarr::CoordinateSystemAxis$new(self$name, orient, all_crds)
    },

    #' @description Create the GeoZarr coordinates for this axis. If the
    #'   coordinate values are not regular and longer than a set minimum, write
    #'   the coordinates to the group as a new Zarr array if it does not yet
    #'   exist. This will also include boundary values.
    #' @param grp An instance of `zarr_group` where the coordinates will be
    #'   located in the Zarr store. The coordinates will be written to a new
    #'   Zarr array with the name based on the axis name if it is irregular and
    #'   long.
    #' @return An instance of [geozarr::Coordinates] or a descendant class.
    geozarr_coordinates = function(grp) {
      len <- self$length
      orient <- self$orientation
      vals <- self$values
      dir <- if (len == 1L || !nzchar(orient) || !is.numeric(vals)) "OTHER"
      else switch(orient, # CFAxisTime and CFAxisVertical override
                  X = "EAST",
                  Y = "NORTH")

      unit <- self$attribute("units")
      if (is.na(unit) || unit == "") unit <- "1"
      else if (grepl("^degree(s?)(_?)(east|E)$", unit) ||
               grepl("^degree(s?)(_?)(north|N)$", unit))
        unit <- "degree"

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

      # Attributes that are structural are managed by the convention used so
      # filter them out before writing. Leave others that are descriptive of the
      # data.
      atts <- private$zarr_attributes(c("axis", "bounds", "units", "actual_range"))

      # Regular coordinate values
      if (private$.regular)
        return(geozarr::CoordinatesPacked$new(self$name, dir, unit,
                                              c(vals[1L], vals[2L] - vals[1L]), len, bnds, atts))

      # Irregular
      if (self$length > geozarr::geozarr_options()$max_explicit) {
        # Create a Zarr array for the axis coordinates if it does not already exist
        if (is.null(grp$children[[self$name]])) {
          ab <- zarr::array_builder$new()
          ab$shape <- len
          ab$data_type <- switch(storage.mode(vals),
                                 "double" = "float64",
                                 "integer" = "int32",
                                 "character" = "string")
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

      geozarr::Coordinates$new(self$name, dir, unit, vals, bnds, atts)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Generic CF axis"
    },

    #' @field dimid The netCDF dimension id of this axis. Setting this value to
    #' anything other than the correct value will lead to disaster.
    dimid = function(value) {
      if (missing(value))
        private$.dimid
      else
        private$.dimid <- value
    },

    #' @field length (read-only) The declared length of this axis.
    length = function(value) {
      if (missing(value))
        length(self$values)
    },

    #' @field orientation Set or retrieve the orientation of the axis, a single
    #'   character with a value of "X", "Y", "Z", "T". Setting the orientation
    #'   of the axis should only be done when the current orientation is
    #'   unknown. Setting a wrong value may give unexpected errors in processing
    #'   of data variables.
    orientation = function(value) {
      if (missing(value))
        private$.orient
      else {
        if (!is.character(value) || length(value) != 1L || !(value %in% c("X", "Y", "Z", "T", "")))
          stop("Axis orientation must be a single character 'X', 'Y', 'Z' or 'T'.", call. = FALSE) # nocov
        private$.orient <- value
      }
    },

    #' @field values (read-only) Retrieve the raw values of the axis. In general
    #'   you should use the `coordinates` field rather than this one.
    values = function(value) {
      if (missing(value))
        self$read_data()
    },

    #' @field coordinates (read-only) Retrieve the coordinate values of the
    #' active coordinate set from the axis.
    coordinates = function(value) {
      if (missing(value))
        private$get_coordinates()
      # FIXME: Must be able to add coordinates too, f.i. in an unlimited axis.
    },

    #' @field regular (read-only) Flag if the numeric or time axis coordinates
    #'   are regular, meaning equally spaced.
    regular = function(value) {
      if (missing(value))
        private$.regular
    },

    #' @field bounds Set or retrieve the bounds of this axis as a [CFBounds]
    #'   object. When setting the bounds, the bounds values must agree with the
    #'   coordinates of this axis.
    bounds = function(value) {
      if (missing(value))
        private$.bounds
      else if (inherits(value, "CFBounds")) {
        # FIXME: Check the bounds values, could be climatology
        private$.bounds <- value
        self$set_attribute("bounds", "NC_CHAR", value$name)
      } else if (!is.null(value))
        stop("Must assign a `CFBounds` object to the axis.", call. = FALSE) # nocov
    },

    #' @field auxiliary Set or retrieve auxiliary coordinates for the axis. On
    #'   assignment, the value must be an instance of [CFLabel] or a [CFAxis]
    #'   descendant, which is added to the end of the list of coordinate sets.
    #'   On retrieval, the active `CFLabel` or `CFAxis` instance or `NULL` when
    #'   the active coordinate set is the primary axis coordinates.
    auxiliary = function(value) {
      if (missing(value)) {
        if (private$.active_coords == 1L) NULL
        else private$.aux[[private$.active_coords - 1L]]
      } else {
        if (inherits(value, c("CFLabel", "CFAxis")) &&
            value$length == self$length && !(value$name %in% private$aux_names())) {
          private$.aux <- append(private$.aux, setNames(list(value), value$name))
        }
      }
    },

    #' @field coordinate_names (read-only) Retrieve the names of the coordinate
    #'   sets defined for the axis, as a character vector. The first element in
    #'   the vector is the name of the axis and it refers to the values of the
    #'   coordinates of this axis. Following elements refer to auxiliary
    #'   coordinates.
    coordinate_names = function(value) {
      if (missing(value))
        c(self$name, names(private$.aux))
    },

    #' @field coordinate_range (read-only) Retrieve the range of the coordinates
    #' of the axis as a vector of two values. The mode of the result depends on
    #' the sub-type of the axis.
    coordinate_range = function(value) {
      if (missing(value)) {
        crds <- self$coordinates
        if (is.null(crds)) NULL
        else c(crds[1L], crds[length(crds)])
      }
    },

    #' @field active_coordinates Set or retrieve the name of the coordinate set
    #'   to use with the axis for printing to the console as well as for
    #'   processing methods such as `subset()`.
    active_coordinates = function(value) {
      if (missing(value))
        self$coordinate_names[private$.active_coords]
      else {
        ndx <- match(value, self$coordinate_names, nomatch = 0L)
        if (ndx > 0L)
          private$.active_coords <- ndx
      }
    },

    #' @field unlimited Logical to indicate if the axis is unlimited. The
    #'   setting can only be changed if the axis has not yet been written to
    #'   file.
    unlimited = function(value) {
      if (missing(value))
        private$.unlimited
      else if (is.null(private$.NCobj) && is.logical(value))
        private$.unlimited <- value[1L]
    },

    #' @field time (read-only) Retrieve the `CFTime` object associated with the
    #' axis. Always returns `NULL` but `CFAxisTime` overrides this field.
    time = function(value) {
      if (missing(value))
        NULL
    },

    #' @field is_parametric (read-only) Logical flag that indicates if the axis
    #'   has parametric coordinates. Always `FALSE` for all axes except for
    #'   [CFAxisVertical] which overrides this method.
    is_parametric = function(value) {
      if (missing(value))
        FALSE
    }
  )
)

# Public S3 methods ------------------------------------------------------------

#' Axis length
#'
#' This method returns the lengths of the axes of a variable or axis.
#'
#' @param x A `CFVariable` instance or a descendant of `CFAxis`.
#' @return For a `CFVariable` instance in argument `x`, a named vector of axis
#'   lengths, excluding any scalar axes. For a `CFAxis` descendant instance in
#'   argument `x`, the length of the axis.
#' @export
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' t2m <- ds[["t2m"]]
#' dim(t2m)
#' dim(t2m$axes[["time"]])
dim.CFAxis <- function(x) {
  x$length
}

#' @export
dimnames.CFAxis <- function(x) {
  x$dimnames
}

#' Compact display of an axis.
#' @param object A `CFAxis` instance or any descendant.
#' @param ... Ignored.
#' @export
#' @keywords internal
str.CFAxis <- function(object, ...) {
  cat(paste0("<", object$friendlyClassName, "> ", object$shard(), "\n"))
}
