# CF character axis object

This class represent CF axes that use categorical character labels as
coordinate values. Note that this is different from a
[CFLabel](https://r-cf.github.io/ncdfCF/reference/CFLabel.md), which is
associated with an axis but not an axis itself.

This is an extension to the CF Metadata Conventions. As per CF, axes are
required to have numerical values, which is relaxed here.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
`CFAxisCharacter`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `dimnames`:

  (read-only) The coordinates of the axis as a character vector.

## Methods

### Public methods

- [`CFAxisCharacter$new()`](#method-CFAxisCharacter-initialize)

- [`CFAxisCharacter$brief()`](#method-CFAxisCharacter-brief)

- [`CFAxisCharacter$copy()`](#method-CFAxisCharacter-copy)

- [`CFAxisCharacter$copy_with_values()`](#method-CFAxisCharacter-copy_with_values)

- [`CFAxisCharacter$slice()`](#method-CFAxisCharacter-slice)

- [`CFAxisCharacter$subset()`](#method-CFAxisCharacter-subset)

- [`CFAxisCharacter$identical()`](#method-CFAxisCharacter-identical)

- [`CFAxisCharacter$append()`](#method-CFAxisCharacter-append)

- [`CFAxisCharacter$indexOf()`](#method-CFAxisCharacter-indexOf)

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
- [`CFAxis$print()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-print)
- [`CFAxis$shard()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-shard)
- [`CFAxis$write()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-write)

------------------------------------------------------------------------

### `CFAxisCharacter$new()`

Create a new instance of this class.

Creating a new character axis is more easily done with the
[`makeCharacterAxis()`](https://r-cf.github.io/ncdfCF/reference/makeCharacterAxis.md)
function.

#### Usage

    CFAxisCharacter$new(
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

  Optional. The values of the axis in a vector. These must be character
  values. Ignored when argument `var` is a NCVariable object.

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

### `CFAxisCharacter$brief()`

Some details of the axis.

#### Usage

    CFAxisCharacter$brief()

#### Returns

A 1-row `data.frame` with some details of the axis.

------------------------------------------------------------------------

### `CFAxisCharacter$copy()`

Create a copy of this axis. The copy is completely separate from this
axis, meaning that the new axis and all of its components are made from
new instances. If this axis is backed by a netCDF resource, the copy
will retain the reference to the resource.

#### Usage

    CFAxisCharacter$copy(name = "", group)

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

### `CFAxisCharacter$copy_with_values()`

Create a copy of this axis but using the supplied values. The attributes
are copied to the new axis. Boundary values and auxiliary coordinates
are not copied.

After this operation the attributes of the newly created axes may not be
accurate, except for the "actual_range" attribute. The calling code
should set, modify or delete attributes as appropriate.

#### Usage

    CFAxisCharacter$copy_with_values(name = "", group, values)

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

### `CFAxisCharacter$slice()`

Given a range of domain coordinate values, returns the indices into the
axis that fall within the supplied range.

#### Usage

    CFAxisCharacter$slice(rng)

#### Arguments

- `rng`:

  A character vector whose extreme (alphabetic) values indicate the
  indices of coordinates to return.

#### Returns

An integer vector of length 2 with the lower and higher indices into the
axis that fall within the range of coordinates in argument `rng`.
Returns `NULL` if no values of the axis fall within the range of
coordinates.

------------------------------------------------------------------------

### `CFAxisCharacter$subset()`

Return an axis spanning a smaller coordinate range. This method returns
an axis which spans the range of indices given by the `rng` argument.

#### Usage

    CFAxisCharacter$subset(name = "", group, rng = NULL)

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

A new `CFAxisCharacter` instance covering the indicated range of
indices. If the value of the argument `rng` is `NULL`, return a copy of
this axis as the new axis.

------------------------------------------------------------------------

### `CFAxisCharacter$identical()`

Tests if the axis passed to this method is identical to `self`.

#### Usage

    CFAxisCharacter$identical(axis)

#### Arguments

- `axis`:

  The `CFAxisCharacter` instance to test.

#### Returns

`TRUE` if the two axes are identical, `FALSE` if not.

------------------------------------------------------------------------

### `CFAxisCharacter$append()`

Append a vector of values at the end of the current values of the axis.

#### Usage

    CFAxisCharacter$append(from, group)

#### Arguments

- `from`:

  An instance of `CFAxisCharacter` whose values to append to the values
  of `self`.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisCharacter` instance with values from `self` and the `from`
axis appended.

------------------------------------------------------------------------

### `CFAxisCharacter$indexOf()`

Find indices in the axis domain. Given a vector of character strings
`x`, find their indices in the coordinates of the axis.

#### Usage

    CFAxisCharacter$indexOf(x, method = "constant", rightmost.closed = TRUE)

#### Arguments

- `x`:

  Vector of character strings to find axis indices for.

- `method`:

  Ignored.

- `rightmost.closed`:

  Ignored.

#### Returns

Numeric vector of the same length as `x`. Values of `x` that are not
equal to a coordinate of the axis are returned as `NA`.
