#' CF data set
#'
#' @description This class represents a CF data set, the object that
#'   encapsulates a netCDF resource. You should never instantiate this class
#'   directly; instead, call [open_ncdf()] which will return an instance that
#'   has all properties read from the netCDF resource, or [create_ncdf()] for a
#'   new, empty instance. Class methods can then be called, or the base R
#'   functions called with this instance.
#'
#'   The CF data set instance provides access to all the objects in the netCDF
#'   resource, organized in groups.
#'
#' @export
#' @docType class
CFDataset <- R6::R6Class("CFDataset",
  private = list(
    .res       = NULL,
    .format    = "netcdf4"
  ),
  public = list(
    #' @field name The name of the netCDF resource. This is extracted from the
    #'   URI (file name or URL).
    name       = "",

    #' @field root Root of the group hierarchy through which all elements of the
    #' netCDF resource are accessed. It is **strongly discouraged** to
    #' manipulate the objects in the group hierarchy directly. Use the provided
    #' access methods instead.
    root = NULL,

    #' @field file_type The type of data in the netCDF resource, if
    #'   identifiable. In terms of the CF Metadata Conventions, this includes
    #'   discrete sampling geometries (DSG). Other file types that can be
    #'   identified include L3b files used by NASA and NOAA for satellite
    #'   imagery (these data sets need special processing), and CMIP5, CMIP6 and
    #'   CORDEX climate projection data.
    file_type = "Generic netCDF data",

    #' @description Create an instance of this class. Do not instantiate this
    #'   class directly; instead, call [open_ncdf()] which will return an
    #'   instance that has all properties read from the netCDF resource, or
    #'   [create_ncdf()] for a new, empty instance.
    #' @param resource An instance of `NCResource` that links to the netCDF
    #'   resource, or a character string with the name of a new data set.
    #' @param format Character string with the format of the netCDF resource as
    #'   reported by the call opening the resource. Ignored when argument
    #'   `resource` is a character string.
    initialize = function(resource, format) {
      if (inherits(resource, "NCResource")) {
        uri <- resource$uri
        self$name <- regmatches(uri, regexec("([^/]*)\\.nc$", uri))[[1L]][2L]
        if (is.na(self$name))
          self$name <- regmatches(uri, regexec("([^/]*)$", uri))[[1L]][2L]

        private$.res <- resource
        private$.format <- format
      } else
        self$name <- resource
    },

    #' @description Summary of the data set printed to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    print = function(...) {
      cat("<Dataset>", self$name, "\n")
      cat("Resource   :", private$.res$uri %||% "(virtual)", "\n")
      cat("Format     :", private$.format, "\n")
      cat("Collection :", self$file_type, "\n")
      cat("Conventions:", self$conventions, "\n")

      if (private$.format == "netcdf4")
        cat("Has groups :", self$has_subgroups(), "\n")

      vars <- self$root$objects("CFVariable")
      nvars <- length(vars)
      if (nvars) {
        if (nvars == 1L) cat("\nVariable:\n") else cat("\nVariables:\n")
        vars <- do.call(rbind, lapply(vars, function(v) v$brief()))
        if (all(vars$long_name == "")) vars$long_name <- NULL
        if (all(vars$units == "")) vars$units <- NULL
        vars <- as.data.frame(vars[lengths(vars) > 0L])
        print(.slim.data.frame(vars, ...), right = FALSE, row.names = FALSE)

        ev <- self$root$objects("CFCellMeasure", recursive = FALSE)
        if (length(ev))
          cat("\nExternal variable", if (length(ev) > 1L) "s", ": ", paste(names(ev), collapse = ", "), "\n", sep = "")
      }

      self$root$print_attributes(width = 50L)
    },

    #' @description Print the group hierarchy to the console.
    hierarchy = function() {
      cat("<CF objects>", self$name, "\n")
      hier <- self$root$hierarchy(1L, 1L)
      cat(hier, sep = "")
    },

    #' @description Get objects by standard_name. Several conventions define
    #'   standard vocabularies for physical properties. The standard names from
    #'   those vocabularies are usually stored as the "standard_name" attribute
    #'   with variables or axes. This method retrieves all variables or axes
    #'   that list the specified "standard_name" in its attributes.
    #'
    #' @param standard_name Optional, a character string to search for a
    #'   specific "standard_name" value in variables and axes.
    #'
    #' @return If argument `standard_name` is provided, a character vector of
    #'   variable or axis names. If argument `standard_name` is missing or an
    #'   empty string, a named list with all "standard_name" attribute values in
    #'   the the netCDF resource; each list item is named for the variable or
    #'   axis.
    objects_by_standard_name = function(standard_name) {
      nm <- c(sapply(self$root$variables(), function(v) v$attribute("standard_name")),
              sapply(self$root$axes(), function(x) x$attribute("standard_name")))
      if (missing(standard_name) || !nzchar(standard_name))
        nm[lengths(nm) > 0L]
      else
        names(nm[which(nm == standard_name)])
    },

    #' @description Does the netCDF resource have subgroups? Newer versions of
    #'   the `netcdf` library, specifically `netcdf4`, can organize dimensions
    #'   and variables in groups. This method will report if the data set is
    #'   indeed organized with subgroups.
    #'
    #' @return Logical to indicate that the netCDF resource uses subgroups.
    has_subgroups = function() {
      length(self$root$subgroups) > 0L
    },

    #' @description Find an object by its name. Given the name of a CF data
    #'   variable or axis, possibly preceded by an absolute group path, return
    #'   the object to the caller.
    #' @param name The name of a CF data variable or axis, with an optional
    #'   absolute group path.
    #' @return The object with the provided name. If the object is not found,
    #'   returns `NULL`.
    find_by_name = function(name) {
      obj <- self$root$find_by_name(name)
      if (is.null(obj))
        self$root$NC$find_by_name(name)
      else
        obj
    },

    #' @description This method lists the CF data variables located in this
    #'   netCDF resource, including those in subgroups.
    #'
    #' @return A list of `CFVariable` instances.
    variables = function() {
      self$root$objects("CFVariable", recursive = TRUE)
    },

    #' @description This method lists the axes located in this netCDF resource,
    #'   including axes in subgroups.
    #'
    #' @return A list of `CFAxis` descendants.
    axes = function() {
      self$root$objects("CFAxis", recursive = TRUE)
    },

    #' @description List all the attributes of a group. This method returns a
    #'   `data.frame` containing all the attributes of the indicated `group`.
    #' @param group The name of the group whose attributes to return. If the
    #'   argument is missing, the global attributes will be returned.
    #' @return A `data.frame` of attributes.
    attributes = function(group) {
      if (missing(group))
        self$root$attributes
      else {
        grp <- self$root$find_by_name(group)
        if (is.null(grp)) NULL
        else grp$attributes
      }
    },

    #' @description Retrieve global attributes of the data set.
    #'
    #' @param att Vector of character strings of attributes to return.
    #' @param field The field of the attribute to return values from. This must
    #'   be "value" (default) or "type".
    #' @return If the `field` argument is "type", a character string. If `field`
    #'   is "value", a single value of the type of the attribute, or a vector
    #'   when the attribute has multiple values. If no attribute is named with a
    #'   value of argument `att` `NA` is returned.
    attribute = function(att, field = "value") {
      self$root$attribute(att, field)
    },

    #' @description Add an attribute to the global attributes. If an attribute
    #'   `name` already exists, it will be overwritten.
    #' @param name The name of the attribute. The name must begin with a letter
    #'   and be composed of letters, digits, and underscores, with a maximum
    #'   length of 255 characters. UTF-8 characters are not supported in
    #'   attribute names.
    #' @param type The type of the attribute, as a string value of a netCDF data
    #'   type.
    #' @param value The value of the attribute. This can be of any supported
    #'   type, including a vector or list of values. Matrices, arrays and like
    #'   compound data structures should be stored as a data variable, not as an
    #'   attribute and they are thus not allowed. In general, an attribute
    #'   should be a character value, a numeric value, a logical value, or a
    #'   short vector or list of any of these. Values passed in a list will be
    #'   coerced to their common mode.
    #' @return Self, invisibly.
    set_attribute = function(name, type, value) {
      self$root$set_attribute(name, type, value)
      invisible(self)
    },

    #' @description Append the text value of a global attribute. If an attribute
    #'   `name` already exists, the `value` will be appended to the existing
    #'   value of the attribute. If the attribute `name` does not exist it will
    #'   be created. The attribute must be of "NC_CHAR" or "NC_STRING" type; in
    #'   the latter case having only a single string value.
    #' @param name The name of the attribute. The name must begin with a letter
    #'   and be composed of letters, digits, and underscores, with a maximum
    #'   length of 255 characters. UTF-8 characters are not supported in
    #'   attribute names.
    #' @param value The character value of the attribute to append. This must be
    #'   a character string.
    #' @param sep The separator to use. Default is `"; "`.
    #' @param prepend Logical to flag if the supplied `value` should be placed
    #'   before the existing value. Default is `FALSE`.
    #' @return Self, invisibly.
    append_attribute = function(name, value, sep = "; ", prepend = FALSE) {
      self$root$append_attribute(name, value, sep, prepend)
      invisible(self)
    },

    #' @description Delete attributes. If an attribute `name` is not present
    #' this method simply returns.
    #' @param name Vector of names of the attributes to delete.
    #' @return Self, invisibly.
    delete_attribute = function(name) {
      self$root$delete_attribute(name)
      invisible(self)
    },

    #' @description Add a [CFVariable] object to the data set. If there is
    #'   another object with the same name in the group where the data variable
    #'   should be placed an error is thrown. For objects associated with the
    #'   data variable (such as axes, CRS, boundary variables, etc), if another
    #'   object with the same name is otherwise identical to the associated
    #'   object then that object will be linked from the variable, otherwise an
    #'   error is thrown.
    #' @param var An instance of `CFVariable` or any of its descendants.
    #' @param group Optional. An instance of [CFGroup] where the data variable
    #'   should be located. If omitted, the data variable will be stored in the
    #'   root group.
    #' @param locations Optional. A `list` whose named elements correspond to
    #'   the names of objects associated with the data variable in argument
    #'   `var`. Each list element has a single character string indicating the
    #'   group in the hierarchy where the object should be stored. As an
    #'   example, if the data variable has axes "lon" and "lat" and they should
    #'   be stored in the parent group of `group`, then specify `locations =
    #'   list(lon = "..", lat = "..")`. Locations can use absolute paths or
    #'   relative paths from the `group`. Associated objects that are not in the
    #'   list will be stored in `group`. If the argument `locations` is not
    #'   provided, all associated objects will be stored in `group`.
    #' @return Argument `var`, invisibly.
    add_variable = function(var, group, locations = list()) {
      if (missing(group)) group <- self$root
      else if(!inherits(group, "CFGroup"))
        stop("Argument `group` must be a CFGroup object.", call. = FALSE)
      if (!inherits(var, "CFVariable"))
        stop("Argument `var` must be a CFVariable object.", call. = FALSE)

      group$add_variable(var, locations)
      invisible(var)
    },

    #' @description Save the data set to file, including its subordinate objects
    #'   such as attributes, data variables, axes, CRS, etc.
    #' @param fn Optional. Fully-qualified file name indicating where to save
    #'   the data set to. This argument must be provided if the data set is
    #'   virtual. If the argument is provided on a data set that was read from a
    #'   netCDF file and it does not point to that netCDF file, a new netCDF
    #'   file will be written to the indicated location. If the argument is the
    #'   same file name as before, the existing netCDF file will be updated.
    #' @param pack Optional. Logical to indicate if the data should be packed;
    #'   default is `FALSE`. Packing is only useful for numeric data; packing is
    #'   not performed on integer values. Packing is always to the "NC_SHORT"
    #'   data type, i.e. 16-bits per value.
    #' @return Self, invisibly.
    save = function(fn = NULL, pack = FALSE) {
      if (is.null(fn)) {
        # Use the current connection
        if (!inherits(private$.res, "NCResource"))
          stop("Must supply file name to save the data set.", call. = FALSE)
      } else if (is.null(private$.res) || fn != private$.res$uri) {
        # Create a new netCDF file
        res <- NCResource$new(fn, write = TRUE)
        res$create()
        private$.res <- res

        # Detach all data variables from old connection
        lapply(self$variables(), function(v) v$detach())
      }

      self$root$write(recursive = TRUE)
      self$root$write_variables(pack, recursive = TRUE)
      private$.res$close()
      invisible(self)
    },

    #' @description Save the data set to a Zarr store with GeoZarr conventions,
    #'   including its subordinate objects such as attributes, data variables,
    #'   axes, CRS, etc. Every principal `CFVariable` will become a
    #'   `geozarr_array` and every `CFGroup` a `zarr_group`. Ancillary data
    #'   variables will typically become a `zarr_array`, i.e. an array not
    #'   having GeoZarr convention attributes. Axes with regular coordinate
    #'   values will be stored in the attributes, saving space and reducing the
    #'   number of such ancillary arrays.
    #'
    #'   The data set will have the same hierarchy in the Zarr store as this
    #'   data set, possibly anchored in some subgroup inside the Zarr store. It
    #'   is highly recommended to use separate empty (or non-existing) groups to
    #'   anchor multiple data sets to avoid the possibility of name collisions.
    #'
    #'   Supported GeoZarr conventions for supplying coordinates are `cs` and
    #'   `spatial`. Due to the limited scope of the latter convention (North-up
    #'   Y coordinates, no support for time or vertical coordinates, 3 axes at
    #'   most) most Zarr arrays will use the `cs` convention. Supporting
    #'   conventions, like `proj` or `ref`, will be used as needed.
    #' @param zarr Optional. Fully-qualified file name or URI indicating where
    #'   to save the data set to, or a `zarr` object. If a file name or URI, it
    #'   must point to an existing Zarr store where the data from this dat aset
    #'   will be appended, or a new Zarr store will be created by that name and
    #'   then it can not already exist. By convention, a new Zarr store should
    #'   have a ".zarr" file name extension. If missing, create a Zarr store in
    #'   memory.
    #' @param dataset_root Optional. Path to a node in the Zarr store where this
    #'   data set will be anchored. If the node does not yet exist, it will be
    #'   created. A path must start from the root node of the Zarr store and be
    #'   specified like "/subgroup/sub/here" with the root of this data set
    #'   starting at the indicated path. Defaults to the root of the Zarr store,
    #'   "/". Alternatively, this may be a `zarr_group` to be used as the root
    #'   for this data set, but only if argument `zarr` is a `zarr` object. If
    #'   the `zarr` argument is not provided, this argument will be ignored.
    #' @return The `zarr` object to which the data set was written.
    geozarr = function(zarr, dataset_root = "/") {
      if (!requireNamespace("geozarr", quietly = TRUE))
        stop("Package 'geozarr' must be installed for this functionality", call. = FALSE)

      # Get the `zarr` object, possibly in a new Zarr store
      if (missing(zarr)) {
        z <- zarr::create_zarr()
        dataset_root <- "/"
      } else if (inherits(zarr, "zarr")) {
        z <- zarr
      } else {
        # zarr argument is a name. Open it or create it.
        z <- try(zarr::create_zarr(zarr), silent = TRUE)
        if (inherits(z, "try-error")) {
          z <- try(zarr::open_zarr(zarr), silent = TRUE)
          if (inherits(z, "try-error"))
            stop("Could not open or create a Zarr store at ", zarr, call. = FALSE)
        }
      }

      # Get the root group for this data set
      if (inherits(dataset_root, "zarr_group")) {
        if (inherits(zarr, "zarr"))
          root_group <- dataset_root
        else
          stop("Data set root group must be a character path to a Zarr group", call. = FALSE)
      } else {
        root_group <- z$get_node(dataset_root)
        if (is.null(root_group)) {
          # Node does not yet exist so create it
          nodes <- strsplit(dataset_root, "/", fixed = TRUE)[[1L]]
          if (nzchar(nodes[1L]))
            stop("Path to the data set root group must start with a slash '/'", call. = FALSE)
          nodes <- nodes[-1L]
          root_group <- z[["/"]]
          while (length(nodes)) {
            grp <- root_group$children[[nodes[1L]]]
            if (is.null(grp))
              grp <- root_group$add_group(nodes[1L])
            root_group <- grp
            nodes <- nodes[-1L]
          }
        }
      }

      # Write the root group of this data set, iterate over contained objects
      self$root$write_geozarr(root_group)

      z
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Data set"
    },

    #' @field resource (read-only) The connection details of the netCDF
    #'   resource. This is for internal use only.
    resource = function(value) {
      if (missing(value))
        private$.res
    },

    #' @field uri (read-only) The connection string to the netCDF resource.
    uri = function(value) {
      if (missing(value))
        if (is.null(private$.res)) NULL else private$.res$uri
    },

    #' @field conventions (read-only) Returns the conventions that this netCDF
    #'   resource conforms to.
    conventions = function(value) {
      if (missing(value)) {
        conv <- self$root$attribute("Conventions")
        if (is.na(conv)) "(not indicated)" else conv
      }
    },

    #' @field var_names (read-only) Vector of names of variables in this data set.
    var_names = function(value) {
      if (missing(value)) {
        if (self$has_subgroups())
          vapply(self$variables(), function(v) v$fullname, character(1L), USE.NAMES = FALSE)
        else
          vapply(self$variables(), function(v) v$name, character(1L), USE.NAMES = FALSE)
      }
    },

    #' @field axis_names (read-only) Vector of names of axes in this data set.
    axis_names = function(value) {
      if (missing(value)) {
        if (self$has_subgroups())
          vapply(self$axes(), function(ax) ax$fullname, character(1L), USE.NAMES = FALSE)
        else
          vapply(self$axes(), function(ax) ax$name, character(1L), USE.NAMES = FALSE)
      }
    }
  )
)

