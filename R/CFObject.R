#' @import methods
#' @import R6
#' @include NCObject.R
NULL

#' CF base object
#'
#' @description This class is a basic ancestor to all classes that represent CF
#'   objects. More useful classes use this class as ancestor.
#'
#' @docType class
CFObject <- R6::R6Class("CFObject",
  private = list(
    # The NC object that this CF object represents if it was read from
    # file.
    .NCobj = NULL,

    # The id and name of this object. They are taken from the NC object upon
    # creation, if supplied, otherwise the name should be supplied and the id
    # will be generated.
    .id = -1L,
    .name = "",

    # The CFGroup that this object lives in.
    .group = NULL,

    # Flag to indicate if there are any unsaved edits to the object and
    # separately for the attributes.
    .dirty = FALSE,
    .attributes_dirty = FALSE,

    # The attributes of the CF object. Upon read from a netCDF resource they are
    # copied from the NC object. For a new CF object, just an empty data.frame
    # with the appropriate columns.
    .attributes = data.frame(name = character(0), type = character(0), length = integer(0), value = numeric(0)),

    set_name = function(new_name) {
      stop("CF classes must implement this method.", call. = FALSE) # nocov
    },

    # Sanitize the attributes argument. Returns a safe data.frame to use.
    check_attributes = function(attributes) {
      if (!is.data.frame(attributes))
        stop("Argument `attributes` must be a valid data.frame.", call. = FALSE) # nocov

      if (!nrow(attributes))
        return(data.frame(name = character(0), type = character(0), length = integer(0), value = numeric(0)))

      # FIXME: Ensure that the appropriate columns and types are present

      attributes
    },

    # Convert CF attributes in a data.frame into a Zarr named list, possibly
    # deleting some of the attributes. Returns the list to the caller.
    zarr_attributes = function(delete) {
      atts <- self$attributes # data.frame
      if (!missing(delete))
        atts <- atts[!atts$name %in% delete, ]
      atts <- if (is.list(atts$value)) setNames(atts$value, atts$name)
      else setNames(list(atts$value), atts$name) # named list

      # Convert atomic vectors of length > 1 into nested unnamed list
      atts <- lapply(atts, function(att)
        {if (is.atomic(att) && length(att) > 1L) unname(as.list(att)) else att})
    },

    # Make sure we detach before we poof out.
    finalize = function() {
      if (!is.null(private$.NCobj) && inherits(private$.NCobj, "NCVariable"))
        private$.NCobj$detach(self)
    }
  ),
  public = list(
    #' @description Create a new `CFobject` instance in memory or from an object
    #'   in a netCDF resource when this method is called upon opening a netCDF
    #'   resource. It is rarely, if ever, useful to call this constructor
    #'   directly. Instead, use the methods from higher-level classes such as
    #'   [CFVariable].
    #' @param obj The [NCObject] instance upon which this CF object is based
    #'   when read from a netCDF resource, or the name for the new CF object to
    #'   be created.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   object. When argument `obj` is an `NCGroup` instance and this argument
    #'   is an empty `data.frame` (default), arguments will be read from the
    #'   resource.
    #' @param group The [CFGroup] instance that this object will live in. The
    #'   default is `NULL` but this is only useful for `CFGroup` instance.
    #' @return A `CFObject` instance.
    initialize = function(obj, attributes = data.frame(), group = NULL) {
      atts <- private$check_attributes(attributes)

      if (is.character(obj)) {
        if (!.is_valid_name(obj))
          stop("Name is not valid for a CF object.", call. = FALSE) # nocov
        private$.name <- obj
        private$.id <- CF$newVarId()
        private$.attributes <- atts
        private$.dirty <- TRUE
        private$.attributes_dirty <- nrow(atts) > 0L
      } else {
        obj$CF <- self
        private$.NCobj <- obj
        private$.id <- obj$id
        private$.name <- obj$name
        private$.attributes <- if (nrow(attributes)) atts
                               else obj$attributes[-1L]
        self$delete_attribute(c("_ChunkSizes", "coordinates"))
      }
      private$.group <- group
      if (!is.null(group))
        group$add_CF_object(self)
    },

    #' @description Attach this CF object to a group. If there is another object
    #'   with the same name in this group an error is thrown. This is the basic
    #'   method that may be overridden by descendant classes.
    #' @param grp An instance of [CFGroup].
    #' @param locations Optional. A `list` whose named elements correspond to
    #'   the names of objects, possibly including this object. Each list element
    #'   has a single character string indicating the group in the hierarchy
    #'   where the object should be stored. As an example, if a data variable
    #'   has axes "lon" and "lat" and they should be stored in the parent group
    #'   of `grp`, then specify `locations = list(lon = "..", lat = "..")`.
    #'   Locations can use absolute paths or relative paths from group `grp`. If
    #'   the argument `locations` is not provided or the name of the object is
    #'   not in the list, the object will be stored in group `grp`.
    #' @return Self, invisibly.
    attach_to_group = function(grp, locations = list()) {
      g <- grp$find_by_name(locations[[self$name]]) %||% grp
      if (g$id != private$.group$id) {
        private$.group$remove_CF_object(self$id)
        g$add_CF_object(self)
        private$.group <- g
        private$.dirty <- TRUE
      }
      invisible(self)
    },

    #' @description Detach the current object from its underlying netCDF
    #'   resource.
    detach = function() {
      if (!is.null(private$.NCobj)) {
        private$.NCobj$detach(self)
        private$.NCobj <- NULL
        private$.dirty <- TRUE
        private$.attributes_dirty <- TRUE
      }
    },

    #' @description Retrieve an attribute of a CF object.
    #'
    #' @param att Single character string of attribute to return.
    #' @param field The field of the attribute to return values from. This must
    #'   be "value" (default) or "type".
    #' @return If the `field` argument is "type", a character string. If `field`
    #'   is "value", a single value of the type of the attribute, or a vector
    #'   when the attribute has multiple values. If no attribute is named with a
    #'   value of argument `att` `NA` is returned.
    attribute = function(att, field = "value") {
      if (length(att) > 1L)
        stop("Can extract only one attribute at a time.", call. = FALSE) # nocov

      atts <- private$.attributes
      if (!nrow(atts)) return(NA)
      val <- atts[atts$name == att, ]
      if (!nrow(val)) return(NA)

      val[[field]][[1L]]
    },

    #' @description Print the attributes of the CF object to the console.
    #'
    #' @param width The maximum width of each column in the `data.frame` when
    #' printed to the console.
    print_attributes = function(width = 30L) {
      if (nrow(private$.attributes)) {
        cat("\nAttributes:\n")
        print(.slim.data.frame(private$.attributes, width), right = FALSE, row.names = FALSE)
      }
    },

    #' @description Add an attribute. If an attribute `name` already exists, it
    #'   will be overwritten.
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
      if (is.na(name) || !is.character(name) || length(name) != 1L)
        stop("Must name one attribute to set values for.", call. = FALSE) # nocov
      if (!type %in% netcdf_data_types)
        stop("Invalid netCDF data type.", call. = FALSE) # nocov

      # Prepare values
      value <- unlist(value, use.names = FALSE)
      if (is.list(value) || is.array(value))
        stop("Unsupported value for attribute (compound list, matrix, array?).", call. = FALSE) # nocov
      if (is.character(value)) {
        if (type == "NC_STRING") len <- length(value)
        else if (type == "NC_CHAR") {
          value <- paste(value, sep = ", ")
          len <- nchar(value)
        } else stop("Wrong attribute type for string value.", call. = FALSE) # nocov
      } else {
        if (is.logical(value)) value <- as.integer(value)
        if (is.numeric(value)) len <- length(value)
        else stop("Unsupported value for attribute.", call. = FALSE) # nocov
      }
      if (type != "NC_CHAR") value <- list(value)

      # Check if the name refers to an existing attribute
      if (nrow(private$.attributes) && nrow(private$.attributes[private$.attributes$name == name, ])) {
        # If so, replace its type and value
        private$.attributes[private$.attributes$name == name, ]$type <- type
        private$.attributes[private$.attributes$name == name, ]$length <- len
        private$.attributes[private$.attributes$name == name, ]$value <- value
      } else {
        # If not, create a new attribute
        if (!.is_valid_name(name))
          stop("Attribute name is not valid.", call. = FALSE) # nocov

        df <- data.frame(name = name, type = type, length = len)
        df$value <- value # Preserve lists
        private$.attributes <- rbind(private$.attributes, df)
      }
      private$.attributes_dirty <- TRUE
      invisible(self)
    },

    #' @description Test if the supplied attributes are identical to the
    #'   attributes of this instance. The order of the attributes may differ but
    #'   the names, types and values must coincide.
    #' @param cmp `data.frame` with attributes to compare to the attributes of
    #'   this instance.
    #' @return `TRUE` if attributes in argument `cmp` are identical to the
    #'   attributes of this instance, `FALSE` otherwise.
    attributes_identical = function(cmp) {
      atts <- self$attributes
      if (nrow(atts) == nrow(cmp)) {
        # Find matching order between attribute sets
        cmp_idx <- match(cmp$name, atts$name)
        if (any(is.na(cmp_idx)))
          return(FALSE)

        # All same type and length
        if (all(atts[cmp_idx, "type"] == cmp$type & atts[cmp_idx, "length"] == cmp$length))
          # All same values - consider vectorized data
          return(all(mapply(function(s, c) {
            all(if (is.double(s)) .near(s, c) else s == c)
          }, atts$value[cmp_idx], cmp$value)))
      }
      FALSE
    },

    #' @description Append the text value of an attribute. If an attribute
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
      if (is.na(name) || !is.character(name) || length(name) != 1L)
        stop("Must name one attribute to append values for.", call. = FALSE)
      if (is.na(name) || !is.character(name) || length(name) != 1L)
        stop("Value to append must be a single character string.", call. = FALSE)

      if (nchar(value) > 0L) {
        # Check if the name refers to an existing attribute
        if (nrow(private$.attributes[private$.attributes$name == name, ])) {
          new_val <- if (prepend)
            paste0(value, sep, private$.attributes[private$.attributes$name == name, ]$value)
          else
            paste0(private$.attributes[private$.attributes$name == name, ]$value, sep, value)
          private$.attributes[private$.attributes$name == name, ]$value <- new_val
          private$.attributes[private$.attributes$name == name, ]$length <- nchar(new_val)
        } else # else create a new attribute
          self$set_attribute(name, "NC_STRING", value)
      }

      private$.attributes_dirty <- TRUE
      invisible(self)
    },

    #' @description Delete attributes. If an attribute `name` is not present
    #' this method simply returns.
    #' @param name Vector of names of the attributes to delete.
    #' @return Self, invisibly.
    delete_attribute = function(name) {
      private$.attributes <- private$.attributes[!private$.attributes$name %in% name, ]
      private$.attributes_dirty <- TRUE
      invisible(self)
    },

    #' @description Write the attributes of this object to a netCDF file.
    #' @return Self, invisibly.
    write_attributes = function() {
      if (private$.attributes_dirty)
        if (inherits(private$.NCobj, "NCObject")) {
          nm <- if (inherits(self, "CFGroup")) "NC_GLOBAL" else self$name
          private$.NCobj$write_attributes(nm, private$.attributes)
          private$.attributes_dirty <- FALSE
        }
      invisible(self)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Generic CF object"
    },

    #' @field id (read-only) Retrieve the identifier of the CF object.
    id = function(value) {
      if (missing(value))
        private$.id
    },

    #' @field name Set or retrieve the name of the CF object. The name must be a
    #'   valid netCDF name: start with a character, use only characters, numbers
    #'   and the underscore, and be at most 255 characters long.
    name = function(value) {
      if (missing(value))
        private$.name
      else
        private$set_name(value)
    },

    #' @field fullname (read-only) The fully-qualified name of the CF object.
    fullname = function(value) {
      if (missing(value)) {
        grp <- self$group
        if (is.null(grp))
          private$.name
        else {
          gnm <- grp$fullname
          if (gnm == "/")
            paste0("/", private$.name)
          else
            paste(gnm, private$.name, sep = "/")
        }
      }
    },

    #' @field group Set or retrieve the [CFGroup] that this object is
    #'   located in, possibly `NULL`.
    group = function(value) {
      if (missing(value))
        private$.group
      else if (inherits(value, "CFGroup"))
        self$attach_to_group(value)
    },

    #' @field attributes (read-only) Retrieve a `data.frame` with the attributes
    #'   of the CF object.
    attributes = function(value) {
      if (missing(value))
        private$.attributes
    },

    #' @field has_resource (read-only) Flag that indicates if this object has an
    #'   underlying netCDF resource.
    has_resource = function(value) {
      !is.null(private$.NCobj)
    },

    #' @field NC (read-only) The NC object that links to an underlying netCDF
    #'   resource, or `NULL` if not linked.
    NC = function(value) {
      if (missing(value))
        private$.NCobj
    },

    #' @field is_dirty Flag to indicate if the object has any unsaved changes.
    is_dirty = function(value) {
      if (missing(value))
        private$.dirty
      else if (is.logical(value) && length(value) == 1L)
        private$.dirty <- value
      else
        stop("Must supply single logical value.", call. = FALSE)
    }
  )
)

