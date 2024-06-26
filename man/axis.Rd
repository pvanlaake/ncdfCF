% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncdfDimension.R
\name{axis}
\alias{axis}
\alias{axis,ncdfDimension-method}
\title{Retrieve the axis of a dimension}
\usage{
axis(x)

\S4method{axis}{ncdfDimension}(x)
}
\arguments{
\item{x}{The \code{ncdfDimension} to query.}
}
\value{
A character to indicate which of axes "X", "Y", "Z", or "T" is
associated with the dimension, or \code{NA} if no axis is assigned to the
dimension.
}
\description{
This method retrieves the axis of the dimension.
}
\examples{
fn <- system.file("extdata",
                  "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
                  package = "ncdfCF")
ds <- open_ncdf(fn)
time <- ds[["time"]]
axis(time)
}
