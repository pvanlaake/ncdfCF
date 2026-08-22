# Vertical CF axis object

This class represents a vertical axis, which may be parametric. A
regular vertical axis behaves like any other numeric axis. A parametric
vertical axis, on the other hand, is defined through an index value that
is contained in the axis coordinates, with additional data variables
that hold ancillary "formula terms" with which to calculate physical
axis coordinates. It is used in atmosphere and ocean data sets.

Parametric vertical axes can only be read from file, not created from
scratch.

## References

https://cfconventions.org/Data/cf-conventions/cf-conventions.html#parametric-vertical-coordinate
https://www.myroms.org/wiki/Vertical_S-coordinate

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) -\>
[`CFAxisNumeric`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.md)
-\> `CFAxisVertical`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `formula_terms`:

  (read-only) A `data.frame` with the "formula_terms" to calculate the
  parametric axis values.

- `is_parametric`:

  (read-only) Logical flag that indicates if the coordinates of the axis
  are parametric.

- `parametric_coordinates`:

  (read-only) Retrieve the parametric coordinates of this vertical axis
  as a
  [CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md).

- `computed_name`:

  (read-only) The name of the computed parameterised coordinates. If the
  parameterised coordinates have not been computed yet the computed name
  is an empty string.

- `computed_units`:

  (read-only) Return the units of the computed parameterised
  coordinates, if computed, otherwise return `NULL`. This will access
  the standard names table.

## Methods

### Public methods

