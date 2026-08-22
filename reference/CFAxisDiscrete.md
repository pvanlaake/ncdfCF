# CF discrete axis object

This class represent discrete CF axes, i.e. those axes whose coordinate
values do not represent a physical property. The coordinate values are
ordinal values equal to the index into the axis.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
`CFAxisDiscrete`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `dimnames`:

  (read-only) The coordinates of the axis as an integer vector, or
  labels for every axis element if they have been set.

## Methods

### Public methods

- [`CFAxisDiscrete$new()`](#method-CFAxisDiscrete-initialize)

- [`CFAxisDiscrete$print()`](#method-CFAxisDiscrete-print)

- [`CFAxisDiscrete$brief()`](#method-CFAxisDiscrete-brief)

- [`CFAxisDiscrete$copy()`](#method-CFAxisDiscrete-copy)

- [`CFAxisDiscrete$indexOf()`](#method-CFAxisDiscrete-indexOf)

- [`CFAxisDiscrete$slice()`](#method-CFAxisDiscrete-slice)

- [`CFAxisDiscrete$subset()`](#method-CFAxisDiscrete-subset)

- [`CFAxisDiscrete$append()`](#method-CFAxisDiscrete-append)

- [`CFAxisDiscrete$write()`](#method-CFAxisDiscrete-write)

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
- [`CFAxis$copy_with_values()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-copy_with_values)
- [`CFAxis$detach()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-detach)
- [`CFAxis$geozarr_axis()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-geozarr_axis)
- [`CFAxis$geozarr_coordinates()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-geozarr_coordinates)
- [`CFAxis$identical()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-identical)
- [`CFAxis$peek()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-peek)
- [`CFAxis$shard()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-shard)

------------------------------------------------------------------------

### `CFAxisDiscrete$new()`

Create a new instance of this class. The values of this axis are always
a sequence, but the sequence may start with any positive value such that
the length of this instance falls within the length of the axis on file,
if there is one.

Creating a new discrete axis is more easily done with the
[`makeDiscreteAxis()`](https://r-cf.github.io/ncdfCF/reference/makeDiscreteAxis.md)
function.

#### Usage

    CFAxisDiscrete$new(var, group, start = 1L, count)

#### Arguments

- `var`:

  The name of the axis when creating a new axis. When reading an axis
  from file, the
  [NCVariable](https://r-cf.github.io/ncdfCF/reference/NCVariable.md)
  object that describes this instance.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) that
  this instance will live in.

- `start`:

  Optional. Integer value that indicates the starting value of this
  axis. Defults to `1L`.

- `count`:

  Number of elements in the axis.

------------------------------------------------------------------------

### `CFAxisDiscrete$print()`

Summary of the axis printed to the console.

#### Usage

    CFAxisDiscrete$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

#### Returns

`self`, invisibly.

------------------------------------------------------------------------

### `CFAxisDiscrete$brief()`

Some details of the axis.

#### Usage

    CFAxisDiscrete$brief()

#### Returns

A 1-row `data.frame` with some details of the axis.

------------------------------------------------------------------------

### `CFAxisDiscrete$copy()`

Create a copy of this axis. The copy is completely separate from this
axis, meaning that both this axis and all of its components are made
from new instances.

#### Usage

    CFAxisDiscrete$copy(name = "", group)

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

### `CFAxisDiscrete$indexOf()`

Find indices in the axis domain. Given a vector of numerical values `x`,
find their indices in the values of the axis. Outside values will be
dropped.

#### Usage

    CFAxisDiscrete$indexOf(x, method = "constant", rightmost.closed = TRUE)

#### Arguments

- `x`:

  Vector of numeric values to find axis indices for.

- `method`:

  Ignored.

- `rightmost.closed`:

  Ignored.

#### Returns

Numeric vector of the same length as `x`. Values of `x` outside of the
range of the values in the axis are returned as `NA`.

------------------------------------------------------------------------

### `CFAxisDiscrete$slice()`

Given a range of coordinate values, returns the indices into the axis
that fall within the supplied range. If the axis has auxiliary
coordinates selected then these will be used for the identification of
the indices to return.

#### Usage

    CFAxisDiscrete$slice(rng)

#### Arguments

- `rng`:

  A vector whose extreme values indicate the indices of coordinates to
  return. The mode of the vector has to be integer or agree with any
  auxiliary coordinates selected.

#### Returns

An integer vector of length 2 with the lower and higher indices into the
axis that fall within the range of coordinates in argument `rng`.
Returns `NULL` if no (boundary) values of the axis fall within the range
of coordinates.

------------------------------------------------------------------------

### `CFAxisDiscrete$subset()`

Return an axis spanning a smaller coordinate range. This method returns
an axis which spans the range of indices given by the `rng` argument.

#### Usage

    CFAxisDiscrete$subset(name = "", group, rng = NULL)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed, will use the
  name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

- `rng`:

  The range of indices whose values from this axis to include in the
  returned axis. If the value of the argument is `NULL`, return a copy
  of the axis.

#### Returns

A new `CFAxisDiscrete` instance covering the indicated range of indices.
If the value of the argument is `NULL`, return a copy of `self` as the
new axis.

------------------------------------------------------------------------

### `CFAxisDiscrete$append()`

Append a vector of values at the end of the current values of the axis.

#### Usage

    CFAxisDiscrete$append(from)

#### Arguments

- `from`:

  An instance of `CFAxisDiscrete` whose length to add to this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisDiscrete` instance with a length that is the sum of the
lengths of this axis and the `from` axis.

------------------------------------------------------------------------

### `CFAxisDiscrete$write()`

Write the axis to a netCDF file. A discrete axis does not have any
attributes or values to write.

#### Usage

    CFAxisDiscrete$write()

#### Returns

Self, invisibly.
