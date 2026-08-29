# Standard names used for parametric Z axes
Z_parametric_standard_names <-
  c("atmosphere_ln_pressure_coordinate",
    "atmosphere_sigma_coordinate", "atmosphere_hybrid_sigma_pressure_coordinate",
    "atmosphere_hybrid_height_coordinate", "atmosphere_sleve_coordinate",
    "ocean_sigma_coordinate", "ocean_s_coordinate", "ocean_s_coordinate_g1",
    "ocean_s_coordinate_g2", "ocean_sigma_z_coordinate", "ocean_double_sigma_coordinate")

#' Vertical CF axis object
#'
#' @description This class represents a vertical axis, which may be parametric.
#'   A regular vertical axis behaves like any other numeric axis. A parametric
#'   vertical axis, on the other hand, is defined through an index value that is
#'   contained in the axis coordinates, with additional data variables that hold
#'   ancillary "formula terms" with which to calculate physical axis
#'   coordinates. It is used in atmosphere and ocean data sets.
#'
#'   Parametric vertical axes can only be read from file, not created from
#'   scratch.
#'
#' @references
#' https://cfconventions.org/Data/cf-conventions/cf-conventions.html#parametric-vertical-coordinate
#' https://www.myroms.org/wiki/Vertical_S-coordinate
#'
#' @docType class
#' @export
CFAxisVertical <- R6::R6Class("CFAxisVertical",
  inherit = CFAxisNumeric,
  cloneable = FALSE,
  private = list(
    # The 'standard_name' attribute of the axis that identifies the parametric
    # form of this axis.
    .parameter_name = "",

    # The standard name for the computed values of the axis.
    .name_computed = "",

    # The unit of the computed values of the axis.
    .units_computed = "",

    # A `data.frame` with columns `term`, `variable` and `param` containing
    # the terms of the formula to calculate the axis values. Column `param`
    # has the references to the variables that hold the data for each term.
    .terms = NULL,

    # The computed values of the parametric axis. This is a CFVariable instance
    # once it is computed.
    .computed_values = NULL,

    # Print some details of the parametric definition.
    print_details = function(...) {
      if (!is.null(private$.terms)) {
        cat("\nParametric definition:", private$.parameter_name)

        if (is.null(private$.computed_values)) {
          cat("\n (not calculated)\n")
        } else {
          cat("\n ", private$.name_computed, " (", private$.units_computed, ")\n", sep = "")
          cat(" Axes:", paste(sapply(private$.computed_values$axes, function(ax) ax$shard())), "\n")
        }
      }
    },

    # This function computes the actual physical axis coordinates from the terms.
    compute = function() {
      if (is.null(private$.computed_values))
        switch(private$.parameter_name,
          "atmosphere_hybrid_sigma_pressure_coordinate" = private$atmosphere_hybrid_sigma_pressure_coordinate(),
          "ocean_s_coordinate_g1" = private$ocean_s_coordinate_g1(),
          "ocean_s_coordinate_g2" = private$ocean_s_coordinate_g2()
        )
      private$.computed_values
    },

    # Helper function to get the data for a specific formula term. Can also
    # return `NULL` if the data is not found.
    get_data = function(term) {
      term <- private$.terms[private$.terms$term == term, ]
      if (nrow(term)) {
        v <- term$param[[1L]]
        if (inherits(v, "CFVerticalParametricTerm"))
          v$values
        else if (term$variable[[1L]] == self$name)
          self$values
        else NULL
      } else NULL
    },

    # Helper function to compute z(i,j,k,n) = s(i,j,k) * t(i,j,n)
    ijkn_from_ijk_times_ijn = function(ijk, ijn) {
      d1 <- dim(ijk)
      d2 <- dim(ijn)
      ijkn <- array(ijk, dim = c(d1, d2[3])) # Recycle last dimension
      ijnk <- array(ijn, dim = c(d2, d1[3])) # Same but last two dims must be reversed
      ijkn * aperm(ijnk, c(1, 2, 4, 3))
    },

    atmosphere_hybrid_sigma_pressure_coordinate = function() {
      # Virtual group for the results
      grp <- CFGroup$new("vertical_field_data", NULL)

      # p(n,k,j,i) = a(k)*p0 + b(k)*ps(n,j,i)
      # or
      # p(n,k,j,i) = ap(k) + b(k)*ps(n,j,i)
      # Alternatively: a/ap(k,l) and b(k,l) to calculate layer boundary values as in Sentinel 5P
      ps <- private$get_data("ps")
      b <- private$get_data("b")

      # Construct the axes for the result. Use "ps" axes [i,j,n], combine with
      # self axis [k].
      ps_var <- private$.terms[private$.terms$term == "ps", ]$param[[1L]]
      ax <- ps_var$axes
      axes <- list(ax[[1L]], ax[[2L]], self, ax[[3L]])

      a <- private$get_data("a")
      ap <- if (is.null(a)) private$get_data("ap")
            else a * private$get_data("p0")

      if (is.matrix(b)) {
        # layer boundary values variant
        crds <- sweep(ps %o% b, 4:5, ap, "+")
        crds <- aperm(crds, c(1, 2, 5, 3, 4))
        axes <- append(axes, CFAxisDiscrete$new("layer_position", group = grp, start = 0L, count = 2L))
      } else {
        # layer mid-point variant
        crds <- sweep(ps %o% b, 4, ap, "+")
        crds <- aperm(crds, c(1, 2, 4, 3))
      }

      # Construct the result
      names(axes) <- sapply(axes, function(ax) ax$name)
      private$.name_computed <- "air_pressure"
      v <- CFVariable$new(private$.name_computed, group = grp, values = crds, axes = axes)
      un <- ps_var$attribute("units")
      if (!is.na(un))
        v$set_attribute("units", "NC_CHAR", un)
      private$.computed_values <- v
    },

    ocean_s_coordinate_g1 = function() {
      # Virtual group for the results
      grp <- CFGroup$new("vertical_field_data", NULL)

      # z(n,k,j,i) = S(k,j,i) + eta(n,j,i) * (1 + S(k,j,i) / depth(j,i))
      # where S(k,j,i) = depth_c * s(k) + (depth(j,i) - depth_c) * C(k)
      s <- private$get_data("s")
      C <- private$get_data("C")
      eta <- private$get_data("eta")
      depth <- private$get_data("depth")
      depth_c <- private$get_data("depth_c")

      S <- sweep((depth - depth_c) %o% C, 3, depth_c * s, "+")

      # Construct the axes for the result. Use "depth" axes [i,j], combine with
      # self axis [k].
      ax <- private$.terms[private$.terms$term == "depth", ]$param[[1L]]$axes
      axes <- append(ax, self)
      names(axes) <- c(names(ax), self$name)

      crds <- if (identical(eta, 0))
        S
      else {
        tmp <- sweep(S, MARGIN = 1:2, depth, "/") + 1 # [k,j,i] 1 + S(k,j,i) / depth(j,i)
        d <- dim(eta)
        if (is.null(d))  # eta is a scalar
          S + eta * tmp
        else if (length(d) == 3L) {
          # eta is time-variant so add the [n] axis
          ax <- private$.terms[private$.terms$term == "eta", ]$param[[1L]]
          axes <- append(axes, ax$axes[[3L]])
          names(axes) <- c(names(axes)[1L:3L], ax$axes[[3L]]$name)

          z <- private$ijkn_from_ijk_times_ijn(tmp, eta)
          sweep(z, MARGIN = 1:3, S, "+")
        } else
          S + sweep(tmp, MARGIN = 1:2, eta, "*")
      }
      private$.name_computed <- private$ocean_computed_name()
      v <- CFVariable$new(private$.name_computed, group = grp, values = crds, axes = axes)
      un <- private$.terms[private$.terms$term == "depth", "param"][[1L]]$attribute("units")
      v$set_attribute("units", "NC_CHAR", un)
      private$.computed_values <- v
    },

    ocean_s_coordinate_g2 = function() {
      # Virtual group for the results
      grp <- CFGroup$new("vertical_field_data", NULL)

      # z(n,k,j,i) = eta(n,j,i) + (eta(n,j,i) + depth(j,i)) * S(k,j,i)
      # where S(k,j,i) = (depth_c * s(k) + depth(j,i) * C(k)) / (depth_c + depth(j,i))
      s <- private$get_data("s")
      C <- private$get_data("C")
      eta <- private$get_data("eta")
      depth <- private$get_data("depth")
      depth_c <- private$get_data("depth_c")

      # Construct the axes for the result. Use "depth" axes [i,j], combine with
      # self axis [k].
      ax <- private$.terms[private$.terms$term == "depth", ]$param[[1L]]
      axes <- append(ax$axes, self)
      names(axes) <- c(names(ax$axes), self$name)

      S <- sweep(depth %o% C, MARGIN = 3, s * depth_c, "+") # [k,j,i] depth_c * s(k) + depth(j,i) * C(k)
      S <- sweep(S, MARGIN = 1:2, depth + depth_c, "/")     # [k,j,i] S(k,j,i)

      crds <- if (identical(eta, 0))
        sweep(S, MARGIN = 1:2, depth, "*")
      else {
        d <- dim(eta)
        if (is.null(d))  # eta is a scalar
          sweep(S, MARGIN = 1:2, depth + eta, "*") + eta
        else if (length(d) == 3L) {
          # eta is time-variant so add the [n] axis
          ax <- private$.terms[private$.terms$term == "eta", ]$param[[1L]]
          axes <- append(axes, ax$axes[[3L]])
          names(axes) <- c(names(axes)[1L:3L], ax$axes[[3L]]$name)

          z <- private$ijkn_from_ijk_times_ijn(S, sweep(eta, MARGIN = 1:2, depth, "+"))
          sweep(z, MARGIN = c(1, 2, 4), eta, "+")
        } else {
          z <- sweep(S, MARGIN = 1:2, eta + depth, "*")
          sweep(z, MARGIN = 1:2, eta, "+")
        }
      }
      private$.name_computed <- private$ocean_computed_name()
      v <- CFVariable$new(private$.name_computed, group = grp, values = crds, axes = axes)
      un <- private$.terms[private$.terms$term == "depth", "param"][[1L]]$attribute("units")
      v$set_attribute("units", "NC_CHAR", un)
      private$.computed_values <- v
    },

    # Helper function to determine the computed name of ocean formulations
    ocean_computed_name = function() {
      switch(private$.terms[private$.terms$term == "depth", ]$param[[1L]]$attribute("standard_name"),
        "sea_floor_depth_below_geoid" = "altitude",
        "sea_floor_depth_below_geopotential_datum" = "height_above_geopotential_datum",
        "sea_floor_depth_below_reference_ellipsoid" = "height_above_reference_ellipsoid",
        "sea_floor_depth_below_mean_sea_level" = "height_above_mean_sea_level",
        "non_standard_name"
        )
    }
  ),
  public = list(
    #' @description Create a new instance of this class.
    #' @param var The name of the axis when creating a new axis. When reading an
    #'   axis from file, the [NCVariable] object that describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param values Optional. The values of the axis in a vector. The values
    #'   have to be numeric and monotonic.
    #' @param start Optional. Integer index where to start reading axis data
    #'   from file. The index may be `NA` to start reading data from the start.
    #' @param count Optional. Number of elements to read from file. This may be
    #'   `NA` to read to the end of the data.
    #' @param attributes Optional. A `data.frame` with the attributes of the
    #'   axis. When an empty `data.frame` (default) and argument `var` is an
    #'   `NCVariable` instance, attributes of the axis will be taken from the
    #'   netCDF resource.
    initialize = function(var, group, values, start = 1L, count = NA, attributes = data.frame()) {
      super$initialize(var, group, values = values, start = start, count = count, orientation =  "Z", attributes = attributes)

      if (!is.na(self$attribute("formula_terms")))
        private$.parameter_name <- self$attribute("standard_name")
    },

    #' @description Attach this verical axis to a group, including any
    #'   parameteric terms. If there is another object with the same name in
    #'   this group an error is thrown. For associated objects (such as bounds,
    #'   etc), if another object with the same name is otherwise identical to
    #'   the associated object then that object will be linked from the
    #'   variable, otherwise an error is thrown.
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
      # Parametric terms
      # FIXME

      # Now add the axis, boundary values and auxiliary coordinates to the group
      super$attach_to_group(grp, locations)
    },

    #' @description Detach the parametric terms from an underlying netCDF
    #' resource.
    #' @return Self, invisibly.
    detach = function() {
      # Detaching parametric terms leads to a loop because they are variables, having axes, having parametric terms...
      #lapply(private$.terms$param[-1L], function(t) t$detach()) # do not detach the first parametric term which is self
      super$detach()
      invisible(self)
    },

    #' @description Create a copy of this axis. The copy is completely separate
    #'   from this instance, meaning that the copies of both this instance and
    #'   all of its components are made as new instances.
    #' @param name The name for the new axis. If an empty string is passed, will
    #'   use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return The newly created axis.
    copy = function(name = "", group) {
      if (self$has_resource) {
        ax <- CFAxisVertical$new(self$NC, group = group, values = private$.values, start = private$.NC_map$start,
                                 count = private$.NC_map$count, attributes = self$attributes)
        if (nzchar(name))
          ax$name <- name
      } else {
        if (!nzchar(name))
          name <- self$name
        ax <- CFAxisVertical$new(name, group = group, values = self$values, attributes = self$attributes)
      }
      private$copy_properties_into(ax)

      if (self$is_parametric)
        ax$set_parametric_terms(private$.parameter_name, private$.terms)

      ax
    },

    #' @description Create a copy of this axis but using the supplied values.
    #'   The attributes are copied to the new axis. Boundary values, parametric
    #'   coordinates and auxiliary coordinates are not copied.
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
      CFAxisVertical$new(name, group = group, values = values, attributes = self$attributes)
    },

    #' @description Set the parametric terms for this axis. The name and the
    #'   terms have to fully describe a CF parametric vertical axis.
    #'
    #'   The terms must also agree with the other axes used by any data variable
    #'   that refers to this axis. That is not checked here so the calling code
    #'   must make that assertion.
    #' @param sn The "standard_name" of the parametric formulation. See the CF
    #'   documentation for details.
    #' @param terms A `data.frame` with columns `term`, `variable` and
    #'   `param` containing the terms of the formula to calculate the axis
    #'   values. Column `param` has the references to the variables that
    #'   hold the data for each term.
    set_parametric_terms = function(sn, terms) {
      # FIXME: Put in all the checks on terms and sn

      private$.terms <- terms
      private$.parameter_name <- sn
      self$set_attribute("formula_terms", "NC_CHAR", paste(terms$term, ": ", terms$variable, sep = "", collapse = " "))
      self$set_attribute("standard_name", "NC_CHAR", sn)
      private$.computed_values <- NULL
    },

    #' @description Append a vector of values at the end of the current values
    #'   of the axis. Boundary values are appended as well but if either this
    #'   axis or the `from` axis does not have boundary values, neither will the
    #'   resulting axis.
    #'
    #'   This method is not recommended for parametric vertical axes. Any
    #'   parametric terms will be deleted. If appending of parametric axes is
    #'   required, the calling code should first read out the parametric terms
    #'   and merge them with the parametric terms of the `from` axis before
    #'   setting them back for this axis.
    #' @param from An instance of `CFAxisVertical` whose values to append to the
    #'   values of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @return A new `CFAxisVertical` instance with values from this axis and
    #'   the `from` axis appended.
    append = function(from) {
      if (super$can_append(from) && .c_is_monotonic(self$values, from$values)) {
        ax <- CFAxisVertical$new(self$name, group = group, values = c(private$values, from$values),
                                 attributes = self$attributes)

        if (!is.null(private$.bounds)) {
          new_bnds <- private$.bounds$append(from$bounds, group)
          if (!is.null(new_bnds))
            ax$bounds <- new_bnds
        }

        if (self$is_parametric) {
          # Delete all references to parametric terms
          private$.parameter_name <- ""
          private$.name_computed <- ""
          private$.units_computed <- ""
          private$.terms <- NULL
          private$.computed_values <- NULL
          self$delete_attribute("formula_terms")
        }

        ax
      } else
        stop("Axis values cannot be appended.", call. = FALSE)
    },

    #' @description Return an axis spanning a smaller coordinate range. This
    #'   method returns an axis which spans the range of indices given by the
    #'   `rng` argument. If this axis has parametric terms, these are not subset
    #'   here - they should be separately treated once all associated axes in
    #'   the terms have been subset. That happens automatically in `CFVariable`
    #'   methods which call the `subset_parametric_terms()` method.
    #' @param name The name for the new axis. If an empty string is passed
    #'   (default), will use the name of this axis.
    #' @param group The [CFGroup] where the copy of this axis will live.
    #' @param rng The range of indices whose values from this axis to include in
    #'   the returned axis. If the value of the argument is `NULL`, return a
    #'   copy of the axis.
    #' @return A new `CFAxisVertical` instance covering the indicated range of
    #'   indices. If the value of the argument `rng` is `NULL`, return a copy of
    #'   this axis as the new axis.
    subset = function(name = "", group, rng = NULL) {
      if (is.null(rng))
        self$copy(name, group = group)
      else {
        rng <- range(rng)
        if (self$has_resource) {
          nc <- private$to_nc_indices(rng[1L], rng[2L] - rng[1L] + 1L)
          ax <- CFAxisVertical$new(private$.NCobj, group = group, start = nc$start,
                                   count = nc$count, attributes = self$attributes)
          if (nzchar(name))
            ax$name <- name
        } else {
          if (!nzchar(name))
            name <- self$name
          ax <- CFAxisVertical$new(name, group = group, values = self$values[rng[1L]:rng[2L]],
                                   attributes = self$attributes)
        }
        private$copy_properties_into(ax, rng)
      }
    },

    #' @description Subset the parametric terms of this axis.
    #' @param original_axis_names Character vector of names of the axes prior to
    #'   a modifying operation in the owning data variable
    #' @param new_axes List of `CFAxis` instances to use for the subsetting.
    #' @param start The indices to start reading data from the file, as an
    #'   integer vector at least as long as the number of axis for the term.
    #' @param count The number of values to read from the file, as an integer
    #'   vector at least as long as the number of axis for the term.
    #' @param aux Optional. List with the parameters for an auxiliary grid
    #'   transformation. Default is `NULL`.
    #' @param ZT_dim Optional. Dimensions of the non-grid axes when an auxiliary
    #'   grid transformation is specified.
    #' @return Self, invisibly. The parametric terms will have been subset in
    #'   this axis.
    subset_parametric_terms = function(original_axis_names, new_axes, start, count, aux = NULL, ZT_dim = NULL) {
      terms <- private$.terms
      if (is.null(terms)) return()

      params <- terms$param
      new_params <- vector("list", length(params))
      for (p in seq_along(params)) {
        if (is.null(params[[p]])) next
        new_params[[p]] <- params[[p]]$subset(original_axis_names, new_axes, start, count, aux, ZT_dim)
      }

      terms$param <- new_params
      self$set_parametric_terms(self$attribute("standard_name"), terms)
      invisible(self)
    },

    #' @description Create the GeoZarr coordinates for this vertical axis. If the
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
      vals <- self$values

      unit <- self$attribute("units")
      positive <- self$attribute("positive")
      dir <- if (is.na(positive)) "DOWN"
             else toupper(positive)

      # Attributes that are structural are managed by the convention used
      # so filter them out before writing. Leave a few that are descriptive of
      # the data
      atts <- private$zarr_attributes(c("axis", "bounds", "positive", "units"))

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

      # Irregular
      if (self$length > geozarr::geozarr_options()$max_explicit) {
        # Create a Zarr array for the axis coordinates if it does not already exist
        if (is.null(grp$children[[self$name]])) {
          ab <- zarr::array_builder$new()
          ab$shape <- len
          ab$data_type <- switch(storage.mode(vals),
                                 "double" = "float64",
                                 "integer" = "int32")
          ab$chunk_shape <- len
          if (len > zarr::zarr_options()$min_compress)
            ab$add_codec("blosc", list(clevel = 6L))
          new_array <- try(grp$add_array(self$name, ab), silent = TRUE)
          if (inherits(new_array, "try-error"))
            stop("Could not create Zarr array with name", self$name, call. = FALSE)
          new_array$write(vals)
        }
      }

      geozarr::Coordinates$new(self$name, dir, unit, vals, bnds)
    }
  ),
  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        if (is.null(private$.terms)) "Vertical axis"
        else "Vertical axis (parametric)"
    },

    #' @field formula_terms (read-only) A `data.frame` with the "formula_terms"
    #' to calculate the parametric axis values.
    formula_terms = function(value) {
      if (missing(value))
        private$.terms
    },

    #' @field is_parametric (read-only) Logical flag that indicates if the
    #'   coordinates of the axis are parametric.
    is_parametric = function(value) {
      if (missing(value))
        !is.na(self$attribute("formula_terms"))
    },

    #' @field parametric_coordinates (read-only) Retrieve the parametric
    #' coordinates of this vertical axis as a [CFVariable].
    parametric_coordinates = function(value) {
      if (missing(value))
        private$compute()
    },

    #' @field computed_name (read-only) The name of the computed parameterised
    #' coordinates. If the parameterised coordinates have not been computed yet
    #' the computed name is an empty string.
    computed_name = function(value) {
      if (missing(value)) {
        private$.name_computed
      }
    },

    #' @field computed_units (read-only) Return the units of the computed
    #' parameterised coordinates, if computed, otherwise return `NULL`. This
    #' will access the standard names table.
    computed_units = function(value) {
      if (missing(value)) {
        if (is.null(private$.computed_values))
          NULL
        else if (private$.name_computed == "non_standard_name")
          "unknown units"
        else
          CF$standard_names$find(private$.name_computed)$units
      }
    }
  )
)
