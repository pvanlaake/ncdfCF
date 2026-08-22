# Numeric CF axis object

This class represents a numeric axis. Its values are numeric. This class
is used for axes with numeric values but without further knowledge of
their nature. More specific classes descend from this class.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
`CFAxisNumeric`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `dimnames`:

  (read-only) The coordinates of the axis as a vector. These are by
  default the values of the axis, but it could also be a set of
  auxiliary coordinates, if they have been set.

## Methods

### Public methods

- [`CFAxisNumeric$new()`](#method-CFAxisNumeric-initialize)

- [`CFAxisNumeric$print()`](#method-CFAxisNumeric-print)

- [`CFAxisNumeric$brief()`](#method-CFAxisNumeric-brief)

- [`CFAxisNumeric$range()`](#method-CFAxisNumeric-range)

- [`CFAxisNumeric$indexOf()`](#method-CFAxisNumeric-indexOf)

- [`CFAxisNumeric$slice()`](#method-CFAxisNumeric-slice)

- [`CFAxisNumeric$copy()`](#method-CFAxisNumeric-copy)

- [`CFAxisNumeric$copy_with_values()`](#method-CFAxisNumeric-copy_with_values)

- [`CFAxisNumeric$identical()`](#method-CFAxisNumeric-identical)

- [`CFAxisNumeric$append()`](#method-CFAxisNumeric-append)

- [`CFAxisNumeric$subset()`](#method-CFAxisNumeric-subset)

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
- [`CFAxis$geozarr_coordinates()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-geozarr_coordinates)
- [`CFAxis$peek()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-peek)
- [`CFAxis$shard()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-shard)
- [`CFAxis$write()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-write)

------------------------------------------------------------------------

### `CFAxisNumeric$new()`

Create a new instance of this class.

Creating a new axis is more easily done with the
[`makeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeAxis.md)
function.

#### Usage

    CFAxisNumeric$new(
      var,
      group,
      values,
      start = 1L,
      count = NA,
      orientation = "",
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

  Optional. The values of the axis in a vector. The values have to be
  numeric with the maximum value no larger than the minimum value + 360,
  and monotonic. Ignored when argument `var` is a `NCVariable` object.

- `start`:

  Optional. Integer index where to start reading axis data from file.
  The index may be `NA` to start reading data from the start.

- `count`:

  Optional. Number of elements to read from file. This may be `NA` to
  read to the end of the data.

- `orientation`:

  Optional. The orientation of the axis: "X", "Y", "Z" "T", or ""
  (default) when not known or relevant.

- `attributes`:

  Optional. A `data.frame` with the attributes of the axis. When an
  empty `data.frame` (default) and argument `var` is an `NCVariable`
  instance, attributes of the axis will be taken from the netCDF
  resource.

------------------------------------------------------------------------

### `CFAxisNumeric$print()`

Summary of the axis printed to the console.

#### Usage

    CFAxisNumeric$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

#### Returns

`self`, invisibly.

------------------------------------------------------------------------

### `CFAxisNumeric$brief()`

Some details of the axis.

#### Usage

    CFAxisNumeric$brief()

#### Returns

A 1-row `data.frame` with some details of the axis.

------------------------------------------------------------------------

### `CFAxisNumeric$range()`

Retrieve the range of coordinate values in the axis.

#### Usage

    CFAxisNumeric$range()

#### Returns

A numeric vector with two elements with the minimum and maximum values
in the axis, respectively.

------------------------------------------------------------------------

### `CFAxisNumeric$indexOf()`

Retrieve the indices of supplied coordinates on the axis. If the axis
has boundary values then the supplied coordinates must fall within the
boundaries of an axis coordinate to be considered valid.

#### Usage

    CFAxisNumeric$indexOf(x, method = "constant", rightmost.closed = TRUE)

#### Arguments

- `x`:

  A numeric vector of coordinates whose indices into the axis to
  extract.

- `method`:

  Extract index values without ("constant", the default) or with
  ("linear") fractional parts.

- `rightmost.closed`:

  Whether or not to include the upper limit. This parameter is ignored
  for this class, it always is `TRUE`.

#### Returns

A vector giving the indices in `x` of valid coordinates provided. Values
of `x` outside of the range of the coordinates in the axis are returned
as `NA`. If the axis has boundary values, then values of `x` that do not
fall on or between the boundaries of an axis coordinate are returned as
`NA`.

------------------------------------------------------------------------

### `CFAxisNumeric$slice()`

Given a range of domain coordinate values, returns the indices into the
axis that fall within the supplied range. If the axis has bounds, any
coordinate whose boundary values fall entirely or partially within the
supplied range will be included in the result.

#### Usage

    CFAxisNumeric$slice(rng)

#### Arguments

- `rng`:

  A numeric vector whose extreme values indicate the indices of
  coordinates to return.

#### Returns

An integer vector of length 2 with the lower and higher indices into the
axis that fall within the range of coordinates in argument `rng`.
Returns `NULL` if no (boundary) values of the axis fall within the range
of coordinates.

------------------------------------------------------------------------

### `CFAxisNumeric$copy()`

Create a copy of this axis. The copy is completely separate from `self`,
meaning that both `self` and all of its components are made from new
instances.

#### Usage

    CFAxisNumeric$copy(name = "", group)

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

### `CFAxisNumeric$copy_with_values()`

Create a copy of this axis but using the supplied values. The attributes
are copied to the new axis. Boundary values and auxiliary coordinates
are not copied.

After this operation the attributes of the newly created axes may not be
accurate, except for the "actual_range" attribute. The calling code
should set, modify or delete attributes as appropriate.

#### Usage

    CFAxisNumeric$copy_with_values(name = "", group, values)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed, will use the
  name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

- `values`:

  The values to the used with the copy of this axis.

#### Returns

The newly created axis.

------------------------------------------------------------------------

### `CFAxisNumeric$identical()`

Tests if the axis passed to this method is identical to `self`.

#### Usage

    CFAxisNumeric$identical(axis)

#### Arguments

- `axis`:

  The `CFAxisNumeric` or sub-class instance to test.

#### Returns

`TRUE` if the two axes are identical, `FALSE` if not.

------------------------------------------------------------------------

### `CFAxisNumeric$append()`

Append a vector of values at the end of the current values of the axis.
Boundary values are appended as well but if either this axis or the
`from` axis does not have boundary values, neither will the resulting
axis.

#### Usage

    CFAxisNumeric$append(from, group)

#### Arguments

- `from`:

  An instance of `CFAxisNumeric` whose values to append to the values of
  this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisNumeric` instance with values from this axis and the `from`
axis appended.

------------------------------------------------------------------------

### `CFAxisNumeric$subset()`

Return an axis spanning a smaller coordinate range. This method returns
an axis which spans the range of indices given by the `rng` argument.

#### Usage

    CFAxisNumeric$subset(name = "", group, rng = NULL)

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

A new `CFAxisNumeric` instance covering the indicated range of indices.
If the value of the argument `rng` is `NULL`, return a copy of this axis
as the new axis.