- [`CFAxisVertical$new()`](#method-CFAxisVertical-initialize)

- [`CFAxisVertical$attach_to_group()`](#method-CFAxisVertical-attach_to_group)

- [`CFAxisVertical$detach()`](#method-CFAxisVertical-detach)

- [`CFAxisVertical$copy()`](#method-CFAxisVertical-copy)

- [`CFAxisVertical$copy_with_values()`](#method-CFAxisVertical-copy_with_values)

- [`CFAxisVertical$set_parametric_terms()`](#method-CFAxisVertical-set_parametric_terms)

- [`CFAxisVertical$append()`](#method-CFAxisVertical-append)

- [`CFAxisVertical$subset()`](#method-CFAxisVertical-subset)

- [`CFAxisVertical$subset_parametric_terms()`](#method-CFAxisVertical-subset_parametric_terms)

- [`CFAxisVertical$geozarr_coordinates()`](#method-CFAxisVertical-geozarr_coordinates)

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
- [`CFAxis$can_append()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-can_append)
- [`CFAxis$configure_terms()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-configure_terms)
- [`CFAxis$copy_terms()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-copy_terms)
- [`CFAxis$geozarr_axis()`](https://r-cf.github.io/ncdfCF/reference/CFAxis.html#method-geozarr_axis)
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

### `CFAxisVertical$new()`

Create a new instance of this class.

#### Usage

    CFAxisVertical$new(
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
  numeric and monotonic.

- `start`:

  Optional. Integer index where to start reading axis data from file.
  The index may be `NA` to start reading data from the start.

- `count`:

  Optional. Number of elements to read from file. This may be `NA` to
  read to the end of the data.

- `attributes`:

  Optional. A `data.frame` with the attributes of the axis. When an
  empty `data.frame` (default) and argument `var` is an `NCVariable`
  instance, attributes of the axis will be taken from the netCDF
  resource.

------------------------------------------------------------------------

### `CFAxisVertical$attach_to_group()`

Attach this verical axis to a group, including any parameteric terms. If
there is another object with the same name in this group an error is
thrown. For associated objects (such as bounds, etc), if another object
with the same name is otherwise identical to the associated object then
that object will be linked from the variable, otherwise an error is
thrown.

#### Usage

    CFAxisVertical$attach_to_group(grp, locations = list())

#### Arguments

- `grp`:

  An instance of
  [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md).

- `locations`:

  Optional. A `list` whose named elements correspond to the names of
  objects associated with this axis, possibly including the axis itself.
  Each list element has a single character string indicating the group
  in the hierarchy where the object should be stored. As an example, if
  the variable has axes "lon" and "lat" and they should be stored in the
  parent group of `grp`, then specify
  `locations = list(lon = "..", lat = "..")`. Locations can use absolute
  paths or relative paths from group `grp`. The axis and associated
  objects that are not in the list will be stored in group `grp`. If the
  argument `locations` is not provided, all associated objects will be
  stored in this group.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFAxisVertical$detach()`

Detach the parametric terms from an underlying netCDF resource.

#### Usage

    CFAxisVertical$detach()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFAxisVertical$copy()`

Create a copy of this axis. The copy is completely separate from this
instance, meaning that the copies of both this instance and all of its
components are made as new instances.

#### Usage

    CFAxisVertical$copy(name = "", group)

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

### `CFAxisVertical$copy_with_values()`

Create a copy of this axis but using the supplied values. The attributes
are copied to the new axis. Boundary values, parametric coordinates and
auxiliary coordinates are not copied.

After this operation the attributes of the newly created axes may not be
accurate, except for the "actual_range" attribute. The calling code
should set, modify or delete attributes as appropriate.

#### Usage

    CFAxisVertical$copy_with_values(name = "", group, values)

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

### `CFAxisVertical$set_parametric_terms()`

Set the parametric terms for this axis. The name and the terms have to
fully describe a CF parametric vertical axis.

The terms must also agree with the other axes used by any data variable
that refers to this axis. That is not checked here so the calling code
must make that assertion.

#### Usage

    CFAxisVertical$set_parametric_terms(sn, terms)

#### Arguments

- `sn`:

  The "standard_name" of the parametric formulation. See the CF
  documentation for details.

- `terms`:

  A `data.frame` with columns `term`, `variable` and `param` containing
  the terms of the formula to calculate the axis values. Column `param`
  has the references to the variables that hold the data for each term.

------------------------------------------------------------------------

### `CFAxisVertical$append()`

Append a vector of values at the end of the current values of the axis.
Boundary values are appended as well but if either this axis or the
`from` axis does not have boundary values, neither will the resulting
axis.

This method is not recommended for parametric vertical axes. Any
parametric terms will be deleted. If appending of parametric axes is
required, the calling code should first read out the parametric terms
and merge them with the parametric terms of the `from` axis before
setting them back for this axis.

#### Usage

    CFAxisVertical$append(from)

#### Arguments

- `from`:

  An instance of `CFAxisVertical` whose values to append to the values
  of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

A new `CFAxisVertical` instance with values from this axis and the
`from` axis appended.

------------------------------------------------------------------------

### `CFAxisVertical$subset()`

Return an axis spanning a smaller coordinate range. This method returns
an axis which spans the range of indices given by the `rng` argument. If
this axis has parametric terms, these are not subset here - they should
be separately treated once all associated axes in the terms have been
subset. That happens automatically in `CFVariable` methods which call
the `subset_parametric_terms()` method.

#### Usage

    CFAxisVertical$subset(name = "", group, rng = NULL)

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

A new `CFAxisVertical` instance covering the indicated range of indices.
If the value of the argument `rng` is `NULL`, return a copy of this axis
as the new axis.

------------------------------------------------------------------------

### `CFAxisVertical$subset_parametric_terms()`

Subset the parametric terms of this axis.

#### Usage

    CFAxisVertical$subset_parametric_terms(
      original_axis_names,
      new_axes,
      start,
      count,
      aux = NULL,
      ZT_dim = NULL
    )

#### Arguments

- `original_axis_names`:

  Character vector of names of the axes prior to a modifying operation
  in the owning data variable

- `new_axes`:

  List of `CFAxis` instances to use for the subsetting.

- `start`:

  The indices to start reading data from the file, as an integer vector
  at least as long as the number of axis for the term.

- `count`:

  The number of values to read from the file, as an integer vector at
  least as long as the number of axis for the term.

- `aux`:

  Optional. List with the parameters for an auxiliary grid
  transformation. Default is `NULL`.

- `ZT_dim`:

  Optional. Dimensions of the non-grid axes when an auxiliary grid
  transformation is specified.

#### Returns

Self, invisibly. The parametric terms will have been subset in this
axis.

------------------------------------------------------------------------

### `CFAxisVertical$geozarr_coordinates()`

Create the GeoZarr coordinates for this vertical axis. If the coordinate
values are not regular and longer than a set minimum, write the
coordinates to the group as a new Zarr array if it does not yet exist.
This will also include boundary values.

#### Usage

    CFAxisVertical$geozarr_coordinates(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` where the coordinates will be located in
  the Zarr store. The coordinates will be written to a new Zarr array
  with the name based on the axis name if it is irregular and long.

#### Returns

An instance of
[geozarr::Coordinates](https://rdrr.io/pkg/geozarr/man/Coordinates.html)
or a descendant class.