#' @name dimnames
#' @title Names or axis values of an CF object
#'
#' @description Retrieve the variable or axis names of an `ncdfCF` object. The
#'   `names()` function gives the names of the variables in the data set,
#'   preceded by the path to the group if the resource uses groups. The return
#'   value of the `dimnames()` function differs depending on the type of object:
#' * `CFDataset`, `CFVariable`: The dimnames are returned as a vector of the
#'   names of the axes of the data set or variable, preceded with the path to
#'   the group if the resource uses groups. Note that this differs markedly from
#'   the `base::dimnames()` functionality.
#' * `CFAxisNumeric`, `CFAxisLongitude`, `CFAxisLatitude`, `CFAxisVertical`: The
#'   coordinate values along the axis as a numeric vector.
#' * `CFAxisTime`: The coordinate values along the axis as a
#'   character vector containing timestamps in ISO8601 format. This could be
#'   dates or date-times if time information is available in the axis.
#' * `CFAxisCharacter`: The coordinate values along the axis as
#'   a character vector.
#' * `CFAxisDiscrete`: The index values of the axis, either along the entire
#'   axis, or a portion thereof.
#'
#' @param x An `CFObject` whose axis names to retrieve. This could be
#'   `CFDataset`, `CFVariable`, or a class descending from `CFAxis`.
#'
#' @return A vector as described in the Description section.
#' @examples
#' fn <- system.file("extdata",
#'   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc",
#'   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#'
#' # Names of data variables
#' names(ds)
#'
#' # CFDataset
#' dimnames(ds)
#'
#' # CFVariable
#' pr <- ds[["pr"]]
#' dimnames(pr)
#'
#' # CFAxisNumeric
#' lon <- ds[["lon"]]
#' dimnames(lon)
#'
#' # CFAxisTime
#' t <- ds[["time"]]
#' dimnames(t)
NULL