# Public S3 methods ------------------------------------------------------------

#' Compact display of a CFDataset
#' @param object A `CFDataset` instance.
#' @param ... Ignored.
#' @export
#' @keywords internal
str.CFDataset <- function(object, ...) {
  len <- length(names(object))
  plural <- if (len != 1L) "s" else ""
  cat("CFDataset with", len, paste0("data variable", plural))
}

#' @rdname dimnames
#' @export
names.CFDataset <- function(x) {
  if (!length(x$variables())) NULL
  else x$var_names
}

#' @export
dimnames.CFDataset <- function(x) {
  ax <- x$axes()
  if (!length(ax))
    NULL
  else if (x$has_subgroups()) {
    grps <- sapply(ax, function(z) z$group$fullname)
    unique(paste0(ifelse(grps == "/", "/", paste0(grps, "/")), x$axis_names))
  } else
    unique(x$axis_names)
}

#' List the groups in the CF object, recursively.
#' @return A character vector with group names in the object.
#' @export
#' @docType methods
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' groups(ds)
groups <- function(x) {
  UseMethod("groups")
}

#' @rdname groups
#' @param x A `CFDataset` instance.
#' @export
groups.CFDataset <- function(x) {
  nm <- c("/", unlist(x$root$subgroup_names()))
  names(nm) <- NULL
  nm
}

#' Get a CF object from a data set
#'
#' This method can be used to retrieve a variable or axis from the data set by
#' name.
#'
#' If the data set has groups, the name `i` of the variable or axis should be
#' fully qualified with the path to the group where the object is located. This
#' fully qualified name can be retrieved with the [names()] and [dimnames()]
#' functions, respectively.
#'
#' @param x An `CFDataset` to extract a variable or axis from.
#' @param i The name of a variable or axis in `x`. If data set `x` has groups,
#'   `i` should be an absolute path to the object to retrieve.
#'
#' @return An instance of `CFVariable` or an `CFAxis` descendant class, or
#'   `NULL` if the name is not found.
#' @export
#'
#' @aliases [[,CFDataset-method
#' @docType methods
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' v1 <- ds$var_names[1]
#' var <- ds[[v1]]
#' var
`[[.CFDataset` <- function(x, i) {
  x$find_by_name(i)
}
