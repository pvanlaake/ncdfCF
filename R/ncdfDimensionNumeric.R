#' @include ncdfDimension.R
NULL

#' Numeric dimension class
#'
#' This class describes numeric dimensions in a netCDF resource.
#'
#' @slot values The values of the positions along the dimension.
#' @slot bounds The bounds of the dimension values, if any.
setClass("ncdfDimensionNumeric",
  contains = "ncdfDimension",
  slots = c(
    values     = "numeric",
    bounds     = "array"
  )
)

#' @rdname showObject
#' @export
#' @importFrom methods show
setMethod("show", "ncdfDimensionNumeric", function (object) {
  longname <- attribute(object, "long_name")
  if (!length(longname) || longname == object@name) longname <- ""
  cat(paste0("Dimension: [", object@id, "] ", object@name))
  if (longname == "") cat("\n") else cat(paste0(" | ", longname, "\n"))

  ax <- if (object@axis == "") "(unknown)" else object@axis
  cat("Axis     :", ax, "\n")

  len <- length(object@values)
  unlim <- if (object@unlim) "(unlimited)" else ""
  rng <- paste0(range(object@values), collapse = " ... ")
  units <- attribute(object, "units")
  if (!length(units)) units <- ""
  if (length(object@bounds)) {
    vals <- trimws(formatC(c(object@bounds[1L, 1L], object@bounds[2L, len]), digits = 8L))
    bndrng <- paste0(vals, collapse = " ... ")
  } else bndrng <- "(not set)"
  cat("Length   :", len, unlim, "\n")
  cat("Range    :", rng, units, "\n")
  cat("Bounds   :", bndrng, "\n")

  show_attributes(object)
})

#' @rdname showObject
#' @export
setMethod("brief", "ncdfDimensionNumeric", function (object) {
  longname <- attribute(object, "long_name")
  if (!length(longname) || longname == object@name) longname <- ""
  unlim <- if (object@unlim) "U" else ""

  nv <- length(object@values)
  if (nv == 1L)
    dims <- sprintf("[%s]", gsub(" ", "", formatC(object@values[1L], digits = 8L)))
  else {
    vals <- trimws(formatC(c(object@values[1], object@values[nv]), digits = 8L))
    dims <- sprintf("[%s ... %s]", vals[1L], vals[2L])
  }
  if (length(object@bounds)) {
    vals <- trimws(formatC(c(object@bounds[1L, 1L], object@bounds[2L, nv]), digits = 8L))
    bnds <- sprintf("[%s ... %s]", vals[1L], vals[2L])
  } else bnds <- ""

  data.frame(id = object@id, axis = object@axis, name = object@name, long_name = longname,
             length = nv, values = dims, unlim = unlim, bounds = bnds)
})

#' @rdname str
#' @export
setMethod("str", "ncdfDimensionNumeric", function(object, ...) {
  cat(object@name, ": Formal class 'ncdfDimensionNumeric' [package \"ncdfCF\"] with 10 slots\n")
  str_dimension(object)

  vals <- object@values
  nv <- length(vals)
  if (!nv)
    cat("  ..@ values    : num[0 (1d)]\n")
  else if (nv < 5L)
    cat(paste0("  ..@ values    : num [1:", nv, "] ",
               paste(vals, collapse = ", "), "\n"))
  else
    cat(paste0("  ..@ values    : num ", vals[1L], ", ", vals[2L], ", ..., ",
               vals[nv - 1L], ", ", vals[nv], "\n"))

  cat("  ..@ bounds    :"); str(object@bounds);

  str_attributes(object)
})

#' @rdname dimnames
#' @export
setMethod("dimnames", "ncdfDimensionNumeric", function (x) x@values)

#' @rdname has_bounds
#' @export
setMethod("has_bounds", "ncdfDimensionNumeric", function(x) {
  length(x@bounds) > 0L
})

#' @rdname indexOf
#' @export
setMethod("indexOf", c("numeric", "ncdfDimensionNumeric"), function (x, y, method = "constant") {
  if (length(y@bounds)) vals <- c(y@bounds[1L, 1L], y@bounds[2L, ])
  else vals <- y@values
  stats::approx(vals, 1L:length(vals), x, method = method, yleft = 0L, yright = .Machine$integer.max)$y
})
