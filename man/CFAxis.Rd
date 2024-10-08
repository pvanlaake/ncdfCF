% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/CFAxis.R
\docType{class}
\name{CFAxis}
\alias{CFAxis}
\title{Find indices in the axis domain}
\description{
This class is a basic ancestor to all classes that represent CF
axes. More useful classes use this class as ancestor.
}
\details{
CF axis object

The fields in this class are common among all CF axis objects.
}
\section{Super class}{
\code{\link[ncdfCF:CFObject]{ncdfCF::CFObject}} -> \code{CFAxis}
}
\section{Public fields}{
\if{html}{\out{<div class="r6-fields">}}
\describe{
\item{\code{group}}{The \link{NCGroup} that this axis is located in.}

\item{\code{NCdim}}{The \link{NCDimension} that stores the netCDF dimension details.
This is \code{NULL} for \link{CFAxisScalar} instances.}

\item{\code{orientation}}{A character "X", "Y", "Z" or "T" to indicate the
orientation of the axis, or an empty string if not known or different.}

\item{\code{bounds}}{The boundary values of this axis, if set.
Create a basic CF axis object

Create a new CF axis instance from a dimension and a variable in a netCDF
resource. This method is called upon opening a netCDF resource by the
\code{initialize()} method of a descendant class suitable for the type of
axis.}
}
\if{html}{\out{</div>}}
}
\section{Active bindings}{
\if{html}{\out{<div class="r6-active-bindings">}}
\describe{
\item{\code{friendlyClassName}}{(read-only) A nice description of the class.}

\item{\code{dimid}}{The netCDF dimension id of this axis.}

\item{\code{length}}{The declared length of this axis.}
}
\if{html}{\out{</div>}}
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-CFAxis-new}{\code{CFAxis$new()}}
\item \href{#method-CFAxis-print}{\code{CFAxis$print()}}
\item \href{#method-CFAxis-brief}{\code{CFAxis$brief()}}
\item \href{#method-CFAxis-shard}{\code{CFAxis$shard()}}
\item \href{#method-CFAxis-time}{\code{CFAxis$time()}}
\item \href{#method-CFAxis-sub_axis}{\code{CFAxis$sub_axis()}}
\item \href{#method-CFAxis-indexOf}{\code{CFAxis$indexOf()}}
\item \href{#method-CFAxis-clone}{\code{CFAxis$clone()}}
}
}
\if{html}{\out{
<details open><summary>Inherited methods</summary>
<ul>
<li><span class="pkg-link" data-pkg="ncdfCF" data-topic="CFObject" data-id="attribute"><a href='../../ncdfCF/html/CFObject.html#method-CFObject-attribute'><code>ncdfCF::CFObject$attribute()</code></a></span></li>
<li><span class="pkg-link" data-pkg="ncdfCF" data-topic="CFObject" data-id="print_attributes"><a href='../../ncdfCF/html/CFObject.html#method-CFObject-print_attributes'><code>ncdfCF::CFObject$print_attributes()</code></a></span></li>
</ul>
</details>
}}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-new"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-new}{}}}
\subsection{Method \code{new()}}{
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$new(grp, nc_var, nc_dim, orientation)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{grp}}{The \link{NCGroup} that this axis is located in.}

\item{\code{nc_var}}{The \link{NCVariable} instance upon which this CF axis is
based.}

\item{\code{nc_dim}}{The \link{NCDimension} instance upon which this CF axis is
based.}

\item{\code{orientation}}{The orientation of the axis: "X", "Y", "Z" "T", or
"" when not known or relevant.}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
A basic CF object.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-print"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-print}{}}}
\subsection{Method \code{print()}}{
Summary of the axis

Prints a summary of the axis to the console. This method is typically
called by the \code{print()} method of descendant classes.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$print()}\if{html}{\out{</div>}}
}

}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-brief"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-brief}{}}}
\subsection{Method \code{brief()}}{
Some details of the axis
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$brief()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A 1-row \code{data.frame} with some details of the axis.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-shard"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-shard}{}}}
\subsection{Method \code{shard()}}{
Very concise information on the axis

The information returned by this function is very concise and most useful
when combined with similar information from other axes.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$shard()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
Character string with very basic axis information.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-time"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-time}{}}}
\subsection{Method \code{time()}}{
Return the \code{CFtime} instance that represents time

This method is only useful for \code{CFAxisTime} instances. This stub is here
to make the call to this method succeed with no result for the other axis
descendants.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$time()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
\code{NULL}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-sub_axis"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-sub_axis}{}}}
\subsection{Method \code{sub_axis()}}{
Return an axis spanning a smaller dimension range

This method is "virtual" in the sense that it does not do anything other
than return \code{NULL}. This stub is here to make the call to this method
succeed with no result for the other axis descendants that do not
implement this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$sub_axis(group, rng = NULL)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{group}}{The group to create the new axis in.}

\item{\code{rng}}{The range of values from this axis to include in the returned
axis. If the value of the argument is \code{NULL}, return the entire axis
(possibly as a scalar axis).}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
\code{NULL}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-indexOf"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-indexOf}{}}}
\subsection{Method \code{indexOf()}}{
Given a vector of numerical, timestamp or categorical values
\code{x}, find their indices in the values of the axis. With
\code{method = "constant"} this returns the index of the value lower than the
supplied values in \code{x}. With \code{method = "linear"} the return value
includes any fractional part.

If bounds are set on the numerical or time axis, the indices are taken
from those bounds. Returned indices may fall in between bounds if the
latter are not contiguous, with the exception of the extreme values in
\code{x}.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$indexOf(x, method = "constant")}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{x}}{Vector of numeric, timestamp or categorial values to find axis
indices for. The timestamps can be either character, POSIXct or Date
vectors. The type of the vector has to correspond to the type of the
axis.}

\item{\code{method}}{Single character value of "constant" or "linear".}
}
\if{html}{\out{</div>}}
}
\subsection{Returns}{
Numeric vector of the same length as \code{x}. If \code{method = "constant"},
return the index value for each match. If \code{method = "linear"}, return
the index value with any fractional value. Values of \code{x} outside of the
range of the values in the axis are returned as \code{0} and \code{.Machine$integer.max},
respectively.
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-CFAxis-clone"></a>}}
\if{latex}{\out{\hypertarget{method-CFAxis-clone}{}}}
\subsection{Method \code{clone()}}{
The objects of this class are cloneable with this method.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{CFAxis$clone(deep = FALSE)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{deep}}{Whether to make a deep clone.}
}
\if{html}{\out{</div>}}
}
}
}
