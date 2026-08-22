# Time axis object

This class represents a time axis. The functionality is provided by the
`CFTime` class in the `CFtime` package.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
`CFAxisTime`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `time`:

  (read-only) Retrieve the `CFTime` instance that manages the values of
  this axis.

- `dimnames`:

  (read-only) The coordinates of the axis as a character vector.

## Methods

### Public methods

- [`CFAxisTime$new()`](#method-CFAxisTime-initialize)

- [`CFAxisTime$print()`](#method-CFAxisTime-print)

- [`CFAxisTime$brief()`](#method-CFAxisTime-brief)

- [`CFAxisTime$identical()`](#method-CFAxisTime-identical)

- [`CFAxisTime$copy()`](#method-CFAxisTime-copy)

- [`CFAxisTime$copy_with_values()`](#method-CFAxisTime-copy_with_values)

- [`CFAxisTime$append()`](#method-CFAxisTime-append)

- [`CFAxisTime$indexOf()`](#method-CFAxisTime-indexOf)

- [`CFAxisTime$slice()`](#method-CFAxisTime-slice)

- [`CFAxisTime$subset()`](#method-CFAxisTime-subset)

- [`CFAxisTime$geozarr_coordinates()`](#method-CFAxisTime-geozarr_coordinates)

Inherited methods

- [`CFObject$append_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-append_attribute)
- [`CFObject$attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-attribute)
- [`CFObject$attributes_identical()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-attributes_identical)
- [`CFObject$delete_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-delete_attribute)
- [`CFObject$print_attributes()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-print_attributes)
- [`CFObject$set_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-set_attribute)
- [`CFObject$write_attributes()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-write_attributes)
- [`CFData$dim()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-dim)
- [`CFData$read_chunk()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-read_chunk)
- [`CFData$read_data()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-read_data)
- [`CFAxis$attach_to_group()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-attach_to_group)
- [`CFAxis$can_append()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-can_append)
- [`CFAxis$configure_terms()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-configure_terms)
- [`CFAxis$copy_terms()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-copy_terms)
- [`CFAxis$detach()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-detach)
- [`CFAxis$geozarr_axis()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-geozarr_axis)
- [`CFAxis$peek()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-peek)
- [`CFAxis$shard()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-shard)
- [`CFAxis$write()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-write)

------------------------------------------------------------------------

### `CFAxisTime$new()`

Create a new instance of this class, including its boundary values. A
`CFTime` or `CFClimatology` instance will also be created to manage the
time magic.

Creating a new time axis is more easily done with the
[`makeTimeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeTimeAxis.md)
function.

#### Usage

    CFAxisTime$new(
      var,
      group,
      values,
      start = 1L,
      count = NA,
      attributes = data.frame()
    )

#### Arguments

- `var`:

  The name of the axis when creating a new axis. When reading an axis
  from file, the
  [NCVariable](https://r-cf.github.io/ncdfCF/reference/NCVariable.md)
  object that describes this instance.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) that
  this instance will live in.

- `values`:

  Either the numeric values of this axis, in which case argument `var`
  must be a `NCVariable`, or an instance of `CFTime` or `CFClimatology`
  with bounds set, and then argument `var` must be a name for the axis.

- `start`:

  Optional. Integer index where to start reading axis data from file.
  The index may be `NA` to start reading data from the start.

- `count`:

  Optional. Number of elements to read from file. This may be `NA` to
  read to the end of the data.

- `attributes`:

  Optional. A `data.frame` with the attributes of the axis. When an
  empty `data.frame` (default) and argument `var` is an NCVariable
  instance, attributes of the axis will be taken from the netCDF
  resource.

------------------------------------------------------------------------

### `CFAxisTime$print()`

Summary of the time axis printed to the console.

#### Usage

    CFAxisTime$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

------------------------------------------------------------------------

### `CFAxisTime$brief()`

Some details of the axis.

#### Usage

    CFAxisTime$brief()

#### Returns

A 1-row `data.frame` with some details of the axis.

------------------------------------------------------------------------

### `CFAxisTime$identical()`

Tests if the axis passed to this method is identical to `self`.

#### Usage

    CFAxisTime$identical(axis)

#### Arguments

- `axis`:

  The `CFAxisTime` instance to test.

#### Returns

`TRUE` if the two axes are identical, `FALSE` if not.

------------------------------------------------------------------------

### `CFAxisTime$copy()`

Create a copy of this axis. The copy is completely separate from `self`,
meaning that both `self` and all of its components are made from new
instances.

#### Usage

    CFAxisTime$copy(name = "", group)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed, will use the
  name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

The newly created axis.

------------------------------------------------------------------------

### `CFAxisTime$copy_with_values()`

Create a copy of this axis but using the supplied values. The attributes
are copied to the new axis. Boundary values and auxiliary coordinates
are not copied.

After this operation the attributes of the newly created axes may not be
accurate, except for the "actual_range" attribute. The calling code
should set, modify or delete attributes as appropriate.

#### Usage

    CFAxisTime$copy_with_values(name = "", group, values)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed, will use the
  name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

- `values`:

  The values to the used with the copy of this axis. This can be a
  `CFTime` instance, a vector of numeric values, a vector of character
  timestamps in ISO8601 or UDUNITS format, or a vector of `POSIXct` or
  `Date` values. If not a `CFTime` instance, the `values` will be
  converted into a `CFTime` instance using the definition and calendar
  of this axis.

#### Returns

The newly created axis.

------------------------------------------------------------------------

### `CFAxisTime$append()`

Append a vector of time values at the end of the current values of the
axis.

#### Usage

    CFAxisTime$append(from, group)

#### Arguments

- `from`:

  An instance of `CFAxisTime` whose values to append to the values of
  this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisTime` instance with values from this axis and the `from`
axis appended.

------------------------------------------------------------------------

### `CFAxisTime$indexOf()`

Retrieve the indices of supplied values on the time axis.

#### Usage

    CFAxisTime$indexOf(x, method = "constant", rightmost.closed = FALSE)

#### Arguments

- `x`:

  A vector of timestamps whose indices into the time axis to extract.

- `method`:

  Extract index values without ("constant", the default) or with
  ("linear") fractional parts.

- `rightmost.closed`:

  Whether or not to include the upper limit. Default is `FALSE`.

#### Returns

A vector giving the indices in the time axis of valid values in `x`, or
`NA` if the value is not valid.

------------------------------------------------------------------------

### `CFAxisTime$slice()`

Retrieve the indices of the time axis falling between two extreme
values.

#### Usage

    CFAxisTime$slice(x, rightmost.closed = FALSE)

#### Arguments

- `x`:

  A vector of two timestamps in between of which all indices into the
  time axis to extract.

- `rightmost.closed`:

  Whether or not to include the upper limit. Default is `FALSE`.

#### Returns

An integer vector giving the indices in the time axis between values in
`x`, or `NULL` if none of the values are valid.

------------------------------------------------------------------------

### `CFAxisTime$subset()`

Return an axis spanning a smaller coordinate range. This method returns
an axis which spans the range of indices given by the `rng` argument.

#### Usage

    CFAxisTime$subset(name = "", group, rng = NULL)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed (default),
  will use the name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

- `rng`:

  The range of indices whose values from this axis to include in the
  returned axis. If the value of the argument is `NULL`, return a copy
  of the axis.

#### Returns

A new `CFAxisTime` instance covering the indicated range of indices. If
the value of the argument `rng` is `NULL`, return a copy of `self` as
the new axis.

------------------------------------------------------------------------

### `CFAxisTime$geozarr_coordinates()`

Create the GeoZarr coordinates for this time axis. If the coordinate
values are not regular and longer than a set minimum, write the
coordinates to the group as a new Zarr array if it does not yet exist.
This will also include boundary values.

#### Usage

    CFAxisTime$geozarr_coordinates(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` where the coordinates will be located in
  the Zarr store. The coordinates will be written to a new Zarr array
  with the name based on the axis name if it is irregular and long.

#### Returns

An instance of
[geozarr::CoordinatesTime](https://rdrr.io/pkg/geozarr/man/CoordinatesTime.html).
