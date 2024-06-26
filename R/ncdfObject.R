#' @include ncdfResource.R
NULL

#' Ancestor of all netCDF objects.
#'
#' This is a virtual class that is the ancestor of other ncdfCF classes. Slots
#' 'id' and 'name' are populated in the descending classes.
#'
#' @slot id Identifier of the netCDF object.
#' @slot name Name of the netCDF object.
#' @slot attributes A data.frame holding all attributes of the object.
setClass("ncdfObject",
  contains = "VIRTUAL",
  slots = c(
    id         = "integer",
    name       = "character",
    attributes = "data.frame"
  ),
  prototype = list(
    id         = -1L,
    name       = "",
    attributes = data.frame()
  )
)

#' @name showObject
#' @title Summary of object details
#'
#' @description These methods provide information on the various `ncdfCF`
#'   objects. While the individual methods are generally behaving the same for
#'   all descendant classes, there are some differences related to the nature of
#'   the objects.
#'
#' * Method `show()` will provide many details of the object over multiple
#'   lines printed to the console. This includes all attributes so it could be a
#'   substantive amount of information.
#' * Method `brief()` returns some details of the object in a 1-row `data.frame`
#'   for further processing, such as combining details from all variables of a
#'   dataset into a single table.
#' * Method `shard()` returns a very short character string with some identifying
#'   properties of the object, typically only useful when combined with shards
#'   of other object to provide a succinct overview of the dataset. This method
#'   has limited usability for the user but may be of interest for programmatic
#'   access.
#'
#' @param object The `ncdfObject` to show.
#'
#' @returns `show()` prints information to the console. `brief()` returns a
#'   1-row `data.frame` with some details of `object`. `shard()` returns a
#'   character string with a few identifying details of `object`.
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#'
#' # ncdfDataset, show
#' ds
#'
#' # ncdfDataset, brief
#' # Note that the variables and dimensions are described by shards
#' brief(ds)
#'
#' # ncdfVariable, show
#' pev <- ds[["pev"]]
#' pev
#'
#' # ncdfDimensionNumeric, shard
#' lon <- ds[["longitude"]]
#' shard(lon)
NULL

#' @rdname showObject
#' @export
setGeneric("shard", function(object) standardGeneric("shard"), signature = "object")

#' @rdname showObject
#' @export
setGeneric("brief", function(object) standardGeneric("brief"), signature = "object")

#' `str` for `ncdfCF` objects
#'
#' `ncdfObject`s have references back to their parent objects, specifically
#' `ncdfDataset` and `ncdfGroup`. These circular references lead to very bulky
#' displays of the structure of the object being examined when using the base R
#' version of `str()`. This package-specific version puts a short-circuit for
#' parent references, making the display more manageable, including in the
#' Environment pane of RStudio when in an interactive session.
#'
#' @param object The `ncdfObject` that the method operates on. This includes
#' datasets, variables, dimensions, and possible others including instances
#' of descendant classes.
#' @param ... Ignored.
#' @returns Character vector that describes the structure of the object.
#'
#' @name str
#' @export
#' @examples
#' fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' str(ds)
setGeneric("str", function(object, ...) standardGeneric("str"), signature = "object")

#' Generics for `ncdfCF` objects
#'
#' These are generic method definitions with implementations in descendant
#' classes. Please see the help topics for the descendant classes.
#'
#' @param object The `ncdfCF` object that the method operates on. This includes
#' datasets, variables, dimensions, and possible others including instances
#' of descendant classes.
#' @param ... Passed on to underlying functions.
#' @returns Various. Please see the documentation of the methods in descendant
#' classes.
#'
#' @name ncdfGenerics
NULL

#' @rdname ncdfGenerics
#' @export
setGeneric("id", function(object) standardGeneric("id"), signature = "object")

#' @rdname ncdfGenerics
#' @export
setGeneric("name", function(object) standardGeneric("name"), signature = "object")

#' @rdname ncdfGenerics
#' @param att Name of the attribute to look up.
#' @param field One of "type", "length" or "value" (default)
#' @export
setGeneric("attribute", function(object, att, field = "value") standardGeneric("attribute"), signature = "object")

#' @rdname ncdfGenerics
#' @export
setGeneric("show_attributes", function(object, ...) standardGeneric("show_attributes"), signature = "object")

#' Print the attributes of the object to the console
#'
#' @param object `ncdfObject` whose attributes to print.
#' @param ... Passed on to underlying functions.
#'
#' @returns Nothing.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' show_attributes(ds[["pr"]])
setMethod("show_attributes", "ncdfObject", function(object, ...) {
  if (nrow(object@attributes)) {
    cat("\nAttributes:\n")
    print(.slim.data.frame(object@attributes, ...), right = FALSE, row.names = FALSE)
  }
})

#' Retrieve the id of an ncdfCF object
#'
#' @param object The object whose id to retrieve.
#'
#' @returns The integer id of the object.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' id(ds[["lon"]])
setMethod("id", "ncdfObject", function(object) object@id)

#' Retrieve the name of an ncdfCF object
#'
#' @param object The object whose name to retrieve.
#'
#' @returns A character string of the name of the object.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' name(ds[["lon"]])
setMethod("name", "ncdfObject", function(object) object@name)

#' Get an attribute value
#'
#' Extract the value of the field of a named attribute of the ncdfCF object.
#' When found, the value may be of type list if the attribute has multiple
#' values.
#'
#' @param object A `ncdfObject` instance.
#' @param att Attribute to find in $name column.
#' @param field The field to extract, either "value" (default), "type" or
#' "length".
#'
#' @returns Value of the `field` column or `character(0)` when not found.
#' @export
#' @examples
#' fn <- system.file("extdata",
#'                   "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
#'                   package = "ncdfCF")
#' ds <- open_ncdf(fn)
#' lon <- ds[["lon"]]
#' attribute(lon, "standard_name")
setMethod("attribute", "ncdfObject", function(object, att, field = "value") {
  atts <- object@attributes
  if (!nrow(atts)) return(character(0L))
  val <- atts[which(atts$name == att), field]
  if (is.list(val)) {
    val <- paste0(val, collapse = ", ")
    if (val == "") val <- character(0L)
  }
  val
})

#' `str()` object attributes
#' @noRd
str_attributes <- function(object, ...) {
  natts <- length(object@attributes)
  if (!natts) cat("  ..@ attributes: data.frame()\n")
  else {
    atts <- trimws(utils::capture.output(str(object@attributes)))
    cat("  ..@ attributes: ", atts[1L], "\n")
    atts <- atts[-1L]
    invisible(lapply(atts, function (a) cat(paste0("  .. ..", a, "\n"))))
  }
}
