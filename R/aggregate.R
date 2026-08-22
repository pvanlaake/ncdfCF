#' Aggregate multiple CF files into GeoZarr arrays
#'
#' NetCDF files have file size limitations, leading to large data sets being
#' split up into multiple files, usually over the temporal dimension. This is
#' very typical in climate projection data sets: a typical CMIP6 run over the
#' period 2015-2100 at daily resolution is broken into 3 to 7 separate files for
#' each parameter, making data extractions across the temporal boundaries
#' cumbersome. Zarr does not have that same limitation: large data sets are
#' broken up into "chunks", each being stored as a file when the store is on a
#' local file system, but this is transparent to the user of the data. A full
#' CMIP6 run of any parameter can be stored and manipulated in a single GeoZarr
#' array.
#'
#' This function will take a set of CF-encoded netCDF files and aggregate the
#' variables of interest into corresponding arrays in a Zarr store. The
#' aggregation can take place over multiple axes simultaneously. This may
#' include length-1 axes that are scalar, i.e. not present in the dimensions of
#' the underlying data variable. Any missing data from missing files in the list
#' will have uninitialised data that does not affect the functioning of the
#' array.
#'
#' Axes of all same-named variables have to be coincident (having the same
#' length, class, values and unit) or compatible (same class and unit) and
#' non-overlapping, otherwise an error will be thrown. Aggregation will take
#' place over the compatible axis/axes.
#'
#' This function makes a best effort. If the list of files provided is sensible,
#' so will be the result. Otherwise, all bets are off.
#' @param cf A `list` of fully-qualified URIs to CF files to aggregate. All
#'   files in the list have to be of the same "type" for the aggregation to make
#'   sense. The list does not have to be in order.
#' @param zarr A `zarr` object that is writable. It cannot already have arrays
#'   that are names in argument `var_map`.
#' @param var_map Optional. A `list` with named elements. The names correspond
#'   to the variables in the `cf` files that will be aggregated. The element
#'   value is a character string indicating the absolute path to the array in
#'   `zarr` to be created for the variable. If omitted or `NULL` (the default),
#'   all variables are taken from all `cf` files and converted to Zarr arrays
#'   under that name in the root group of the `zarr` object.
#' @param chunking Optional. Named `vector` or `list`, with numeric values
#'   giving the relative weights of each axis in the chunking - higher values
#'   favour data extraction over that axis. If a `vector`, the names correspond
#'   to the names of the axes of the variables to aggregegate - any non-named
#'   axes will be assigned a value of 1. If a `list`, the names refer to the
#'   variables and the elements are each a list with names for the axes of that
#'   variable and values giving the chunking weights for that axis - any
#'   non-named axes will be assigned a value of 1 for that variable. If omitted
#'   or `NULL` (default), all axes will have equal weight in the chunking.
#' @return The `zarr` object with the variables included.
#' @export
#' @examples
#' \dontrun{
#' pr <- list.files(pattern = '^pr.*\\.nc$', full.names = TRUE)
#' z <- zarr::create_zarr()
#' z <- aggregate_geozarr(cf = pr, zarr = z)
#' }
aggregate_geozarr <- function(cf, zarr, var_map = NULL, chunking = NULL) {
  # Work in progress
}
