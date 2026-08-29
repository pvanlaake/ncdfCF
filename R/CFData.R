#' CF data object
#'
#' @description This class is a basic ancestor to all classes that contain data
#'   from a netCDF resource, specifically data variables and axes. More useful
#'   classes use this class as ancestor.
#'
#' @docType class
CFData <- R6::R6Class("CFData",
  inherit = CFObject,
  cloneable = FALSE,
  private = list(
    # The values of this object. This class does not interpret the values in
    # any way - that is the job of descendant classes.
    .values = NULL,

    # Integer vector of the dimensions of .values. It is set at initialization
    # on the basis of .values. This should include all dimensions of the owning
    # object, including degenerate ones. The owning object should set this
    # parameter with any degenerate dimensions.
    .dims = integer(0),

    # List of start and count vectors for reading data from file. The length of
    # the vectors must agree with the array on file or be `NA`.
    .NC_map = list(),

    # The NC data type of the data in the object. Taken from .NCobj if set,
    # otherwise the descending class must set it explicitly when receiving its
    # data values.
    .data_type = "NC_NAT", # Not a type

    # Flag to indicate if the data on disk is too large for memory.
    .data_oversized = FALSE,

    # Flag to indicate if the data has edits
    .data_dirty = FALSE,

    # Set a new name for the CF object. Cascade to the underlying netCDF
    # resource. This method is here because all descending classes relate to a
    # NC variable.
    set_name = function(new_name) {
      if (.is_valid_name(new_name)) {
        if (is.null(private$.group$find_by_name(new_name))) { # FIXME: Make this a FQN?
          private$.name <- if (!is.null(private$.NCobj)) {
            private$.NCobj$set_name(new_name)
            private$.NCobj$name # new_name may not have been written
          } else
            new_name
        }
      }
      invisible(self)
    },

    # Set the dimensions of the data in this object. The product of `new_dims`
    # must equal the actual .dims. This method is really only useful to add
    # length-1 dimensions, such as a scalar axis, to the current dimensions.
    set_dims = function(new_dims) {
      if (prod(private$.dims) == prod(new_dims)) {
        names(new_dims) <- NULL
        private$.dims <- new_dims
        if (!is.null(private$.values))
          dim(private$.values) <- private$.dims
      } else
        stop("New dimensions do not agree with existing data dimensions.", call. = FALSE)
    },

    # Sanitize the start and count values. Called during initialization and by
    # read_chunk()/read_window(). NAs are converted to numbers and values have
    # to agree with .dims. Returns the sanitized start and count vectors as a
    # list.
    check_start_count = function(start, count) {
      d <- private$.dims
      len <- length(d)
      if (!len || any(d == 0L)) return(list())          # When the object does not have any data

      if (length(start) == 1L && is.na(start))
        start <- rep(1L, len)
      else if (length(start) == len) {
        start[is.na(start)] <- 1L
        if (any(start > d))
          stop("Start values cannot be larger than the dimensions of the data", call. = FALSE) # nocov
      } else
        stop("`start` vector is not the length of the object dimensions", call. = FALSE)

      if (length(count) == 1L && is.na(count))
        count <- d - start + 1L
      else if (length(count) == len) {
        ndx <- which(is.na(count))
        count[ndx] <- d[ndx] - start[ndx] + 1L
        if (any(count > d - start + 1L))
          stop("Count values cannot extend beyond the dimensions of the data", call. = FALSE) # nocov
      } else
        stop("`count` vector is not the length of the object dimensions", call. = FALSE)

      list(start = start, count = count)
    },

    # Translate local (validated, .dims-relative) start/count into the
    # file-absolute (NC-space) indices NCobj$get_data()/write_data()
    # require, applying this object's .NC_map offset. Only meaningful when
    # .NC_map is non-empty; callers with an empty .NC_map are already in
    # NC-space (nothing to translate) and must not call this.
    to_nc_indices = function(local_start, local_count) {
      len <- length(private$.NC_map$start)
      list(start = private$.NC_map$start + local_start[seq_len(len)] - 1L,
           count = local_count[seq_len(len)])
    },

    # Warn if reading `count` elements at the object's current data type
    # would allocate more than CF.options$memory_cell_limit bytes. For
    # packed data, RNetCDF's unpack=TRUE typically widens to double
    # regardless of the on-disk (packed) type -- fitnum may narrow it back
    # down afterwards, but that's not knowable in advance, so packed
    # variables are sized conservatively at 8 bytes/element here. Returns
    # the estimated byte count, invisibly, or NA if the type is unknown.
    check_memory_limit = function(count) {
      itemsize <- if (!is.null(private$.NCobj) && private$.NCobj$is_packed) 8L
      else .nc_type_size(private$.data_type)
      if (is.na(itemsize)) return(invisible(NA_real_))

      bytes <- prod(count) * itemsize
      if (bytes > CF.options$memory_cell_limit)
        warning(sprintf(
          "Reading %s elements will allocate approximately %s, exceeding the memory limit (%s). Consider reading a smaller extent, or raise the limit if you have the memory to spare",
          paste(count, collapse = "x"), .format_bytes(bytes), .format_bytes(CF.options$memory_cell_limit)),
          call. = FALSE)
      invisible(bytes)
    },

    # Core chunk-planned read + reassembly for resolved start/count,
    # in whatever coordinate space the caller has established is correct for
    # them (file-relative for a .NC_map read, local for a validated one). No
    # NA resolution, no bounds-checking against .dims -- that's the caller's
    # job, done once before calling this.
    read_window_core = function(start, count, reader) {
      bytes <- private$check_memory_limit(count)

      if (!is.na(bytes) && bytes <= CF.options$memory_cell_limit)
        return(reader(start, count))  # fits outright: skip .chunk_plan() entirely

      chunks <- if (!is.null(private$.NCobj)) private$.NCobj$netcdf4$chunksizes else NULL
      itemsize <- if (!is.null(private$.NCobj) && private$.NCobj$is_packed) 8L
      else (.nc_type_size(private$.data_type) %||% 8L)

      plan <- .chunk_plan(count, chunks, start, count, itemsize, CF.options$memory_cell_limit)
      if (length(plan) == 1L)
        return(reader(plan[[1L]]$start, plan[[1L]]$count))

      out <- NULL
      for (p in plan) {
        block <- reader(p$start, p$count)
        if (is.null(out)) out <- array(vector(storage.mode(block), prod(count)), dim = count)
        idx <- lapply(seq_along(count), function(d) {
          off <- p$start[d] - start[d]
          seq.int(off + 1L, off + p$count[d])
        })
        out <- do.call(`[<-`, c(list(out), idx, list(value = block)))
      }
      out
    },

    # Set the values of the object. Perform some basic checks when set programmatically.
    # Values may be NULL
    set_values = function(values) {
      dtype <- storage.mode(values)

      # Check if we can find a vtype from the NCvar, possibly packed
      if (!is.null(private$.NCobj)) {
        private$.data_type <- private$.NCobj$attribute("scale_factor", "type")
        if (is.na(private$.data_type))
          private$.data_type <- private$.NCobj$attribute("add_offset", "type")
        if (is.na(private$.data_type))
          private$.data_type <- private$.NCobj$vtype
        else
          # Data is packed in the netCDF file: throw away the attributes and let
          # RNetCDF deal with unpacking when reading the data using the
          # attributes in the NCVariable.
          self$delete_attribute(c("scale_factor", "add_offset", "valid_range", "valid_min", "valid_max"))
      } else if (!is.null(values)) {
        private$.data_type <- if (dtype == "double") {
          # If the data is numeric, check attributes to select between NC_DOUBLE and NC_FLOAT
          if (!is.na(dt <- self$attribute("_FillValue", "type"))) dt
          else if (!is.na(dt <- self$attribute("missing_value", "type"))) dt
          else "NC_DOUBLE"
        } else .nc_type(dtype)
      } else
        private$.data_type <- "NC_NAT"

      if (!is.null(values) && !.compatible_type(dtype, private$.data_type)) {
        stop("Bad data type of values for this object.", call. = FALSE)
      }

      # Set the actual_range attribute for the values
      if (is.null(values))
        self$delete_attribute("actual_range")
      else if (prod(dim(values)) * (.nc_type_size(private$.data_type) %||% 8L) <= CF.options$memory_cell_limit) {
        rng <- suppressWarnings(range(values, na.rm = TRUE))
        if (is.infinite(rng[1L]) || is.na(rng[1L]))
          self$delete_attribute("actual_range")
        else {
          if (is.numeric(rng))
            rng <- round(rng, CF.options$digits)
          self$set_attribute("actual_range", private$.data_type, rng)
        }
      }

      if (!is.null(values) && self$ndims > 1L) {
        if (private$.data_type == "NC_CHAR" && inherits(self, c("CFAxis", "CFLabel")))
          dim(values) <- private$.dims[-1] # First dimension is string length
        else
          dim(values) <- private$.dims
      }
      private$.values <- values
    },

    # Write a data array to a netCDF file.
    # dt : Data array to write, optional
    # @param start Vector of indices where to start reading data along the
    #   dimensions of the array. The vector must be `NA` to read all data,
    #   otherwise it must have agree with the dimensions of the array.
    # @param count Vector of number of elements to read along each dimension of
    #   the array. The vector must be `NA` to read to the end of each dimension,
    #   otherwise its value must agree with the corresponding `start` value and
    #   the dimension of the array.
    # ...: Additional parameters for RNetCDF::var.put.nc(), like pack and na.mode
    # Returns self, invisibly.
    write_data = function(dt = private$.values, start = NA, count = NA, ...) {
      if (private$.data_dirty) {
        if (length(private$.NC_map)) {
          # .NC_map always refers to the initial dimensions, so the arguments
          # are trimmed to that length (noting that there may be "scalar" axes
          # in a variable backed by a netCDF resource).
          sc <- private$check_start_count(start, count)
          nc <- private$to_nc_indices(sc$start, sc$count)
          private$.NCobj$write_data(d = dt, start = nc$start, count = nc$count, ...)
        } else {
          # .NC_map is an empty list for private$.values being a complete array.
          private$.NCobj$write_data(d = dt, start = NA, count = NA, ...)
        }
        private$.data_dirty <- FALSE
      }
      invisible(self)
    }
  ),
  public = list(
    #' @description Create a new `CFData` instance. This method is called upon
    #'   creating CF objects, such as when opening a netCDF resource or creating
    #'   a new CF object. It is rarely, if ever, useful to call this constructor
    #'   directly. Instead, use the methods from higher-level classes such as
    #'   [CFVariable].
    #' @param obj The [NCVariable] instance upon which this CF object is based
    #'   when read from a netCDF resource, or the name for the new CF object to
    #'   be created.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the object in an array. Ignored
    #'   when argument `obj` is an `NCVariable` instance.
    #' @param start Optional. Vector of indices where to start reading data
    #'   along the dimensions of the array on file. The vector must be `NA` to
    #'   read all data, otherwise it must have agree with the dimensions of the
    #'   array on file. Default value is `1`, i.e. start from the beginning of
    #'   the 1-D NC variable. Ignored when argument `obj` is not an `NCVariable`
    #'   instance.
    #' @param count Optional. Vector of number of elements to read along each
    #'   dimension of the array on file. The vector must be `NA` to read to the
    #'   end of each dimension, otherwise its value must agree with the
    #'   corresponding `start` value and the dimension of the array on file.
    #'   Default is `NA`. Ignored when argument `obj` is not an `NCVariable`
    #'   instance.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   object.
    #' @return A `CFData` instance.
    initialize = function(obj, group, values, start = 1L, count = NA, attributes = data.frame()) {
      super$initialize(obj, attributes, group = group)
      if (inherits(obj, "NCVariable")) {
        # Set the initial .NC_map to cover the entire NC variable
        if ((nd <- obj$ndims) > 0L) {
          private$.dims <- obj$dim()
          private$.NC_map <- list(start = rep(1L, nd), count = private$.dims)
        }
        # Subset to a smaller dimension space, if needed
        private$.NC_map <- private$check_start_count(start, count)
        private$.dims <- private$.NC_map$count
      } else
        private$.data_dirty <- TRUE

      if (missing(values) || is.null(values) || (length(values) == 1L && is.na(values)))
        values <- NULL
      else
        private$.dims <- dim(values) %||% length(values)
      private$set_values(values)
    },

    #' @description Detach the current object from its underlying netCDF
    #'   resource. If necessary, data is read from the resource before
    #'   detaching.
    detach = function() {
      if (!is.null(private$.NCobj) && is.null(private$.values))
        self$read_data()
      private$.NC_map <- list()
      private$.data_dirty <- TRUE
      super$detach()
    },

    #' @description Retrieve the dimensions of the data of this object.
    #' @param dimension Optional. The index of the dimension to retrieve the
    #'   length for. If omitted, retrieve the lengths of all dimensions.
    #' @return Integer vector with the length of each requested dimension.
    dim = function(dimension) {
      if (missing(dimension))
        private$.dims
      else
        private$.dims[dimension]
    },

    #' Read the data of the CF object from the NC file. The data is cached by
    #' `self` so repeated calls do not access the netCDF resource, unless
    #' argument `refresh` is `TRUE`. This method will not assess how big the
    #' data is before reading it so there is a chance that memory will be
    #' exhausted. The calling code should check for this possibility and break
    #' up the reading of data into chunks using `read_chunk()` or
    #' `read_window()` - these methods will not cache the data, however.
    #' @param refresh Should the data be read from file if the object is linked?
    #'   This will replace current values, if previously loaded. Default
    #'   `FALSE`.
    #' @return An array of data, invisibly, as prescribed by the `start` and
    #'   `count` values used to create this object. If the object is not backed
    #'   by a netCDF resource, returns `NULL`.
    read_data = function(refresh = FALSE) {
      if ((!is.null(private$.NCobj)) && (is.null(private$.values) || refresh)) {
        if (!length(private$.NC_map))
          # No .NC_map: local space and NC-space coincide, so a full-extent read
          # against .dims is valid: read directly.
          private$set_values(
            private$read_window_core(rep(1L, length(private$.dims)), private$.dims,
                                     private$.NCobj$get_data))
        else
          # .NC_map is in NC-space: read directly via NCobj$get_data().
          private$set_values(
            private$read_window_core(private$.NC_map$start, private$.NC_map$count,
                                     private$.NCobj$get_data))
      }
      invisible(private$.values)
    },

    #' Read a chunk of raw data of the CF object, as defined by the `start` and
    #' `count` vectors. Note that these vectors are relative to any subset of
    #' the data variable that this CF object refers to. The data read by this
    #' method will not be stored in `self` so the calling code must take a
    #' reference to it. If the chunk is (potentially) large, use `read_window()`
    #' for additional safeguards against memory exhaustion.
    #' @param start Vector of indices where to start reading data along the
    #'   dimensions of the array. The vector must be `NA` to read all data,
    #'   otherwise it must agree with the dimensions of the array.
    #' @param count Vector of number of elements to read along each dimension of
    #'   the array. The vector must be `NA` to read to the end of each
    #'   dimension, otherwise its value must agree with the corresponding
    #'   `start` value and the dimension of the array.
    #' @return An array of data, as prescribed by the `start` and `count`
    #'   arguments, or `NULL` if there is no data.
    read_chunk = function(start, count) {
      sc <- private$check_start_count(start, count)
      if (!length(sc)) return (NULL)

      if (!is.null(private$.values)) {
        cll <- paste0("private$.values[", paste(sc$start, ":", sc$start + sc$count - 1L, sep = "", collapse = ", "), "]")
        eval(parse(text = cll))
      } else {
        # Read from the netCDF resource: translate validated LOCAL start/count
        # to NC-space via this object's .NC_map offset, then read directly.
        nc <- private$to_nc_indices(sc$start, sc$count)
        private$.NCobj$get_data(nc$start, nc$count)
      }
    },

    #' @description Read the array for `(start, count)`, transparently splitting
    #'   the request into budget-bounded, chunk-aligned sub-reads when the
    #'   window is large, and reassembling into one array via indexed
    #'   assignment. This materializes the full `(start, count)` window: it
    #'   bounds each individual read, and warns if the reassembled whole exceeds
    #'   `CF.options$memory_cell_limit`, but does not itself reduce memory below
    #'   the size of that window. Use this in preference to `read_chunk()` for
    #'   any read that might be large.
    #' @param start,count As for `read_chunk()`.
    #' @return An array, as `read_chunk()` would return.
    read_window = function(start, count) {
      sc <- private$check_start_count(start, count)
      if (!length(sc)) return(NULL)
      private$read_window_core(sc$start, sc$count, self$read_chunk)
    }
  ),
  active = list(
    #' @field data_type Set or retrieve the data type of the data in the object.
    #'   Setting the data type to a wrong value can have unpredictable and
    #'   mostly catastrophic consequences.
    data_type = function(value) {
      if (missing(value))
        private$.data_type
      else if (self$has_resource)
        stop("Cannot set the data type of a variable present on file.", call. = FALSE) # nocov
      else if (value %in% netcdf_data_types)
        private$.data_type <- value
      else
        stop("Unrecognized data type for a netCDF variable.", call. = FALSE) # nocov
    },

    #' @field ndims (read-only) Retrieve the dimensionality of the data in the
    #'   array.
    ndims = function(value) {
      if (missing(value))
        length(private$.dims)
    },

    #' @field NC_map Returns a list with columns "start" and "count" giving the
    #'   indices for reading the data of this object from a netCDF resource. The
    #'   list is empty if this object is not backed by a netCDF resource.
    NC_map = function(value) {
      if (missing(value))
        private$.NC_map
    }
  )
)
