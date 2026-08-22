# Latitude CF axis object

This class represents a latitude axis. Its values are numeric. This
class adds some logic that is specific to latitudes, such as their
range, orientation and meaning.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
[`CFAxisNumeric`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.md)
-\> `CFAxisLatitude`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

## Methods

### Public methods

- [`CFAxisLatitude$new()`](#method-CFAxisLatitude-initialize)

- [`CFAxisLatitude$copy()`](#method-CFAxisLatitude-copy)

- [`CFAxisLatitude$copy_with_values()`](#method-CFAxisLatitude-copy_with_values)

- [`CFAxisLatitude$subset()`](#method-CFAxisLatitude-subset)

- [`CFAxisLatitude$append()`](#method-CFAxisLatitude-append)

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
- [`CFAxisNumeric$brief()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-brief)
- [`CFAxisNumeric$identical()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-identical)
- [`CFAxisNumeric$indexOf()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-indexOf)
- [`CFAxisNumeric$print()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-print)
- [`CFAxisNumeric$range()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-range)
- [`CFAxisNumeric$slice()`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.html#method-slice)

------------------------------------------------------------------------

### `CFAxisLatitude$new()`

Create a new instance of this class.

Creating a new latitude axis is more easily done with the
[`makeLatitudeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeLatitudeAxis.md)
function.

#### Usage

    CFAxisLatitude$new(
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

  Optional. The values of the axis in a vector. The values have to be
  numeric within the range (-90, 90) and monotonic. Ignored when
  argument `var` is a NCVariable object.

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

### `CFAxisLatitude$copy()`

Create a copy of this axis. The copy is completely separate from `self`,
meaning that both `self` and all of its components are made from new
instances.

#### Usage

    CFAxisLatitude$copy(name = "", group)

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

### `CFAxisLatitude$copy_with_values()`

Create a copy of this axis but using the supplied values. The attributes
are copied to the new axis. Boundary values and auxiliary coordinates
are not copied.

After this operation the attributes of the newly created axes may not be
accurate, except for the "actual_range" attribute. The calling code
should set, modify or delete attributes as appropriate.

#### Usage

    CFAxisLatitude$copy_with_values(name = "", group, values)

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

### `CFAxisLatitude$subset()`

Return a latitude axis spanning a smaller coordinate range. This method
returns an axis which spans the range of indices given by the `rng`
argument.

#### Usage

    CFAxisLatitude$subset(name = "", group, rng = NULL)

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

A new `CFAxisLatitude` instance covering the indicated range of indices.
If the value of the argument `rng` is `NULL`, return a copy of `self` as
the new axis.

------------------------------------------------------------------------

### `CFAxisLatitude$append()`

Append a vector of values at the end of the current values of the axis.
Boundary values are appended as well but if either this axis or the
`from` axis does not have boundary values, neither will the resulting
axis.

#### Usage

    CFAxisLatitude$append(from)

#### Arguments

- `from`:

  An instance of `CFAxisLatitude` whose values to append to the values
  of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisLatitude` instance with values from this axis and the
`from` axis appended.
