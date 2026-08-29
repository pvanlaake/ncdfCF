#' CF data variable
#'
#' @description This class represents a CF data variable, the object that
#'   provides access to an array of data.
#'
#'   The CF data variable instance provides access to all the details that have
#'   been associated with the data variable, such as axis information, grid
#'   mapping parameters, etc.
#'
#' @export
#' @docType class
CFVariable <- R6::R6Class("CFVariable",
  inherit = CFData,
  cloneable = FALSE,
  private = list(
    # A list with the axes of the variable.
    .axes = list(),

    # Auxiliary coordinates reference, if the data variable uses them.
    .llgrid = NULL,

    # List of ancillary variables associated with this data variable.
    .ancillary = list(),

    # The CFGridMapping object for the variable, if set.
    .crs = NULL,

    # A list of cell measure objects, if the variable has cell measures.
    .cell_measures = list(),

    # Return the R order of axes that "receive special treatment".
    YXZT = function() {
      orient <- sapply(private$.axes, function(x) x$orientation)
      match(c("Y", "X", "Z", "T"), orient, nomatch = 0L)
    },

    # Return the CF canonical order of axes that "receive special treatment".
    XYZT = function() {
      orient <- sapply(private$.axes, function(x)  x$orientation)
      match(c("X", "Y", "Z", "T"), orient, nomatch = 0L)
    },

    # Check that names passed as arguments to $subset() and $profile() are
    # valid. This means that they must refer to an axis by name or orientation
    # and there can be no duplication. It returns an integer vector with the
    # order in which the axes are specified.
    check_names = function(nm) {
      axis_names <- names(private$.axes)
      is_axis <- match(nm, axis_names)
      if (anyDuplicated(is_axis, incomparables = NA))
        stop("Duplicated axis names not allowed", call. = FALSE)
      if (!any(is.na(is_axis)))
        return(is_axis)

      orientations <- sapply(private$.axes, function(a) a$orientation)
      is_orient <- match(nm, orientations)
      if (anyDuplicated(is_orient, incomparables = NA))
        stop("Duplicated axis orientations not allowed", call. = FALSE)
      if (!any(is.na(is_orient)))
        return(is_orient)

      ax_na <- which(is.na(is_axis))
      is_axis[ax_na] <- is_orient[ax_na]
      if (!any(is.na(is_axis)))
        return(is_axis)

      if (!is.null(private$.llgrid)) {
        is_aux <- match(nm, private$.llgrid$grid_names)
        if (anyDuplicated(is_aux, incomparables = NA))
          stop("Duplicated auxiliary axis names not allowed", call. = FALSE)
        if (!all(is.na(is_aux)) && sum(is_aux > 0L, na.rm = TRUE) != 2L)
          stop("Must select both auxiliary grid axes or none.", call. = FALSE)
        if (!any(is.na(is_aux)))
          return(is_aux)

        ax_na <- which(is.na(is_axis))
        is_axis[ax_na] <- is_aux[ax_na]
      }

      # FIXME: is_aux and is_axis look at different sets of names so can't be compared
      #if (anyDuplicated(is_axis, incomparables = NA))
      #  stop("Duplicated axis names and orientations not allowed", call. = FALSE)
      if (any(is.na(is_axis)))
        stop("Arguments contain names not corresponding to an axis", call. = FALSE)

      is_axis
    },

    # Orient data values in such a way that it conforms to regular R arrays:
    # axis order will be Y-X-Z-T-others and Y values will go from the top to the
    # bottom. Alternatively, order data values in the CF canonical order.
    # Argument data is the array to order, argument ordering must be "R" or
    # "CF". Returns a new array with an attribute "axes" that lists
    # axis names in the order of the new array.
    orient = function(data, ordering = "R") {
      dim_names <- names(private$.axes)[seq_along(dim(data))]

      if (ordering == "R")
        order <- private$YXZT()
      else if (ordering == "CF")
        order <- private$XYZT()
      else
        stop("Invalid argument for ordering.", call. = FALSE)

      if (sum(order) == 0L) {
        # Cannot orient data array because axis orientation has not been set
        attr(data, "axes") <- dim_names
        return(data)
      }
      if (all(diff(order[which(order > 0L)]) > 0L)) {
        attr(data, "axes") <- dim_names
      } else {
        all_dims <- seq(length(dim(data)))
        perm <- c(order[which(order > 0L)], all_dims[!(all_dims %in% order)])
        data <- aperm(data, perm)
        attr(data, "axes") <- dim_names[perm]
      }

      if (ordering == "R") {
        # Flip Y-axis, if necessary
        ynames <- dimnames(data)[[1L]]
        if (length(ynames) > 1L && as.numeric(ynames[2L]) > as.numeric(ynames[1L])) {
          dn <- dimnames(data)
          dims <- dim(data)
          dim(data) <- c(dims[1L], prod(dims[-1L]))
          data <- apply(data, 2L, rev)
          dim(data) <- dims
          dn[[1L]] <- rev(dn[[1L]])
          dimnames(data) <- dn
        }
      }

      data
    },

    # Do the auxiliary grid interpolation. Argument "subset" is passed from the
    # `subset()` method. Argument "ll_names" give the auxiliary longitude and
    # latitude names and possibly the resolution. Return a list of useful
    # objects to `subset()`.
    auxiliary_interpolation = function(subset, ll_names, res) {
      # This code assumes that the grid orientation of the data variable is the
      # same as that of the longitude-latitude grid
      ext <- private$.llgrid$extent
      sel_names <- names(subset)
      Xrng <- if (ll_names[1L] %in% sel_names && !is.na(subset[[ ll_names[1L] ]][1L]))
                range(subset[[ ll_names[1L] ]])
              else ext[1L:2L]
      Yrng <- if (ll_names[2L] %in% sel_names && !is.na(subset[[ ll_names[2L] ]][1L]))
                range(subset[[ ll_names[2L] ]])
              else ext[3L:4L]
      if (is.null(res))
        private$.llgrid$aoi <-  aoi(Xrng[1L], Xrng[2L], Yrng[1L], Yrng[2L])
      else {
        if (length(res) == 1L) res <- c(res, res)
        private$.llgrid$aoi <-  aoi(Xrng[1L], Xrng[2L], Yrng[1L], Yrng[2L], res[1L], res[2L])
      }

      index <- private$.llgrid$grid_index()
      dim_index <- dim(index)

      # The below appears counter-intuitive (XY relationship to indices) but it
      # works for long-lat grids that use the recommended X-Y-Z-T axis ordering.
      # Report any problems to https://github.com/R-CF/ncdfCF/issues
      dim_ll <- private$.llgrid$dim
      xyidx <- arrayInd(index, dim_ll)          # convert indices to row,column
      rx <- range(xyidx[, 2L], na.rm = TRUE)    # full range of columns
      xyidx[, 2L] <- xyidx[, 2L] - rx[1L] + 1L  # reduce columns to 1-based
      cols <- rx[2L] - rx[1L] + 1L              # no of columns in reduced grid
      ry <- range(xyidx[, 1L], na.rm = TRUE)    # full range of rows
      xyidx[, 1L] <- xyidx[, 1L] - ry[1L] + 1L  # reduce rows to 1-based
      rows <- ry[2L] - ry[1L] + 1L              # no of rows in reduced grid
      index <- rows * (xyidx[, 2L] - 1L) + xyidx[, 1L] # reduced index value

      # index = the index values into the reduced grid
      # X,Y = start and count values for data to read
      # aoi = the AOI that was used to index
      # box = the dim of the original index
      list(index = index, X = c(ry[1L], rows), Y = c(rx[1L], cols), aoi = private$.llgrid$aoi, box = dim_index)
    },

    # === Reducer functions === These functions implement base functions sum,
    # mean, min, max, range over chunks of data such that they can be applied
    # over variables whose data exceeds available memory. The reducer functions
    # are used by process_level().
    .reducer_sum = list(
      init = function(shape) array(0, dim = shape),
      update = function(acc, block, tdim, na_rm)
        acc + .process.data(block, tdim, FUN = sum, na.rm = na_rm)[[1L]],
      finalize = function(acc, na_rm) list(acc)
    ),

    .reducer_mean = list(
      init = function(shape) list(sum = array(0, dim = shape), n = array(0, dim = shape)),
      update = function(acc, block, tdim, na_rm) {
        list(sum = acc$sum + .process.data(block, tdim, FUN = sum, na.rm = na_rm)[[1L]],
             n   = acc$n   + .process.data(block, tdim, FUN = function(x, ...)
               if (na_rm) sum(!is.na(x)) else length(x))[[1L]])
      },
      finalize = function(acc, na_rm) list(acc$sum / acc$n)
    ),

    # min/max/range: per-block partials come from min()/max() themselves, which
    # already turn an all-NA block-at-location into Inf/-Inf (with a warning)
    # under na.rm = TRUE -- that warning is suppressed per block and re-issued
    # exactly once at finalize(), conditioned on the FINAL accumulator, matching
    # base R's own single warning for a whole-vector call.
    .reducer_min = list(
      init = function(shape) array(Inf, dim = shape),
      update = function(acc, block, tdim, na_rm)
        pmin(acc, suppressWarnings(.process.data(block, tdim, FUN = min, na.rm = na_rm)[[1L]]), na.rm = na_rm),
      finalize = function(acc, na_rm) {
        if (na_rm && any(is.infinite(acc) & acc > 0))
          warning("no non-missing arguments to min; returning Inf", call. = FALSE)
        list(acc)
      }
    ),

    .reducer_max = list(
      init = function(shape) array(-Inf, dim = shape),
      update = function(acc, block, tdim, na_rm)
        pmax(acc, suppressWarnings(.process.data(block, tdim, FUN = max, na.rm = na_rm)[[1L]]), na.rm = na_rm),
      finalize = function(acc, na_rm) {
        if (na_rm && any(is.infinite(acc) & acc < 0))
          warning("no non-missing arguments to max; returning -Inf", call. = FALSE)
        list(acc)
      }
    ),

    .reducer_range = list(
      init = function(shape) list(min = array(Inf, dim = shape), max = array(-Inf, dim = shape)),
      update = function(acc, block, tdim, na_rm) {
        list(min = pmin(acc$min, suppressWarnings(.process.data(block, tdim, FUN = min, na.rm = na_rm)[[1L]]), na.rm = na_rm),
             max = pmax(acc$max, suppressWarnings(.process.data(block, tdim, FUN = max, na.rm = na_rm)[[1L]]), na.rm = na_rm))
      },
      finalize = function(acc, na_rm) {
        if (na_rm) {
          if (any(is.infinite(acc$min) & acc$min > 0))
            warning("no non-missing arguments to min; returning Inf", call. = FALSE)
          if (any(is.infinite(acc$max) & acc$max < 0))
            warning("no non-missing arguments to max; returning -Inf", call. = FALSE)
        }
        list(acc$min, acc$max)  # matches .process.data()'s asplit() order exactly
      }
    ),

    # Match by function identity, not name -- a user's own function called
    # "mean" is never silently intercepted. mean's sum/count decomposition
    # is only valid for trim = 0 (the default); a trimmed mean isn't
    # linearly decomposable across blocks, so that case falls through to
    # the materialized path instead.
    find_reducer = function(fun, dots) {
      if (identical(fun, base::sum)) return(private$.reducer_sum)
      if (identical(fun, base::mean) && (is.null(dots$trim) || dots$trim == 0))
        return(private$.reducer_mean)
      if (identical(fun, base::min)) return(private$.reducer_min)
      if (identical(fun, base::max)) return(private$.reducer_max)
      if (identical(fun, base::range) && !isTRUE(dots$finite)) return(private$.reducer_range)
      NULL
    },

    # Plan blocks for streaming that vary only along a time dimension, at the
    # full requested extent on every other dimension so every block's
    # per-location reduction lines up with the same accumulator locations and
    # can be merged with plain element-wise arithmetic. Deliberately not
    # .chunk_plan(): that planner is free to also split the other dimensions to
    # hit budget, which breaks a location-keyed accumulator (blocks would cover
    # different, non-overlapping spatial regions rather than more time at the
    # same locations).
    plan_tdim_only = function(start, count, tdim, tdim_native, itemsize, budget) {
      other_elems <- prod(as.numeric(count[-tdim]))
      max_mult <- max(1L, floor(budget / (itemsize * other_elems * tdim_native)))
      block_tdim <- min(max_mult * tdim_native, count[tdim])

      tstart <- seq(start[tdim], start[tdim] + count[tdim] - 1L, by = block_tdim)
      lapply(tstart, function(s) {
        st <- start; st[tdim] <- s
        ct <- count; ct[tdim] <- min(block_tdim, start[tdim] + count[tdim] - s)
        list(start = st, count = ct)
      })
    },

    # Compute one factor level's contribution from one or more contiguous
    # tdim runs (already split at disparate-index boundaries by the caller).
    # Streams via .chunk_plan() when the level exceeds budget and `fun` has
    # a registered reducer; otherwise materializes and reduces as before.
    process_level = function(runs, tdim, num_dims, fun, ...) {
      runs <- lapply(runs, function(r) {
        sc <- private$check_start_count(r$start, r$count)
        list(start = sc$start, count = sc$count)
      })

      itemsize <- .nc_type_size(self$data_type) %||% 8L
      total_elems <- sum(sapply(runs, function(r) prod(r$count)))

      materialize <- function() {
        if (length(runs) == 1L)
          self$read_window(runs[[1L]]$start, runs[[1L]]$count)
        else
          abind::abind(lapply(runs, function(r) self$read_window(r$start, r$count)), along = num_dims)
      }

      limit <- CF.options$memory_cell_limit
      if (total_elems * itemsize <= limit)
        return(.process.data(materialize(), tdim, FUN = fun, ...))

      dots <- list(...)
      reducer <- private$find_reducer(fun, dots)
      chunks <- if (!is.null(private$.NCobj)) private$.NCobj$netcdf4$chunksizes else NULL
      tdim_native <- if (!is.null(chunks)) chunks[tdim] else 1L
      feasible <- !is.null(reducer) && all(sapply(runs, function(r)
        prod(as.numeric(r$count[-tdim])) * tdim_native * itemsize <= limit))
      if (feasible) {
        na_rm <- isTRUE(dots$na.rm)
        acc <- NULL
        for (r in runs) {
          plan <- private$plan_tdim_only(r$start, r$count, tdim, tdim_native, itemsize, limit)
          for (p in plan) {
            block <- self$read_chunk(p$start, p$count)
            if (is.null(acc)) {
              bd <- dim(block)
              acc <- reducer$init(if (is.null(bd)) 1L else bd[-tdim])
            }
            acc <- reducer$update(acc, block, tdim, na_rm)
          }
        }
        return(reducer$finalize(acc, na_rm))
      }

      .process.data(materialize(), tdim, FUN = fun, ...)
    },

    # Internal apply/tapply method for this class. If the size of the data
    # variable is below a certain threshold, read the data and process in one
    # go. Otherwise processing goes per factor level. In other words, for each
    # factor level the data is read from file, to which the function is applied.
    # This is usually applied over the temporal domain but could be others
    # as well (untested).
    process_data = function(tdim, fac, fun, ...) {
      if (!is.null(private$.values))
        return(.process.data(self$values, tdim, fac, fun, ...))
      itemsize <- .nc_type_size(self$data_type) %||% 8L
      if (prod(sapply(private$.axes, function(x) x$length)) * itemsize < CF.options$memory_cell_limit)
        # Read the whole data array because size is manageable
        return(.process.data(self$read_data(), tdim, fac, fun, ...))

      # If data variable is too large, go by individual factor levels
      num_dims <- self$ndims
      start <- rep(1L, num_dims)
      count <- rep(NA_integer_, num_dims)

      lvls <- nlevels(fac)
      d <- vector("list", lvls)
      ndx <- as.integer(fac)
      nm <- self$name
      for (l in 1L:lvls) {
        indices <- which(ndx == l)
        dff <- diff(indices)
        if (all(dff == 1L)) {
          rng <- range(indices)
          st <- start; st[tdim] <- rng[1L]
          ct <- count; ct[tdim] <- rng[2L] - rng[1L] + 1L
          runs <- list(list(start = st, count = ct))
        } else {
          cutoffs <- c(0L, which(c(dff, 2L) > 1L))
          runs <- lapply(2L:length(cutoffs), function(i) {
            st <- start; st[tdim] <- indices[cutoffs[i - 1L] + 1L]
            ct <- count; ct[tdim] <- cutoffs[i] - cutoffs[i - 1L]
            list(start = st, count = ct)
          })
        }
        d[[l]] <- private$process_level(runs, tdim, num_dims, fun, ...)
        # d is a list with lvls elements, each element a list with elements for
        # the number of function results, possibly 1; each element having an
        # array of dimensions from private$values that are not tdim.
      }
      res_dim <- dim(d[[1L]][[1L]])
      tdim_len <- length(d)
      if (tdim_len > 1L) {
        dims <- c(res_dim,  tdim_len)
        perm <- c(num_dims, 1L:(num_dims - 1L))
      } else
        dims <- res_dim

      fun_len <- length(d[[1L]])
      out <- if (fun_len > 1L) {
        # Multiple function result values so get all arrays for every result
        # value and unlist those
        lapply(1:fun_len, function(r) {
            x <- unlist(lapply(d, function(lvl) lvl[[r]]), recursive = FALSE, use.names = FALSE)
            dim(x) <- dims
            if (tdim_len > 1L)
              aperm(x, perm)
            else x
          })
      } else {
        # Single function result so unlist
        d <- unlist(d, recursive = TRUE, use.names = FALSE)
        dim(d) <- dims
        list(if (tdim_len > 1L) aperm(d, perm) else d)
      }
    }
  ),
  public = list(
    #' @description Create an instance of this class.
    #' @param var The [NCVariable] instance upon which this CF variable is based
    #'   when read from a netCDF resource, or the name for the new CF variable
    #'   to be created.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param axes List of instances of [CFAxis] to use with this variable.
    #' @param values Optional. The values of the variable in an array.
    #' @param start Optional. Vector of indices where to start reading data
    #'   along the dimensions of the NC variable on file. The vector must be
    #'   `NA` to read all data, otherwise it must have agree with the dimensions
    #'   of the NC variable. Ignored when argument `var` is not an `NCVariable`
    #'   instance.
    #' @param count Optional. Vector of number of elements to read along each
    #'   dimension of the NC variable on file. The vector must be `NA` to read
    #'   to the end of each dimension, otherwise its value must agree with the
    #'   corresponding `start` value and the dimension of the NC variable.
    #'   Ignored when argument `var` is not an `NCVariable` instance.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   object. When argument `var` is an `NCVariable` instance and this
    #'   argument is an empty `data.frame` (default), arguments will be read
    #'   from the netCDF resource.
    #' @return A `CFVariable` instance.
    initialize = function(var, group, axes, values = values, start = NA, count = NA, attributes = data.frame()) {
      super$initialize(var, group, values = values, start = start, count = count, attributes = attributes)

      # Axes - If they do not agree with the .dims parameter (from CFData) then
      # adjust as appropriate. In general this is only necessary when axes are
      # modified as part of a data-transformation operation and become length-1.
      # The below code is simple but should always work - presumably...
      private$.axes <- axes
      ax_dims <- sapply(axes, function(ax) ax$length)
      if (length(ax_dims) > self$ndims) {
        private$set_dims(ax_dims)
      }

      # Delete useless attributes
      self$delete_attribute(c("_FillValue", "missing_value"))
    },

    #' @description Print a summary of the data variable to the console.
    #' @param ... Arguments passed on to other functions. Of particular interest
    #' is `width = ` to indicate a maximum width of attribute columns.
    print = function(...) {
      cat("<Variable>", self$name, "\n")

      if (!is.null(ds <- self$group$data_set) && ds$has_subgroups())
        cat("Path name:", self$fullname, "\n")

      longname <- self$attribute("long_name")
      if (!is.na(longname) && longname != self$name)
        cat("Long name:", longname, "\n")

      if (!is.null(private$.values)) {
        rng <- self$attribute("actual_range")
        if (is.na(rng[1L])) {
          cat("\nValues: -\n")
          cat(sprintf("    NA: %d (100%%)\n", length(self$values)))
        } else {
          units <- self$attribute("units")
          if (is.na(units)) units <- ""
          cat("\nValues: [", rng[1L], " ... ", rng[2L], "] ", units, "\n", sep = "")
          NAs <- sum(is.na(self$values))
          cat(sprintf("    NA: %d (%.1f%%)\n", NAs, NAs * 100 / length(self$values)))
        }
      } else
        cat("\nValues: (not loaded)\n")

      if (!is.null(private$.crs)) {
        cat("\nCoordinate reference system:\n")
        print(.slim.data.frame(private$.crs$brief(), ...), right = FALSE, row.names = FALSE)
      }

      cat("\nAxes:\n")
      axes <- do.call(rbind, lapply(private$.axes, function(a) a$brief()))
      axes <- lapply(axes, function(c) if (all(c == "")) NULL else c)
      if (length(axes)) {
        axes <- as.data.frame(axes[lengths(axes) > 0L])
        print(.slim.data.frame(axes, ...), right = FALSE, row.names = FALSE)
      } else cat(" (none)\n")

      len <- length(private$.ancillary)
      if (len) {
        cat("\nAncillary variable", if (len > 1L) "s", ":\n", sep = "")
        anc <- do.call(rbind, lapply(private$.ancillary, function(a) a$brief()))
        print(.slim.data.frame(anc, ...), right = FALSE, row.names = FALSE)
      }

      len <- length(private$.cell_measures)
      if (len) {
        cat("\nCell measure", if (len > 1L) "s", ": ",
            paste(sapply(private$.cell_measures, function(cm) paste0(cm$name, " (", cm$measure, ")")), collapse = "; "),
            "\n", sep = "")
      }

      if (!is.null(private$.llgrid)) {
        cat("\nAuxiliary longitude-latitude grid:\n")
        ll <- private$.llgrid$brief()
        print(.slim.data.frame(ll, ...), right = FALSE, row.names = FALSE)
      }

      self$print_attributes(...)
    },

    #' @description Some details of the data variable.
    #'
    #' @return A 1-row `data.frame` with some details of the data variable.
    brief = function() {
      nm <- if (!is.null(ds <- self$group$data_set) && ds$has_subgroups())
        self$fullname
      else
        self$name

      unit <- self$attribute("units")
      if (is.na(unit)) unit <- ""
      longname <- self$attribute("long_name")
      if (is.na(longname) || longname == nm) longname <- ""

      data.frame(name = nm, long_name = longname, units = unit,
                 data_type = private$.data_type, axes = paste(names(private$.axes), collapse = ", "))
    },

    #' @description The information returned by this method is very concise
    #'   and most useful when combined with similar information from other
    #'   variables.
    #' @return Character string with very basic variable information.
    shard = function() {
      paste0("[", self$id, ": ", self$name, "]")
    },

    #' @description Retrieve interesting details of the data variable.
    #' @return A 1-row `data.frame` with details of the data variable.
    peek = function() {
      out <- data.frame(id = self$id)
      out$name <- self$name
      out$long_name <- self$attribute("long_name")
      out$standard_name <- self$attribute("standard_name")
      out$units <- self$attribute("units")
      out$axes <- paste(sapply(private$.axes, function(a) a$name), collapse = ", ")
      out
    },

    #' @description Detach the various properties of this variable from an
    #'   underlying netCDF resource.
    #' @return Self, invisibly.
    detach = function() {
      lapply(private$.cell_measures, function(cm) cm$detach())
      if (!is.null(private$.crs)) private$.crs$detach()
      if (!is.null(private$.llgrid)) private$.llgrid$detach()
      lapply(private$.axes, function(ax) ax$detach())
      private$.dirty <- TRUE
      super$detach()
      invisible(self)
    },
    #' @description Return the time object from the axis representing time.
    #' @param want Character string with value "axis" or "time", indicating
    #' what is to be returned.
    #' @return If `want = "axis"` the [CFAxisTime] axis; if `want = "time"` the
    #' `CFTime` instance of the axis, or `NULL` if the variable does not have a
    #' "time" axis.
    time = function(want = "time") {
      ndx <- sapply(private$.axes, inherits, "CFAxisTime")
      if (any(ndx)) {
        if (want == "axis") private$.axes[[which(ndx)]]
        else private$.axes[[which(ndx)]]$time
      } else NULL
    },

    #' @description Retrieve the data in the object exactly as it was read from
    #'   a netCDF resource or produced by an operation.
    #' @return An `array`, `matrix` or `vector` with (dim)names set.
    raw = function() {
      data <- self$read_data()
      if (is.null(data)) return(NULL)
      if (is.null(dim(data)))
        names(data) <- self$dimnames
      else
        dimnames(data) <- self$dimnames
      data
    },

    #' @description Retrieve the data in the object in the form of an R array,
    #' with axis ordering Y-X-others and Y values going from the top down.
    #' @return An `array` or `matrix` of data in R ordering, or a `vector` if
    #' the data has only a single dimension.
    array = function() {
      data <- self$raw()
      if (is.null(data)) return(NULL)
      if (is.null(dim(data)))
        data
      else
        private$orient(data, "R")
    },

    #' @description This method extracts a subset of values from the array of
    #'   the variable, with the range along each axis to extract expressed in
    #'   coordinate values of the domain of each axis.
    #'
    #' @details The range of values along each axis to be subset is expressed in
    #'   coordinates of the domain of the axis. Any axes for which no selection
    #'   is made in the `...` argument are extracted in whole. Coordinates can
    #'   be specified in a variety of ways that are specific to the nature of
    #'   the axis. For numeric axes it should (resolve to) be a vector of real
    #'   values. A range (e.g. `100:200`), a vector (`c(23, 46, 3, 45, 17`), a
    #'   sequence (`seq(from = 78, to = 100, by = 2`), all work. Note, however,
    #'   that only a single range is generated from the vector so these examples
    #'   resolve to `(100, 200)`, `(3, 46)`, and `(78, 100)`, respectively. For
    #'   time axes a vector of character timestamps, `POSIXct` or `Date` values
    #'   must be specified. As with numeric values, only the two extreme values
    #'   in the vector will be used.
    #'
    #'   If the range of coordinate values for an axis in argument `...` extends
    #'   the valid range of the axis, the extracted data will start at the
    #'   beginning for smaller values and extend to the end for larger values.
    #'   If the values envelope the valid range the entire axis will be
    #'   extracted in the result. If the range of coordinate values for any axis
    #'   are all either smaller or larger than the valid range of the axis then
    #'   nothing is extracted and `NULL` is returned.
    #'
    #'   The extracted data has the same dimensional structure as the data in
    #'   the variable, with degenerate dimensions preserved. The order of the
    #'   axes in argument `...` does not reorder the axes in the result; use the
    #'   `array()` method for this.
    #'
    #'   As an example, to extract values of a variable for Australia for the
    #'   year 2020, where the first axis in `x` is the longitude, the second
    #'   axis is the latitude, both in degrees, and the third (and final) axis
    #'   is time, the values are extracted by `x$subset(X = c(112, 154), Y =
    #'   c(-9, -44), T = c("2020-01-01", "2021-01-01"))`. Note that this works
    #'   equally well for projected coordinate reference systems - the key is
    #'   that the specification in argument `...` uses the same domain of values
    #'   as the respective axes in `x` use.
    #'
    #'   ## Auxiliary coordinate variables
    #'
    #'   A special case exists for variables where the horizontal dimensions (X
    #'   and Y) are not in longitude and latitude coordinates but in some other
    #'   coordinate system. In this case the netCDF resource may have so-called
    #'   *auxiliary coordinate variables* for longitude and latitude that are
    #'   two grids with the same dimension as the horizontal axes of the data
    #'   variable where each pixel gives the corresponding value for the
    #'   longitude and latitude. If the variable has such *auxiliary coordinate
    #'   variables* then you can specify their names (instead of specifying the
    #'   names of the primary planar axes). The resolution of the grid that is
    #'   produced by this method is automatically calculated. If you want to
    #'   subset those axes then specify values in decimal degrees; if you want
    #'   to extract the full extent, specify `NA` for both axes.
    #' @param ... One or more arguments of the form `axis = range`. The "axis"
    #'   part should be the name of an axis or its orientation `X`, `Y`, `Z` or
    #'   `T`. The "range" part is a vector of values representing coordinates
    #'   along the axis where to extract data. Axis designators and names are
    #'   case-sensitive and can be specified in any order. If values for the
    #'   range per axis fall outside of the extent of the axis, the range is
    #'   clipped to the extent of the axis.
    #' @param rightmost.closed Single logical value to indicate if the upper
    #'   boundary of range in each axis should be included. You must use the
    #'   argument name when specifying this, like `rightmost.closed = TRUE`, to
    #'   avoid the argument being treated as an axis name.
    #' @param .resolution For interpolation with auxiliary coordinates, the
    #'   resolution in longitude and latitude directions as numeric values in
    #'   decimal degrees, optional. If a single value is given, it will apply in
    #'   both directions. If not supplied, the resolution in the center of the
    #'   requested area will be calculated and applied over the entire area.
    #' @return A `CFVariable` instance, having the axes and attributes of the
    #'   variable, or `NULL` if one or more of the selectors in the `...`
    #'   argument fall entirely outside of the range of the axis.
    #'
    #'   If `self` is linked to a netCDF resource then the result will be linked
    #'   to the same netCDF resource as well, except when *auxiliary coordinate
    #'   variables* have been selected for the planar axes. In all cases the
    #'   result will be attached to a private group.
    subset = function(..., rightmost.closed = FALSE, .resolution = NULL) {
      num_axes <- self$ndims
      if (!num_axes)
        stop("Cannot subset a scalar variable", call. = FALSE)
      axis_names <- names(private$.axes)

      # Organize the selectors
      selectors <- list(...)
      if (is.list(selectors[[1L]]))
        selectors <- selectors[[1L]]
      sel_names <- names(selectors)
      axis_order <- private$check_names(sel_names)

      # Auxiliary coordinates
      aux <- NULL
      if (inherits(private$.llgrid, "CFAuxiliaryLongLat")) {
        aux_names <- private$.llgrid$grid_names
        if (any(aux_names %in% sel_names)) {
          aux <- private$auxiliary_interpolation(selectors, aux_names, .resolution)
          sel_names <- sel_names[-which(sel_names %in% aux_names)]
          ll_dimids <- private$.llgrid$dimids
          aoi_bounds <- aux$aoi$bounds()
        }
      }

      # Private group for the result
      grp <- CFGroup$new("", NULL)

      # Start and count are "local", indices relative to the dimensions of self,
      # which may be a subset of the data variable on file.
      start <- rep(1L, num_axes)
      count <- self$dim()

      ZT_dim <- vector("integer")
      out_axes <- vector("list", num_axes)
      for (ax in seq(num_axes)) {
        axis <- private$.axes[[ax]]
        orient <- axis$orientation
        ax_dimid <- axis$dimid

        # In every section, set start and count values and create a corresponding axis
        if (!is.null(aux) && !is.null(ax_dimid) && ax_dimid == ll_dimids[1L]) {
          start[ax] <- aux$X[1L]
          count[ax] <- aux$X[2L]
          out_axis <- CFAxisLongitude$new(aux_names[1L], group = grp, values = aux$aoi$dimnames[[2L]],
                                          attributes = axis$attributes)
          out_axis$bounds <- aoi_bounds$lon
          out_axis$delete_attribute("long_name")
        } else if (!is.null(aux) && !is.null(ax_dimid) && ax_dimid == ll_dimids[2L]) {
          start[ax] <- aux$Y[1L]
          count[ax] <- aux$Y[2L]
          out_axis <- CFAxisLatitude$new(aux_names[2L], group = grp, values = aux$aoi$dimnames[[1L]],
                                         attributes = axis$attributes)
          out_axis$bounds <- aoi_bounds$lat
          out_axis$delete_attribute("long_name")
        } else { # No auxiliary long-lat coordinates
          rng <- selectors[[ axis_names[ax] ]]
          if (is.null(rng)) rng <- selectors[[ orient ]]
          if (is.null(rng)) { # Axis not specified so take the whole axis
            ZT_dim <- c(ZT_dim, axis$length)
            out_axis <- axis$copy(group = grp)
          } else { # Subset the axis
            idx <- axis$slice(rng)
            if (is.null(idx)) return(NULL)
            start[ax] <- idx[1L]
            count[ax] <- idx[2L] - idx[1L] + 1L
            ZT_dim <- c(ZT_dim, count[ax])
            out_axis <- axis$subset(group = grp, rng = idx)
          }
        }

        # Collect axes for result
        out_axes[[ax]] <- out_axis
      }
      names(out_axes) <- sapply(out_axes, function(ax) ax$name)

      # Get the data for the result CFVariable
      d <- NULL
      if (is.null(aux)) {
        if (!is.null(private$.values))
          d <- self$read_window(start, count)
      } else {
        d <- self$read_window(start, count)

        lon_idx <- which(sapply(out_axes, inherits, "CFAxisLongitude"))
        lat_idx <- which(sapply(out_axes, inherits, "CFAxisLatitude"))
        if (lon_idx != 1L || lat_idx != 2L) {
          # Permute the data so lon & lat are the first two axes
          dims <- seq(length(dim(d)))
          d <- aperm(d, c(lon_idx, lat_idx, dims[-c(lon_idx, lat_idx)]))
          out_axes <- c(out_axes[lon_idx], out_axes[lat_idx], out_axes[-c(lon_idx, lat_idx)])
        }

        dim(d) <- dim_in <- c(aux$X[2L] * aux$Y[2L], prod(ZT_dim))
        d <- d[aux$index, ]
        dim(d) <- dim_out <- c(aux$box, ZT_dim)
      }

      # If there is a parametric vertical axis, subset its terms
      original_axis_names <- names(private$.axes)
      lapply(out_axes, function(ax) {
        if (ax$is_parametric)
          ax$subset_parametric_terms(original_axis_names, axes, start, count, aux, ZT_dim)
      })

      # Sanitize the attributes for the result, as required, and get a CRS
      if (is.null(aux)) {
        atts <- self$attributes
      } else {
        atts <- self$attributes
        #atts <- private$drop_coordinates_attribute(self$attributes, private$.llgrid$grid_names)
        atts <- atts[!(atts$name == "grid_mapping"), ]  # drop attribute: warped to lat-long
      }

      # Assemble the new instance
      if (is.null(aux)) {
        v <- if (self$has_resource) {
          NCdims <- length(private$.NC_map$start)
          nc <- private$to_nc_indices(start[seq_len(NCdims)], count[seq_len(NCdims)])
          CFVariable$new(private$.NCobj, group = grp, values = d, axes = out_axes,
                         start = nc$start, count = nc$count, attributes = atts)
        } else
          CFVariable$new(self$name, group = grp, values = d, axes = out_axes, attributes = atts)
        v$crs <- private$.crs
        # FIXME: Attach llgrid if not selecting on its axes. Possibly subset
        # if (!is.null(private$.llgrid))
        #  v$gridLongLat <- private$.llgrid
      } else {
        v <- CFVariable$new(self$name, group = grp, values = d, axes = out_axes, attributes = atts)
        v$crs <- NULL
        v$detach()
      }
      v
    },

    #' @description Summarise the temporal domain of the data, if present, to a
    #'   lower resolution, using a user-supplied aggregation function.
    #'
    #' @details Attributes are copied from the input data variable or data
    #'   array. Note that after a summarisation the attributes may no longer be
    #'   accurate. This method tries to sanitise attributes but the onus is on
    #'   the calling code (or yourself as interactive coder). Attributes like
    #'   `standard_name` and `cell_methods` likely require an update in the
    #'   output of this method, but the appropriate new values are not known to
    #'   this method. Use `CFVariable$set_attribute()` on the result of this
    #'   method to set or update attributes as appropriate.
    #' @param name Character vector with a name for each of the results that
    #'   `fun` returns. So if `fun` has 2 return values, this should be a vector
    #'   of length 2. Any missing values are assigned a default name of
    #'   "result_#" (with '#' being replaced with an ordinal number).
    #' @param fun A function or a symbol or character string naming a function
    #'   that will be applied to each grouping of data. The function must return
    #'   an atomic value (such as `sum()` or `mean()`), or a vector of atomic
    #'   values (such as `range()`). Lists and other objects are not allowed and
    #'   will throw an error that may be cryptic as there is no way that this
    #'   method can assert that `fun` behaves properly so an error will pop up
    #'   somewhere, quite possibly in unexpected ways. The function may also be
    #'   user-defined so you could write a wrapper around a function like `lm()`
    #'   to return values like the intercept or any coefficients from the object
    #'   returned by calling that function.
    #' @param period The period to summarise to. Must be one of either "day",
    #'   "dekad", "month", "quarter", "season", "year". A "quarter" is the
    #'   standard calendar quarter such as January-March, April-June, etc. A
    #'   "season" is a meteorological season, such as December-February,
    #'   March-May, etc. (any December data is from the year preceding the
    #'   January data). The period must be of lower resolution than the
    #'   resolution of the time axis.
    #' @param era Optional, integer vector of years to summarise over by the
    #'   specified `period`. The extreme values of the years will be used. This
    #'   can also be a list of multiple such vectors. The elements in the list,
    #'   if used, should have names as these will be used to label the results.
    #' @param ... Additional parameters passed on to `fun`.
    #' @return A `CFVariable` object, or a list thereof with as many
    #'   `CFVariable` objects as `fun` returns values, or `NULL` if the `era`
    #'   argument falls entirely outside of the range of the time axis.
    summarise = function(name, fun, period, era = NULL, ...) {
      if (missing(name) || missing(period) || missing(fun))
        stop("Arguments 'name', 'period' and 'fun' are required.", call. = FALSE) # nocov
      if (!(period %in% c("day", "dekad", "month", "quarter", "season", "year")))
        stop("Argument 'period' has invalid value.", call. = FALSE) # nocov
      if (!all(.is_valid_name(name)))
        stop("Not all names are valid.", call. = FALSE) # nocov

      # Find the time object, create the factor
      tax <- self$time("axis")
      if (is.null(tax))
        stop("No 'time' axis found to summarise on.", call. = FALSE) # nocov
      f <- try(tax$time$factor(period, era), silent = TRUE)
      if (inherits(f, "try-error"))
        stop("The 'time' axis is too short to summarise on.", call. = FALSE) # nocov
      if (is.factor(f)) f <- list(f)

      tm <- which(names(private$.axes) == tax$name)

      # Private group for the result
      grp <- CFGroup$new("", NULL)

      # Helper function for the below lapply
      .make_var <- function(nm, vals, axes, atts) {
        v <- CFVariable$new(nm, group = grp, values = vals, axes = axes, attributes = atts)
        v$crs <- self$crs
        v$detach()
        v
      }

      res <- lapply(f, function(fac) {
        if (!nlevels(fac))
          return(NULL)

        atts <- tax$attributes
        # New CFTime object
        new_tm <- attr(fac, "CFTime")
        if (inherits(new_tm, "CFClimatology")) {
          atts <- atts[!(atts$name == "bounds"), ]
          atts <- rbind(atts, data.frame(name = "climatology", type = "NC_CHAR", length = 16, value = "climatology_bnds"))
        }

        # Make a new time axis for the result
        new_ax <- CFAxisTime$new(tax$name, group = grp, values = new_tm, attributes = atts)
        other_axes <- private$.axes[-tm]
        axes <- c(new_ax, other_axes)
        names(axes) <- c(tax$name, names(other_axes))

        # Summarise
        dt <- private$process_data(tm, fac, fun, ...)

        # Create the output
        atts <- self$attributes
        aux_nm <- self$auxiliary_names

        len <- length(dt) # Number of fun outputs
        if (len == 1L)
          out <- .make_var(name[1L], dt[[1L]], axes, atts)
        else {
          if (length(name) < len)
            name <- c(name, paste0("result_", (length(name)+1L):len))
          out <- lapply(1:len, function(i) .make_var(name[i], dt[[i]], axes, atts))
          names(out) <- name
        }
        out
      })
      if (length(f) == 1L)
        res[[1L]]
      else {
        names(res) <- names(f)
        res
      }
    },

    #' @description This method extracts profiles of values from the array of
    #'   the variable, with the location along each axis to extract expressed in
    #'   coordinate values of each axis.
    #'
    #' @details The coordinates along each axis to be sampled are expressed in
    #'   values of the domain of the axis. Any axes which are not passed as
    #'   arguments are extracted in whole to the result. If bounds are set on
    #'   the axis, the coordinate whose bounds envelop the requested coordinate
    #'   is selected. Otherwise, the coordinate along the axis closest to the
    #'   supplied value will be used. If the value for a specified axis falls
    #'   outside the valid range of that axis, `NULL` is returned.
    #'
    #'   A typical case is to extract the temporal profile as a 1D array for a
    #'   given location. In this case, use arguments for the latitude and
    #'   longitude on an X-Y-T data variable: `profile(lat = -24, lon = 3)`.
    #'   Other profiling options are also possible, such as a 2D zonal
    #'   atmospheric profile at a given longitude for an X-Y-Z data variable:
    #'   `profile(lon = 34)`.
    #'
    #'   Multiple profiles can be extracted in one call by supplying vectors for
    #'   the indicated axes: `profile(lat = c(-24, -23, -2), lon = c(5, 5, 6))`.
    #'   The vectors need not have the same length, unless `.as_table = TRUE`.
    #'   With unequal length vectors the result will be a `list` of `CFVariable`
    #'   instances with different dimensionality and/or different axes.
    #'
    #'   ## Auxiliary coordinate variables
    #'
    #'   A special case exists for variables where the horizontal dimensions (X
    #'   and Y) are not in longitude and latitude coordinates but in some other
    #'   coordinate system. In this case the netCDF resource may have so-called
    #'   *auxiliary coordinate variables*. If the variable has such *auxiliary coordinate
    #'   variables* then you can specify their names (instead of specifying the
    #'   names of the primary planar axes).
    #' @param ... One or more arguments of the form `axis = location`. The
    #'   "axis" part should be the name of an axis or its orientation `X`, `Y`,
    #'   `Z` or `T`. The "location" part is a vector of values representing
    #'   coordinates along the axis where to profile. A profile will be
    #'   generated for each of the elements of the "location" vectors in all
    #'   arguments.
    #' @param .names A character vector with names for the results. The names
    #'   will be used for the resulting `CFVariable` instances, or as values for
    #'   the "location" column of the `data.table` if argument `.as_table` is
    #'   `TRUE`. If the vector is shorter than the longest vector of locations
    #'   in the `...` argument, a name "location_#" will be used, with the #
    #'   replaced by the ordinal number of the vector element.
    #' @param .as_table Logical to flag if the results should be `CFVariable`
    #'   instances (`FALSE`, default) or a single `data.table` (`TRUE`). If
    #'   `TRUE`, all `...` arguments must have the same number of elements, use
    #'   the same axes and the `data.table` package must be installed.
    #' @return If `.as_table == FALSE`, a `CFVariable` instance, or a list
    #'   thereof with each having one profile for each of the elements in the
    #'   "location" vectors of argument `...` and named with the respective
    #'   `.names` value. If `.as_table == TRUE`, a `data.table` with a row for
    #'   each element along all profiles, with a ".variable" column using the
    #'   values from the `.names` argument.
    profile = function(..., .names = NULL, .as_table = FALSE) {
      num_axes <- self$ndims
      if (!num_axes)
        stop("Cannot profile a scalar variable", call. = FALSE)

      # Organize the selectors
      selectors <- list(...)
      sel_names <- names(selectors)
      sel_axes <- private$check_names(sel_names)
      sel_lengths <- sapply(selectors, length)
      total <- max(sel_lengths)

      # Convert domain values to indices
      if (inherits(private$.llgrid, "CFAuxiliaryLongLat")) {
        aux_names <- private$.llgrid$grid_names
        if (all(aux_names %in% sel_names)) {
          xy <- private$.llgrid$sample_index(selectors[[aux_names[1L]]], selectors[[aux_names[2L]]])
          sel_indices <- lapply(1:length(selectors), function(x) {
            if (sel_names[x] == aux_names[1L])
              idx <- xy[, 1L]
            else if (sel_names[x] == aux_names[2L])
              idx <- xy[, 2L]
            else
              idx <- private$.axes[[sel_axes[x]]]$indexOf(selectors[[x]])
            idx[is.na(idx)] <- 0L
            idx
          })
        } else
          xy <- NULL
      } else {
        xy <- NULL
        sel_indices <- lapply(1:length(selectors), function(x) {
          idx <- private$.axes[[sel_axes[x]]]$indexOf(selectors[[x]])
          idx[is.na(idx)] <- 0L
          idx
        })
      }

      # Check .as_table
      if (.as_table) {
        if (!requireNamespace("data.table", quietly = TRUE))
          stop("Please install package 'data.table' before calling this method", call. = FALSE)
        hasNA <- any(sapply(sel_indices, function(x) any(x == 0L)))
        if (!all(sel_lengths == sel_lengths[1L]) || hasNA)
          stop("All ... arguments must have the same length and use same axes when `.as_table = TRUE`.", call. = FALSE)
      }

      # Check .names
      len <- length(.names)
      if (len < total) {
        .names <- c(.names, sapply((len + 1L):total, function(i) paste0("location_", i)))
      } else if (len > total)
        .names <- .names[1L:total]

      # Private group for the result, only intermediate if .as_table == TRUE
      grp <- CFGroup$new("", NULL)

      out <- vector("list", total)
      for (e in 1L:total) {
        indices <- sapply(sel_indices, function(x) x[e])
        if (!any(indices == 0L, na.rm = TRUE)) { # All selector coordinates are in range
          start <- rep(1L, num_axes)
          count <- self$dim()
          out_axes <- vector("list", num_axes)

          for (ax in seq(num_axes)) {
            axis <- private$.axes[[ax]]
            ax_ndx <- match(ax, sel_axes)
            out_axes[[ax]] <- if (!is.na(ax_ndx) && !is.na(indices[ax_ndx])) {
              start[ax] <- indices[ax_ndx]
              count[ax] <- 1L
              orient <- axis$orientation
              nm <- if (is.null(xy)) axis$name
                    else if (orient == "X") private$.llgrid$varLong$name
                    else private$.llgrid$varLat$name
              axis$copy_with_values(nm, group = grp, values = selectors[[ax_ndx]][e])
            } else
              axis$copy(group = grp)
          }
          names(out_axes) <- sapply(out_axes, function(a) a$name)

          # Read the data
          d <- self$read_chunk(start, count)

          # Sanitize the attributes for the result, as required, and make CRS
          if (is.null(xy)) {
            atts <- self$attributes
            crs <- self$crs
          } else {
            #atts <- private$drop_coordinates_attribute(self$attributes, private$.llgrid$grid_names)
            atts <- atts[!(atts$name == "grid_mapping"), ]  # drop: warped to lat-long
            crs <- NULL
          }

          # Assemble the CFVariable instance
          v <- CFVariable$new(.names[e], group = grp, values = d, axes = out_axes, attributes = atts)
          v$crs <- crs
          out[[e]] <- if (.as_table) v$data.table(var_as_column = TRUE)
          else v
        }
      }

      if (.as_table) {
        atts <- attributes(out[[1L]])$value
        out <- data.table::rbindlist(out, use.names = FALSE)
        data.table::setattr(out, "value", atts)
      } else if (total == 1L)
        out <- out[[1L]]
      else
        names(out) <- .names
      out
    },

    #' @description Append the data from another `CFVariable` instance to the
    #'   current instance, along one of the axes. The operation will only
    #'   succeed if the axes other than the one to append along have the same
    #'   coordinates and the coordinates of the axis to append along have to be
    #'   monotonically increasing or decreasing after appending. The attributes
    #'   are not assessed.
    #' @param from The `CFVariable` instance to append to this data variable.
    #' @param along The name of the axis to append along. This must be a single
    #'   character string and the named axis has to be present both in this data
    #'   variable and in the `CFVariable` instance in argument `from`.
    #' @return Self, invisibly, with the arrays from this data variable and
    #'   `from` appended, in a new private group.
    append = function(from, along) {
      # FIXME: Make from a list so that multiple appends can be done in one go
      # Check if the `from` variable can be appended to self
      if (length(along) != 1L || !(along %in% names(private$.axes)))
        stop("Argument `along` must be the name of an axis present in this data variable.", call. = FALSE)
      if (length(from$axes) != length(private$.axes))
        stop("Data variable `from` must have the same number of axes as this data variable", call. = FALSE)
      for (ax in seq_along(self$axes)) {
        if (self$axes[[ax]]$name == along)
          axno <- ax
        else {
          if (!self$axes[[ax]]$identical(from$axes[[ax]]))
            stop(paste("Axis", ax, "is not identical between the two data variables."), call. = FALSE)
        }
      }

      # Merge the data values
      v <- abind::abind(self$values, from$raw(), along = axno)

      # Make a new group for the result
      grp <- CFGroup$new("", NULL)

      # Extend the axis `along` with values from `from`, increase the
      # corresponding .dims value and set the values
      private$.axes[[axno]] <- private$.axes[[axno]]$append(from$axes[[axno]], grp)
      private$.dims[axno] <- private$.axes[[axno]]$length
      private$set_values(v)

      # Unlink from any netCDF resource
      self$detach()

      self$attach_to_group(grp)
      invisible(self)
    },

    #' @description Tests if the `other` object is coincident with this data
    #'   variable: identical axes.
    #' @param other A `CFVariable` instance to compare to this data variable.
    #' @return `TRUE` if the data variables are coincident, `FALSE` otherwise.
    is_coincident = function(other) {
      if (!inherits(other, "CFVariable")) return(FALSE)
      other_axes <- other$axes
      if (length(other_axes) != length(self$axes)) return(FALSE)
      for (ax in seq_along(self$axes))
        if (!self$axes[[ax]]$identical(other_axes[[ax]]))
          return(FALSE)
      TRUE
    },

    #' @description Add a cell measure variable to this variable.
    #' @param cm An instance of [CFCellMeasure].
    #' @return Self, invisibly.
    add_cell_measure = function(cm) {
      if (inherits(cm, "CFCellMeasure"))
        private$.cell_measures <- append(private$.cell_measures, setNames(list(cm), cm$name))
    },

    #' @description Add an auxiliary coordinate to the appropriate axis of this
    #'   variable. The length of the axis must be the same as the length of the
    #'   auxiliary labels.
    #' @param aux An instance of [CFLabel] or [CFAxis].
    #' @param axis An instance of `CFAxis` that these auxiliary coordinates are
    #'   for.
    #' @return Self, invisibly.
    add_auxiliary_coordinate = function(aux, axis) {
      if (inherits(aux, c("CFLabel", "CFAxis"))) {
        axis$auxiliary <- aux
        #if (aux$name %in% axis$coordinate_names)
        #  self$update_coordinates_attribute(aux$name)
      }
    },

    #' @description Add an ancillary variable to this variable.
    #' @param var An instance of [CFVariable].
    #' @return Self, invisibly.
    add_ancillary_variable = function(var) {
      if (inherits(var, "CFVariable")) {
        private$.ancillary[[var$name]] <- var
        #if (aux$name %in% axis$coordinate_names)
        #  self$update_coordinates_attribute(aux$name)
      }
    },

    #' @description Attach this variable to a group. If there is another object
    #'   with the same name in this group an error is thrown. For associated
    #'   objects (such as axes, CRS, boundary variables, etc), if another object
    #'   with the same name is otherwise identical to the associated object then
    #'   that object will be linked from the variable, otherwise an error is
    #'   thrown.
    #' @param grp An instance of [CFGroup].
    #' @param locations Optional. A `list` whose named elements correspond to
    #'   the names of objects associated with this variable (but not the
    #'   variable itself). Each list element has a single character string
    #'   indicating the group in the hierarchy where the object should be
    #'   stored. As an example, if the variable has axes "lon" and "lat" and
    #'   they should be stored in the parent group of `grp`, then specify
    #'   `locations = list(lon = "..", lat = "..")`. Locations can use absolute
    #'   paths or relative paths from the group. Associated objects that are not
    #'   in the list will be stored in group `grp`. If the argument `locations`
    #'   is not provided, all associated objects will be stored in this group.
    #' @return Self, invisibly.
    attach_to_group = function(grp, locations = list()) {
      if (self$name %in% names(grp$objects))
        stop("CF object '", self$name, "' already exists in group ", grp$fullname, ".", call. = FALSE)

      # FIXME: All objects that are added must be registered so that they can be
      # removed if there is an error later on. General process: every object
      # type has an attach_to_group method to handle its own attachment. If
      # an error occurs, clean up and cascade the error to the caller.
      lapply(private$.axes, function(ax) ax$attach_to_group(grp, locations))
      if (!is.null(private$.llgrid))
        private$.llgrid$attach_to_group(grp, locations)
      if (!is.null(private$.crs))
        private$.crs$attach_to_group(grp, locations)
      lapply(private$.cell_measures, function(cm) cm$attach_to_group(grp, locations))
      lapply(private$.ancillary, function(anc) anc$attach_to_group(grp, locations))

      super$attach_to_group(grp, locations)
    },

    #' @description Convert the data to a `terra::SpatRaster` (3D) or a
    #'   `terra::SpatRasterDataset` (4D) object. The data will be oriented to
    #'   North-up. The 3rd dimension in the data will become layers in the
    #'   resulting `SpatRaster`, any 4th dimension the data sets. The `terra`
    #'   package needs to be installed for this method to work.
    #' @return A `terra::SpatRaster` or `terra::SpatRasterDataset` instance.
    terra = function() {
      if (!requireNamespace("terra", quietly = TRUE))
        stop("Please install package 'terra' before using this functionality")

      # Extent
      YX <- private$YXZT()[1L:2L]
      if (!all(YX))
        stop("Data variable does not have X and Y axes.", call. = FALSE) # nocov

      Xbnds <- private$.axes[[YX[2L]]]$bounds
      if (inherits(Xbnds, "CFBounds")) Xbnds <- Xbnds$range()
      else {
        vals <- private$.axes[[YX[2L]]]$values
        halfres <- (vals[2L] - vals[1L]) * 0.5 # this assumes regular spacing
        Xbnds <- c(vals[1L] - halfres, vals[length(vals)] + halfres)
      }
      Ybnds <- private$.axes[[YX[1L]]]$bounds
      if (inherits(Ybnds, "CFBounds")) Ybnds <- Ybnds$range()
      else {
        vals <- private$.axes[[YX[1L]]]$values
        halfres <- (vals[2L] - vals[1L]) * 0.5 # this assumes regular spacing
        Ybnds <- c(vals[1L] - halfres, vals[length(vals)] + halfres)
      }
      if (Ybnds[1L] > Ybnds[2L]) Ybnds <- rev(Ybnds)
      ext <- round(c(Xbnds, Ybnds), CF.options$digits) # Round off spurious "accuracy"

      # CRS
      wkt2 <- if (is.null(self$crs)) "" else self$crs$wkt2(.wkt2_axis_info(self))

      # Create the object
      arr <- self$array()
      numdims <- length(dim(arr))
      dn <- dimnames(arr)
      if (numdims == 4L) {
        r <- terra::sds(arr, extent = ext, crs = wkt2)
        for (d4 in seq_along(dn[[4L]]))
          names(r[d4]) <- dn[[3L]]
        names(r) <- dn[[4L]]
      } else {
        r <- terra::rast(arr, extent = ext, crs = wkt2)
        if (numdims == 3L)
          names(r) <- dn[[3L]]
        else if (length(private$.axes) > 2L) # Use coordinate of a scalar axis
          names(r) <- private$.axes[[3L]]$coordinates
      }

      r
    },

    #' @description Retrieve the data variable in the object in the form of a
    #'   `data.table`. The `data.table` package needs to be installed for this
    #'   method to work.
    #'
    #'   The attributes associated with this data variable will be mostly lost.
    #'   If present, attributes 'long_name' and 'units' are attached to the
    #'   `data.table` as attributes, but all others are lost.
    #' @param var_as_column Logical to flag if the name of the variable should
    #'   become a column (`TRUE`) or be used as the name of the column with the
    #'   data values (`FALSE`, default). Including the name of the variable as a
    #'   column is useful when multiple `data.table`s are merged by rows into
    #'   one.
    #' @return A `data.table` with all data points in individual rows. All axes
    #'   will become columns. Two attributes are added: `name` indicates the
    #'   long name of this data variable, `units` indicates the physical unit of
    #'   the data values.
    data.table = function(var_as_column = FALSE) {
      if (!requireNamespace("data.table", quietly = TRUE))
        stop("Please install package 'data.table' before using this functionality", call. = FALSE)
      .datatable.aware = TRUE

      exp <- expand.grid(lapply(private$.axes, function(ax) ax$coordinates),
                         KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
      dt <- data.table::as.data.table(exp)
      if (var_as_column) {
        dt[ , .variable := private$.name]
        suppressWarnings(dt[ , .value := self$values])
      } else
        suppressWarnings(dt[ , eval(private$.name) := self$values])

      long_name <- self$attribute("long_name")
      if (is.na(long_name)) long_name <- ""
      units <- self$attribute("units")
      if (is.na(units)) units <- ""
      data.table::setattr(dt, "value", list(name = long_name, units = units))
      dt
    },

    #' @description Write the data variable to a netCDF file, including all of
    #'   its dependent objects, such as axes and attributes.
    #'
    #'   Axes with `length == 1L` are written as a "scalar axis", unless they
    #'   are unlimited.
    #' @param pack Optional. Logical to indicate if the data should be packed
    #'   for a `CFVariable` first written to file. Packing is only useful for
    #'   numeric data; packing is not performed on integer values. Packing is
    #'   always to the "NC_SHORT" data type, i.e. 16-bits per value. If the
    #'   variable has been written before, the packing state of the variable on
    #'   file will be used.
    #' @return Self, invisibly.
    write = function(pack) {
      # FIXME: Auxiliary long-lat, ancillary, cell measure variables
      # CRS
      if (!is.null(self$crs)) {
        self$crs$write()
        self$set_attribute("grid_mapping", "NC_CHAR", self$crs$name)
      }

      # Axes and auxiliary coordinates
      if (length(private$.axes))
        lbls <- unlist(sapply(private$.axes, function(ax) {ax$write(); ax$coordinate_names[-1L]}), use.names = FALSE)

      if (private$.dirty) {
        dt <- private$orient(self$read_data(), "CF")
        ord <- private$XYZT()

        if (is.null(private$.NCobj)) {
          # Drop true scalar dimensions from the dt dim
          ax_names <- attr(dt, "axes") # Names not qualified!
          scalars  <- sapply(ax_names, function(ax) private$.axes[[ax]]$length == 1L && !private$.axes[[ax]]$unlimited)
          axis_dimids <- sapply(ax_names[!scalars], function(ax) private$.axes[[ax]]$dimid)
          ax_names <- sapply(ax_names, function(ax) private$.axes[[ax]]$fullname) # Names are now qualified
          dim(dt)  <- dim(dt)[!scalars]

          pack <- if (missing(pack)) FALSE
                  else pack && private$.data_type %in% c("NC_FLOAT", "NC_DOUBLE")

          # Create a new NC variable on file
          private$.NCobj <- NCVariable$new(id = NA, name = self$name, group = private$.group$NC,
                                           vtype = if (pack) "NC_SHORT" else private$.data_type,
                                           dimids = if (all(scalars)) NA else axis_dimids)
          private$.id <- private$.NCobj$id
        } else {
          pack <- private$.NCobj$is_packed
          ax_names <- sapply(private$.axes, function(x) x$fullname)
          scalars <- rep(FALSE, length(ax_names))
        }

        # Packing attributes
        if (pack) {
          actual_range <- self$attribute("actual_range")
          self$.NCobj$set_attribute("add_offset", private$.data_type, (actual_range[1L] + actual_range[2L]) * 0.5)
          self$.NCobj$set_attribute("scale_factor", private$.data_type, (actual_range[2L] - actual_range[1L]) / 65534)
          self$.NCobj$set_attribute("missing_value", "NC_SHORT", -32767)
        }

        # Set "coordinates" attribute for scalar axes and labels
        if (any(scalars) || length(lbls))
          self$set_attribute("coordinates", "NC_CHAR", paste(c(ax_names[scalars], lbls), collapse = " "))

        private$write_data(dt, pack = pack, na.mode = 2)
        private$.dirty <- FALSE
      }

      self$write_attributes()

      invisible(self)
    },

    #' @description Write the data variable to a Zarr group, including its
    #'   attributes and other assorted objects. Axes, auxiliary coordinates and
    #'   boundary values that are regular or short are written inline in the
    #'   attributes of the array, irregular ones have already been stored
    #'   externally.
    #' @param grp An instance of `zarr_group` to write the data variable to. The
    #'   data variable will be written to a new Zarr array with the name of the
    #'   data variable.
    #' @return Self, invisibly.
    write_geozarr = function(grp) {
      # Create Zarr array metadata for the data variable
      ab <- zarr::array_builder$new()
      vals <- self$values
      ab$shape <- dim(vals) %||% length(vals)
      ab$data_type <- switch(storage.mode(vals),
                             "double" = "float64",
                             "integer" = "int32",
                             "character" = "string")
      shp <- ab$shape
      names(shp) <- names(private$.axes)
      ab$chunk_shape <- zarr::optimal_chunking(shp)
      if (prod(ab$shape) > zarr::zarr_options()$min_compress)
        ab$add_codec("blosc", list(clevel = 6L))
      meta <- ab$metadata()

      # CRS
      crs <- private$.crs
      if (!is.null(crs))
        crs <- crs$wkt2(.wkt2_axis_info(self))

      # Compile the coordinate system from the axes
      axes <- lapply(private$.axes, function(ax) { ax$geozarr_axis(grp) })
      cs <- geozarr::CoordinateSystem$new("coordinate_system", axes, crs)

      # Attributes that are structural are written inline with the Zarr array
      # so filter them out before writing. Leave a few that are descriptive of
      # the data, such as units.
      atts <- private$zarr_attributes(c("coords", "grid_mapping"))
      meta$attributes <- atts

      # Build the full array metadata, including convention attributes
      if (is.character(crs))
        crs <- list(compound = list(wkt2 = crs))
      meta$chunk_key_encoding <- list(name = "default",
                                      configuration = list(separator = "."))
      meta <- geozarr::set_convention(meta, cs, crs = crs, external_group = "..")

      # Add any auxiliary variables
      # lapply(private$.aux, function(x) {x$write_geozarr(grp)})

      # Create the GeoZarr array and add it to the Zarr group
      new_array <- geozarr::geozarr_array$new(self$name, meta, grp, grp$store, cs)
      new_array$write(vals)
      new_array$dirty <- TRUE
      new_array$save()
      grp$set_node(new_array)

      invisible(self)
    },

    #' @description Save the data variable to a netCDF file, including its
    #'   subordinate objects such as axes, CRS, etc. Note that saving a data
    #'   variable will create a "bare-bones" netCDF file and its associated
    #'   [CFDataset].
    #' @param fn The name of the netCDF file to create.
    #' @param pack Logical to indicate if the data should be packed. Packing is
    #'   only useful for numeric data; packing is not performed on integer
    #'   values. Packing is always to the "NC_SHORT" data type, i.e. 16-bits per
    #'   value.
    #' @return The newly create `CFDataset`, invisibly.
    save = function(fn, pack = FALSE) {
      ds <- create_ncdf()
      ds$add_variable(self)
      ds$save(fn, pack = pack)
      invisible(ds)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Data variable"
    },

    #' @field axes (read-only) List of instances of classes descending from
    #'   [CFAxis] that are the axes of the data object.
    axes = function(value) {
      if (missing(value))
        private$.axes
    },

    #' @field ancillary_variables A list of ancillary data variables associated
    #' with this data variable.
    ancillary_variables = function(value) {
      if (missing(value))
        private$.ancillary
    },

    #' @field crs The coordinate reference system of this variable,
    #'   as an instance of [CFGridMapping]. If this field is `NULL`, the
    #'   horizontal component of the axes are in decimal degrees of longitude
    #'   and latitude.
    crs = function(value) {
      if (missing(value))
        private$.crs
      else if (is.null(value) || inherits(value, "CFGridMapping"))
        private$.crs <- value
      else
        stop("Invalid CRS for a CF data variable.", call. = FALSE) # nocov
    },

    #' @field cell_measures (read-only) List of the [CFCellMeasure] objects of
    #'   this variable, if defined.
    cell_measures = function(value) {
      if (missing(value))
        private$.cell_measures
    },

    #' @field dimids (read-only) Retrieve the dimension ids used by the
    #'   NC variable used by this variable.
    dimids = function(value) {
      if (missing(value))
        self$NC$dimids
    },

    #' @field dimnames (read-only) Retrieve dimnames of the data variable.
    dimnames = function(value) {
      if (missing(value)) {
        # A data variable with a single value has no axes, like in ROMS data.
        if (!length(private$.axes)) return(NULL)

        len <- self$ndims
        dn <- lapply(1:len, function(ax) dimnames(private$.axes[[ax]]))
        names(dn) <- sapply(1:len, function(ax) private$.axes[[ax]]$name)
        dn
      }
    },

    #' @field auxiliary_names (read-only) Retrieve the names of the auxiliary
    #'   longitude and latitude grids as a vector of two character strings, in
    #'   that order. If no auxiliary grids are defined, returns `NULL`.
    auxiliary_names = function(value) {
      if (missing(value)) {
        if (is.null(private$.llgrid)) NULL
        else private$.llgrid$grid_names
      }
    },

    #' @field values (read-only) Retrieve the raw values of the data variable.
    #'   In general you should use the `raw()` function rather than this method
    #'   because the `raw()` function will attach `dimnames` to the array that
    #'   is returned.
    values = function(value) {
      if (missing(value))
        self$read_data()
    },

    #' @field gridLongLat  Retrieve or set the grid of longitude and latitude
    #'   values of every grid cell when the main variable grid has a different
    #'   coordinate system.
    gridLongLat = function(value) {
      if (missing(value))
        private$.llgrid
      else if (inherits(value, "CFAuxiliaryLongLat"))
        if (all(value$dimids %in% sapply(private$.axes, function(x) x$dimid)))
          private$.llgrid <- value
        else
          warning("Dimension ids of auxiliary lat-lon grid do not match those of the axis.", call. = FALSE)
      else stop("Trying to set wrong object as auxiliary lat-lon grid.", call. = FALSE)
    },

    #' @field crs_wkt2 (read-only) Retrieve the coordinate reference system
    #' description of the variable as a WKT2 string.
    crs_wkt2 = function(value) {
      if (missing(value)) {
        if (is.null(private$.crs)) {
          # If no CRS has been set, return the default GEOGCRS unless
          # the axis coordinates fall out of range in which case an empty string
          # is returned.
          orient <- lapply(private$.axes, function(x) x$orientation)
          X <- match("X", orient, nomatch = 0L)
          Y <- match("Y", orient, nomatch = 0L)
          if (X && Y) {
            X <- private$.axes[[X]]$range()
            Y <- private$.axes[[Y]]$range()
            if (Y[1L] >= -90 && Y[2L] <= 90 && ((X[1L] >= 0 && X[2L] <= 360) || (X[1L] >= -180 && X[2L] <= 180)))
              .wkt2_crs_geo(4326)
            else ""
          } else ""
        } else
          private$.crs$wkt2(.wkt2_axis_info(self))
      }
    }
  )
)

# Public S3 methods ------------------------------------------------------------

#' @export
dim.CFVariable <- function(x) {
  nd <- x$ndims
  if (nd) {
    ax <- x$axes[1L:nd]
    sapply(ax, function(z) z$length)
  } else NULL
}

#' @export
dimnames.CFVariable <- function(x) {
  ax <- x$axes
  if (length(ax)) names(ax)
  else NULL
}

#' Extract data for a variable
#'
#' Extract data from a `CFVariable` instance, optionally sub-setting the
#' axes to load only data of interest.
#'
#' If all the data of the variable in `x` is to be extracted, simply use `[]`
#' (unlike with regular arrays, this is required, otherwise the details of the
#' variable are printed on the console).
#'
#' The indices into the axes to be subset can be specified in a variety of
#' ways; in practice it should (resolve to) be a vector of integers. A range
#' (e.g. `100:200`), an explicit vector (`c(23, 46, 3, 45, 17`), a sequence
#' (`seq(from = 78, to = 100, by = 2`), all work. Note, however, that only a
#' single range is generated from the vector so these examples resolve to
#' `100:200`, `3:46`, and `78:100`, respectively. It is also possible to use a
#' custom function as an argument.
#'
#' This method works with "bare" indices into the axes of the array. If
#' you want to use domain values of the axes (e.g. longitude values or
#' timestamps) to extract part of the variable array, use the
#' `CFVariable$subset()` method.
#'
#' Scalar axes should not be included in the indexing as they do not represent a
#' dimension into the data array.
#'
#' @param x An `CFVariable` instance to extract the data of.
#' @param i,j,... Expressions, one for each axis of `x`, that select a
#'   number of elements along each axis. If any expressions are missing,
#'   the entire axis is extracted. The values for the arguments may be an
#'   integer vector or a function that returns an integer vector. The range of
#'   the values in the vector will be used. See examples, below.
#' @param drop Logical, ignored. Axes are never dropped. Any degenerate
#'   dimensions of the array are returned as such, with dimnames and appropriate
#'   attributes set.
#'
#' @return An array with dimnames and other attributes set.
#' @export
#' @aliases bracket_select
#' @docType methods
#' @examples
#' fn <- system.file("extdata",
#'   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc",
#'   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' pr <- ds[["pr"]]
#'
#' # How are the dimensions organized?
#' dimnames(pr)
#'
#' # Precipitation data for March for a single location
#' x <- pr[5, 12, 61:91]
#' str(x)
#'
#' # Summer precipitation over the full spatial extent
#' summer <- pr[, , 173:263]
#' str(summer)
"[.CFVariable" <- function(x, i, j, ..., drop = FALSE) {
  caller_env <- parent.frame()

  numaxes <- x$ndims
  t <- vector("list", numaxes)
  names(t) <- dimnames(x)[1:numaxes]

  sc <- sys.call()
  if (numaxes == 0L && length(sc) == 3L) { # Variable is a scalar value
    start <- 1L
    count <- NA_integer_
  } else {
    sc <- sc[-(1L:2L)] # drop [ and x
    if ((length(sc) == 1L) && (identical(sc[[1L]], quote(expr = )))) {
      # [] specified, read whole array
      start <- rep(1L, numaxes)
      count <- rep(NA_integer_, numaxes)
      dnames <- lapply(x$axes, dimnames)
      t <- lapply(x$axes, function(z) z$time)
    } else if (length(sc) != numaxes) {
      stop("Indices specified are not equal to the number of axes of the variable")
    } else {
      start <- vector("integer", numaxes)
      count <- vector("integer", numaxes)
      dnames <- vector("list", numaxes)
      names(dnames) <- dimnames(x)[1:numaxes]
      for (d in seq_along(sc)) {
        ax <- x$axes[[d]]
        tm <- ax$time
        if (identical(sc[[d]], quote(expr = ))) {
          # Axis not subsetted, read the whole thing
          start[d] <- 1L
          count[d] <- NA_integer_
          dnames[[d]] <- dimnames(ax)
          if (!is.null(tm)) t[[d]] <- tm
        } else {
          # Subset the axis
          v <- eval(sc[[d]], envir = caller_env)
          ex <- range(v)
          start[d] <- ex[1L]
          count[d] <- ex[2L] - ex[1L] + 1L
          dnames[[d]] <- dimnames(ax)[seq(ex[1], ex[2])]
          if (!is.null(tm)) {
            idx <- tm$indexOf(ex[1L]:ex[2L], "constant")
            t[[d]] <- attr(idx, "CFTime")
          }
        }
      }
    }
  }
  data <- x$read_window(start, count)

  # Apply dimension data and other attributes
  if (length(x$axes) && length(dim(data)) == length(dnames)) { # dimensions may have been dropped automatically, e.g. NC_CHAR to character string
    dimnames(data) <- dnames
    ax <- sapply(x$axes, function(ax) if (ax$length > 1L) ax$orientation)
    ax <- ax[lengths(ax) > 0L]
    attr(data, "axis") <- ax
  }
  time <- t[lengths(t) > 0L]
  if (length(time))
    attr(data, "time") <- time
  data
}
