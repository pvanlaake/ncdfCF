% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncdfCF-package.R
\docType{package}
\name{ncdfCF-package}
\alias{ncdfCF}
\alias{ncdfCF-package}
\title{ncdfCF: Easy Access to NetCDF Files and Interpreting with CF Metadata Conventions}
\description{
Support for accessing and interpreting netCDF datasets in a familiar R style.
Built on top of the \href{https://cran.r-project.org/package=RNetCDF}{\code{RNetCDF} package},
built and maintained by the developers of the \code{netcdf} library, package
\code{ncdfCF} provides high-level access to netCDF resources. Resources are matched
against the
\href{https://cfconventions.org/}{Climate and Forecast (CF) Metadata Conventions}
for climate and forecasting data. The CF Metadata Conventions is widely used
for distributing files with climate observations or projections, including
the Coupled Model Intercomparison Project (CMIP) data used by climate change
scientists and the Intergovernmental Panel on Climate Change (IPCC). This
package currently supports axis determination, time interpretation with all
9 defined calendars, and use of bounds data.
}
\details{
Properties of the netCDF resource objects are easily examined using common
R commands. Access to the data in the variables can be had using similarly
known patterns.

\strong{Open, inquire}
\itemize{
\item \code{\link[=open_ncdf]{open_ncdf()}}: Open a netCDF resource, either in a local file system or on
a THREDDS server. Note that resources are automatically closed.
\item \code{\link[=show]{show()}}, \code{\link[=brief]{brief()}}, and \code{\link[=shard]{shard()}}: Print (increasingly more compact)
information to the console for a dataset, variable, or dimension.
\item \code{\link[=dimnames]{dimnames()}}: Vector of names of the dimensions in the dataset or variable,
or a vector of coordinate values for a dimension.
\item \code{\link[=dim]{dim()}}, \code{\link[=length]{length()}}: Vector of the dimension lengths for a dataset or
variable, or the length of a single dimension.
\item \code{\link[=axis]{axis()}}: The axis of the dimension.
\item \code{\link[=has_bounds]{has_bounds()}}: Does the dimension have bounds set?
\item \code{\link[=time]{time()}}: Return the \href{https://cran.r-project.org/web//packages//CFtime/index.html}{CFtime}
instance of the dimension, or \code{NULL} if not a time dimension.
}

\strong{Filtering and selection}
\itemize{
\item [\verb{[]}][bracket_select]: Select the entire variable or a part thereof
using index values.
\item \code{\link[=subset]{subset()}}: Select a subset from a variable by specifying extents in
real-world coordinates for the dimensions.
\item \code{\link[=indexOf]{indexOf()}}: Index values into the dimension from real-world coordinates,
possibly with fractional part for interpolation.
}
}
\author{
\strong{Maintainer}: Patrick Van Laake \email{patrick@vanlaake.net} [copyright holder]

}
\keyword{internal}
