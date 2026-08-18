#nocov start
# Create environment for the package
CF <- new.env(parent = emptyenv())
CF.options <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  assign("CFtypes", c("unknown", "data", "coordinate", "auxiliary_coordinate",
                      "scalar_coordinate", "boundary", "domain", "grid_mapping",
                      "cell_measure", "ancillary_data", "mesh_topology",
                      "location_index_set", "quantization",
                      "geometry_container"), envir = CF)
  assign("eps", 1e-05, envir = CF)
  assign("standard_names", CFStandardNames$new(), envir = CF)

  # The below variables are used to generate unique id's for CF objects.
  # When data sets or data arrays are written to file, new id's as reported by
  # the netCDF library are assigned. Don't use currentVarId directly, instead
  # use function newVarId().
  assign("currentVarId", 0L, envir = CF)
  assign("newVarId", function() {CF$currentVarId <- CF$currentVarId - 1L; CF$currentVarId}, envir = CF)

  # User-modifiable options
  assign("memory_cell_limit", 1e8, envir = CF.options)
  assign("digits", 6L, envir = CF.options)
  assign("cache_stale_days", 90, envir = CF.options)
}
#nocov end
