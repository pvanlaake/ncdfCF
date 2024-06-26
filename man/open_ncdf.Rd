% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncdfDataset.R
\name{open_ncdf}
\alias{open_ncdf}
\title{Read a netCDF resource}
\usage{
open_ncdf(resource, keep_open = FALSE)
}
\arguments{
\item{resource}{The name of the netCDF resource to open, either a local file
name or a remote URI.}

\item{keep_open}{Logical flag to indicate if the netCDF resource has to
remain open after reading the metadata. This should be enabled typically
only for programmatic access or when a remote resource has an expensive
access protocol (i.e. 2FA). The resource has to be explicitly closed with
\code{close()} after use. Note that when a dataset is opened with
\code{keep_open = TRUE} the resource may still be closed by the operating system
or the remote server.}
}
\value{
An \code{ncdfDataset} instance, or an error if the resource was not found
or errored upon reading.
}
\description{
Read a netCDF resource
}
\examples{
fn <- system.file("extdata",
  "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20240101-20241231_vncdfCF.nc",
  package = "ncdfCF")
ds <- open_ncdf(fn)
ds
}
