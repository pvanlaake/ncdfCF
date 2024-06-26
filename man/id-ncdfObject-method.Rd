% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncdfObject.R
\name{id,ncdfObject-method}
\alias{id,ncdfObject-method}
\title{Retrieve the id of an ncdfCF object}
\usage{
\S4method{id}{ncdfObject}(object)
}
\arguments{
\item{object}{The object whose id to retrieve.}
}
\value{
The integer id of the object.
}
\description{
Retrieve the id of an ncdfCF object
}
\examples{
fn <- system.file("extdata",
                  "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
                  package = "ncdfCF")
ds <- open_ncdf(fn)
id(ds[["lon"]])
}
