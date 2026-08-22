#' CF cell measure variable
#'
#' @description This class represents a CF cell measure variable, the object
#'   that indicates the area or volume of every grid cell in referencing data
#'   variables.
#'
#'   If a cell measure variable is external to the current file, an instance
#'   will still be created for it, but the user must link the external file to
#'   this instance before it can be used in analysis.
#'
#' @docType class
CFCellMeasure <- R6::R6Class("CFCellMeasure",
  private = list(
    # The data object for the class. This is an instance of CFVariable but it is
    # only present when the cell measure variable is internal to the file or
    # after an external file has been linked.
    .var = NULL,

    # The name of this object.
    .name = "",

    # The CFDataset from the external variable, if linked.
    .ext = NULL,

    # A list of the CFVariable instances linking to this instance.
    .links = list(),

    # A list of the axes that this cell measure variable uses, from the internal
    # variable or from an external file after it is linked.
    .axes = list(),

    # The measure of the variable, either "area" or "volume".
    .measure = "",

    # Get the names of the private$.links or private$.axes
    names_of = function(lst) {
      sapply(lst, function(el) el$name)
    },

    # This method checks that a CFVariable, v, has (a subset of) axes that are
    # compatible with this cell measure variable. If not, an error is thrown.
    compatible = function(v) {
      lapply(private$.axes, function(ax) {
        tst <- v$axes[[ax$name]]
        if (is.null(tst))
          stop("Incompatible sets of axes between data variable and cell measure variable.", call. = FALSE)
        if (ax$length != tst$length || !all(abs(ax$values - tst$values) < CF$eps))
          stop("Axis coordinates not identical between data variable and cell measure variable.", call. = FALSE)
      })
      invisible(self)
    }
  ),
  public = list(
    #' @description Create an instance of this class. The instance may be based
    #'   on a NC variable contained in the same resource as the referencing data
    #'   variable, or it may be external. If internal, the CF variable will be
    #'   created in the CF group that manages the NC group where the NC
    #'   variable is located.
    #' @param measure The measure of this object. Must be either of "area" or
    #'   "volume".
    #' @param name The name of the cell measure variable. Ignored if argument
    #'   `nc_var` is specified.
    #' @param nc_var The netCDF variable that defines this CF cell measure
    #'   object. `NULL` for an external variable.
    #' @param axes List of [CFAxis] instances that describe the dimensions of
    #'   the cell measure object. `NULL` for an external variable.
    #' @return An instance of this class.
    initialize = function(measure, name, nc_var = NULL, axes = NULL) {
      if (measure %in% c("area", "volume"))
        private$.measure <- measure
      else
        stop("Invalid 'measure' for cell measure variable.", call. = FALSE)

      if (!(is.null(nc_var) || is.null(axes))) {
        private$.var <- CFVariable$new(nc_var, group = nc_var$group$CF, axes = axes)
        private$.name <- nc_var$name
        private$.axes <- axes
      } else
        private$.name <- name
    },

    #' @description Print a summary of the cell measure variable to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    print = function(...) {
      cat("<Cell measure>", private$.name, "\n")
      cat("Measure  :", private$.measure, "\n")

      if (is.null(private$.var))
        cat("Data     : external (not linked)\n")
      else {
        if (!is.null(private$.ext))
          cat("Location :", private$.ext$uri, "\n")
        # else if (private$.var$group$name != "/")
        #   cat("Location :", private$.var$group$name, "\n")

        longname <- private$.var$attribute("long_name")
        if (!is.na(longname) && longname != private$.name)
          cat("Long name:", longname, "\n")

        if (length(private$.links))
          cat("Linked to:", private$names_of(private$.links), "\n")

        cat("\nAxes:\n")
        axes <- do.call(rbind, lapply(private$.var$axes, function(a) a$brief()))
        axes <- lapply(axes, function(c) if (all(c == "")) NULL else c)
        axes <- as.data.frame(axes[lengths(axes) > 0L])
        print(.slim.data.frame(axes, ...), right = FALSE, row.names = FALSE)

        private$.var$print_attributes(...)
      }
    },

    #' @description Retrieve the values of the cell measure variable.
    #' @return The values of the cell measure as a [CFVariable] instance.
    data = function() {
      private$.var
    },

    #' @description Register a [CFVariable] which is using this cell measure
    #'   variable. A check is performed on the compatibility between the data
    #'   variable and this cell measure variable.
    #' @param var A `CFVariable` instance to link to this instance.
    #' @return Self, invisibly.
    register = function(var) {
      private$compatible(var)
      private$.links <- append(private$.links, var)
      names(private$.links) <- private$names_of(private$.links)
    },

    #' @description Link the cell measure variable to an external netCDF
    #'   resource. The resource will be opened and the appropriate data variable
    #'   will be linked to this instance. If the axes or other properties of the
    #'   external resource are not compatible with this instance, an error will
    #'   be raised.
    #' @param resource The name of the netCDF resource to open, either a local
    #'   file name or a remote URI.
    #' @return Self, invisibly.
    link = function(resource) {
      ds <- open_ncdf(resource)
      if (inherits(ds, "CFDataset")) {
        var <- ds[[private$.name]]
        if (inherits(var, "CFVariable")) {
          private$.axes <- var$axes
          # FIXME: Is the below statement correct???
          lapply(private$.links, private$compatible) # May throw an error
          private$.ext <- ds
          private$.var <- var
          invisible(self)
        }
      } else
        stop("Invalid resource for cell measure variable.", call. = FALSE)
    },

    #' @description Detach the internal data variable from an underlying netCDF
    #' resource.
    #' @return Self, invisibly.
    detach = function() {
      if (is.null(private$.ext) && !is.null(private$.var))
        private$.var$detach()
      invisible(self)
    }
  ),
  active = list(
    #' @field measure (read-only) Retrieve the measure of this instance. Either
    #'   "area" or "volume".
    measure = function(value) {
      if (missing(value))
        private$.measure
    },

    #' @field name The name of this instance, which must refer to a NC variable
    #' or an external variable.
    name = function(value) {
      if (missing(value))
        private$.name
      else if (.is_valid_name(value))
        private$.name <- value # Should this be disallowed when .var is set?
      else
        stop("Invalid name for a CF object.", call. = FALSE) # nocov
    }
  )
)
