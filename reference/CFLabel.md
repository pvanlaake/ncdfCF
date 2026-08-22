# CF label object

This class represent CF labels, i.e. a variable of character type that
provides a textual label for a discrete or general numeric axis. See
also
[CFAxisCharacter](https://r-cf.github.io/ncdfCF/reference/CFAxisCharacter.md),
which is an axis with character labels.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
`CFLabel`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `values`:

  Set or retrieve the labels of this object. In general you should use
  the `coordinates` field rather than this one. Upon setting values, if
  there is a linked netCDF resource, this object will be detached from
  it.

- `coordinates`:

  (read-only) Retrieve the labels of this object. Upon retrieval, label
  values are read from the netCDF resource, if there is one, upon first
  access and cached thereafter.

- `length`:

  (read-only) The number of labels in the set.

- `dimid`:

  The netCDF dimension id of this label set. Setting this value to
  anything other than the correct value will lead to disaster.

## Methods

### Public methods

- [`CFLabel$new()`](#method-CFLabel-initialize)

- [`CFLabel$print()`](#method-CFLabel-print)

- [`CFLabel$identical()`](#method-CFLabel-identical)

- [`CFLabel$copy()`](#method-CFLabel-copy)

- [`CFLabel$slice()`](#method-CFLabel-slice)

- [`CFLabel$subset()`](#method-CFLabel-subset)

- [`CFLabel$write()`](#method-CFLabel-write)

- [`CFLabel$geozarr_coordinates()`](#method-CFLabel-geozarr_coordinates)

Inherited methods

- [`CFObject$append_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-append_attribute)
- [`CFObject$attach_to_group()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-attach_to_group)
- [`CFObject$attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-attribute)
- [`CFObject$attributes_identical()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-attributes_identical)
- [`CFObject$delete_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-delete_attribute)
- [`CFObject$print_attributes()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-print_attributes)
- [`CFObject$set_attribute()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-set_attribute)
- [`CFObject$write_attributes()`](https://r-cf.github.io/ncdfCF/reference/CFObject.html#method-write_attributes)
- [`CFData$detach()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-detach)
- [`CFData$dim()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-dim)
- [`CFData$read_chunk()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-read_chunk)
- [`CFData$read_data()`](https://r-cf.github.io/ncdfCF/reference/CFData.html#method-read_data)

------------------------------------------------------------------------

### `CFLabel$new()`

Create a new instance of this class.

#### Usage

    CFLabel$new(var, group, values = NA, start = NA, count = NA)

#### Arguments

- `var`:

  The
  [NCVariable](https://r-cf.github.io/ncdfCF/reference/NCVariable.md)
  instance upon which this CF object is based when read from a netCDF
  resource, or the name for the object new CF object to be created.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) that
  this instance will live in.

- `values`:

  Optional. The labels of the CF object. Ignored when argument `var` is
  a `NCVariable` object.

- `start`:

  Optional. Integer index value indicating where to start reading data
  from the file. The value may be `NA` (default) to read all data,
  otherwise it must not be larger than the number of labels. Ignored
  when argument `var` is not an `NCVariable` instance.

- `count`:

  Optional. Integer value indicating the number of labels to read from
  file. The value may be `NA` to read to the end of the labels,
  otherwise its value must agree with the corresponding `start` value
  and the number of labels on file. Ignored when argument `var` is not
  an `NCVariable` instance.

#### Returns

A `CFLabel` instance.

------------------------------------------------------------------------

### `CFLabel$print()`

Prints a summary of the labels to the console.

#### Usage

    CFLabel$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

------------------------------------------------------------------------

### `CFLabel$identical()`

Tests if the object passed to this method is identical to `self`.

#### Usage

    CFLabel$identical(lbl)

#### Arguments

- `lbl`:

  The `CFLabel` instance to test.

#### Returns

`TRUE` if the two label sets are identical, `FALSE` if not.

------------------------------------------------------------------------

### `CFLabel$copy()`

Create a copy of this label set. The copy is completely separate from
`self`, meaning that both `self` and all of its components are made from
new instances.

#### Usage

    CFLabel$copy(name = "", group)

#### Arguments

- `name`:

  The name for the new label set. If an empty string is passed, will use
  the name of this label set.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

The newly created label set.

------------------------------------------------------------------------

### `CFLabel$slice()`

Given a range of domain coordinate values, returns the indices into the
axis that fall within the supplied range.

#### Usage

    CFLabel$slice(rng)

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

### `CFLabel$subset()`

Retrieve a subset of the labels.

#### Usage

    CFLabel$subset(name, group, rng)

#### Arguments

- `name`:

  The name for the new label set, optional.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this label set will live.

- `rng`:

  The range of indices whose values from this axis to include in the
  returned axis.

#### Returns

A `CFLabel` instance, or `NULL` if the `rng` values are invalid.

------------------------------------------------------------------------

### `CFLabel$write()`

Write the labels to a netCDF file, including its attributes.

#### Usage

    CFLabel$write()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFLabel$geozarr_coordinates()`

Create the GeoZarr coordinates for this label set. If the label set is
longer than a set minimum, write the label values to the group as a new
Zarr array if it does not yet exist.

#### Usage

    CFLabel$geozarr_coordinates(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` where the label values will be located in
  the Zarr store. The label values will be written to a new Zarr array
  with the name based on the name of this label set if it is irregular
  and long.

#### Returns

An instance of
[geozarr::CoordinatesString](https://rdrr.io/pkg/geozarr/man/CoordinatesString.html).
