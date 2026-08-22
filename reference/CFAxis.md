# CF axis object

This class is a basic ancestor to all classes that represent CF axes.
More useful classes use this class as ancestor.

This super-class does manage the "coordinates" of the axis, i.e. the
values along the axis. This could be the values of the axis as stored on
file, but it can also be the values from an auxiliary coordinate set, in
the form of a
[CFLabel](https://r-cf.github.io/ncdfCF/reference/CFLabel.md) instance.
The coordinate set to use in display, selection and processing is
selectable through methods and fields in this class.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
`CFAxis`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `dimid`:

  The netCDF dimension id of this axis. Setting this value to anything
  other than the correct value will lead to disaster.

- `length`:

  (read-only) The declared length of this axis.

- `orientation`:

  Set or retrieve the orientation of the axis, a single character with a
  value of "X", "Y", "Z", "T". Setting the orientation of the axis
  should only be done when the current orientation is unknown. Setting a
  wrong value may give unexpected errors in processing of data
  variables.

- `values`:

  (read-only) Retrieve the raw values of the axis. In general you should
  use the `coordinates` field rather than this one.

- `coordinates`:

  (read-only) Retrieve the coordinate values of the active coordinate
  set from the axis.

- `regular`:

  (read-only) Flag if the numeric or time axis coordinates are regular,
  meaning equally spaced.

- `bounds`:

  Set or retrieve the bounds of this axis as a
  [CFBounds](https://r-cf.github.io/ncdfCF/reference/CFBounds.md)
  object. When setting the bounds, the bounds values must agree with the
  coordinates of this axis.

- `auxiliary`:

  Set or retrieve auxiliary coordinates for the axis. On assignment, the
  value must be an instance of
  [CFLabel](https://r-cf.github.io/ncdfCF/reference/CFLabel.md) or a
  CFAxis descendant, which is added to the end of the list of coordinate
  sets. On retrieval, the active `CFLabel` or `CFAxis` instance or
  `NULL` when the active coordinate set is the primary axis coordinates.

- `coordinate_names`:

  (read-only) Retrieve the names of the coordinate sets defined for the
  axis, as a character vector. The first element in the vector is the
  name of the axis and it refers to the values of the coordinates of
  this axis. Following elements refer to auxiliary coordinates.

- `coordinate_range`:

  (read-only) Retrieve the range of the coordinates of the axis as a
  vector of two values. The mode of the result depends on the sub-type
  of the axis.

- `active_coordinates`:

  Set or retrieve the name of the coordinate set to use with the axis
  for printing to the console as well as for processing methods such as
  [`subset()`](https://rdrr.io/r/base/subset.html).

- `unlimited`:

  Logical to indicate if the axis is unlimited. The setting can only be
  changed if the axis has not yet been written to file.

- `time`:

  (read-only) Retrieve the `CFTime` object associated with the axis.
  Always returns `NULL` but `CFAxisTime` overrides this field.

- `is_parametric`:

  (read-only) Logical flag that indicates if the axis has parametric
  coordinates. Always `FALSE` for all axes except for
  [CFAxisVertical](https://r-cf.github.io/ncdfCF/reference/CFAxisVertical.md)
  which overrides this method.

## Methods

### Public methods

- [`CFAxis$new()`](#method-CFAxis-initialize)

- [`CFAxis$print()`](#method-CFAxis-print)

- [`CFAxis$brief()`](#method-CFAxis-brief)

- [`CFAxis$shard()`](#method-CFAxis-shard)

- [`CFAxis$peek()`](#method-CFAxis-peek)

- [`CFAxis$detach()`](#method-CFAxis-detach)

- [`CFAxis$copy_terms()`](#method-CFAxis-copy_terms)

- [`CFAxis$configure_terms()`](#method-CFAxis-configure_terms)

- [`CFAxis$identical()`](#method-CFAxis-identical)

- [`CFAxis$can_append()`](#method-CFAxis-can_append)

- [`CFAxis$copy()`](#method-CFAxis-copy)

- [`CFAxis$copy_with_values()`](#method-CFAxis-copy_with_values)

- [`CFAxis$subset()`](#method-CFAxis-subset)

- [`CFAxis$indexOf()`](#method-CFAxis-indexOf)

- [`CFAxis$attach_to_group()`](#method-CFAxis-attach_to_group)

- [`CFAxis$write()`](#method-CFAxis-write)

- [`CFAxis$geozarr_axis()`](#method-CFAxis-geozarr_axis)

- [`CFAxis$geozarr_coordinates()`](#method-CFAxis-geozarr_coordinates)

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

------------------------------------------------------------------------

### `CFAxis$new()`

Create a new CF axis instance from a dimension and a variable in a
netCDF resource. This method is called upon opening a netCDF resource by
the `initialize()` method of a descendant class suitable for the type of
axis.

Creating a new axis is more easily done with the
[`makeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeAxis.md)
function.

#### Usage

    CFAxis$new(
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

  Optional. The values of the axis in a vector. Ignored when argument
  `var` is a `NCVariable` object.

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

#### Returns

A basic `CFAxis` object.

------------------------------------------------------------------------

### `CFAxis$print()`

Prints a summary of the axis to the console. This method is typically
called by the [`print()`](https://rdrr.io/r/base/print.html) method of
descendant classes.

#### Usage

    CFAxis$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

#### Returns

`self`, invisibly.

------------------------------------------------------------------------

### `CFAxis$brief()`

Some details of the axis.

#### Usage

    CFAxis$brief()

#### Returns

A 1-row `data.frame` with some details of the axis.

------------------------------------------------------------------------

### `CFAxis$shard()`

Very concise information on the axis. The information returned by this
function is very concise and most useful when combined with similar
information from other axes.

#### Usage

    CFAxis$shard()

#### Returns

Character string with very basic axis information.

------------------------------------------------------------------------

### `CFAxis$peek()`

Retrieve interesting details of the axis.

#### Usage

    CFAxis$peek()

#### Returns

A 1-row `data.frame` with details of the axis.

------------------------------------------------------------------------

### `CFAxis$detach()`

Detach the axis from its underlying netCDF resource, including any
dependent CF objects.

#### Usage

    CFAxis$detach()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFAxis$copy_terms()`

Copy the parametric terms of a vertical axis. This method is only useful
for `CFAxisVertical` instances having a parametric formulation. This
stub is here to make the call to this method succeed with no result for
the other descendant classes.

#### Usage

    CFAxis$copy_terms(from, original_axes, new_axes)

#### Arguments

- `from`:

  A CFAxisVertical instance that will receive references to the
  parametric terms.

- `original_axes`:

  List of `CFAxis` instances from the CF object that these parametric
  terms are copied from.

- `new_axes`:

  List of `CFAxis` instances to use with the formula term objects.

#### Returns

`NULL`

------------------------------------------------------------------------

### `CFAxis$configure_terms()`

Configure the function terms of a parametric vertical axis. This method
is only useful for `CFAxisVertical` instances having a parametric
formulation. This stub is here to make the call to this method succeed
with no result for the other descendant classes.

#### Usage

    CFAxis$configure_terms(axes)

#### Arguments

- `axes`:

  List of `CFAxis` instances.

#### Returns

`NULL`

------------------------------------------------------------------------

### `CFAxis$identical()`

Tests if the axis passed to this method is identical to `self`. This
only tests for generic properties - class, length, name and attributes -
with further assessment done in sub-classes.

#### Usage

    CFAxis$identical(axis, with_attributes = FALSE)

#### Arguments

- `axis`:

  The `CFAxis` instance to test.

- `with_attributes`:

  Logical that indicates if the attributes are assessed for equality
  too. Default is `FALSE`.

#### Returns

`TRUE` if the two axes are identical, `FALSE` if not.

------------------------------------------------------------------------

### `CFAxis$can_append()`

Tests if the axis passed to this method can be appended to `self`. This
only tests for generic properties - class, mode of the values and name -
with further assessment done in sub-classes.

#### Usage

    CFAxis$can_append(axis)

#### Arguments

- `axis`:

  The `CFAxis` descendant instance to test.

#### Returns

`TRUE` if the passed axis can be appended to `self`, `FALSE` if not.

------------------------------------------------------------------------

### `CFAxis$copy()`

Create a copy of this axis. This method is "virtual" in the sense that
it does not do anything other than return `NULL`. This stub is here to
make the call to this method succeed with no result for the `CFAxis`
descendants that do not implement this method.

#### Usage

    CFAxis$copy(name = "", group)

#### Arguments

- `name`:

  The name for the new axis. If an empty string is passed, will use the
  name of this axis.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

#### Returns

`NULL`

------------------------------------------------------------------------

### `CFAxis$copy_with_values()`

Create a copy of this axis but using the supplied values. This method is
"virtual" in the sense that it does not do anything other than return
`NULL`. This stub is here to make the call to this method succeed with
no result for the `CFAxis` descendants that do not implement this
method.

#### Usage

    CFAxis$copy_with_values(name = "", group, values)

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

`NULL`

------------------------------------------------------------------------

### `CFAxis$subset()`

Return an axis spanning a smaller coordinate range. This method is
"virtual" in the sense that it does not do anything other than return
`self`. This stub is here to make the call to this method succeed with
no result for the `CFAxis` descendants that do not implement this
method.

#### Usage

    CFAxis$subset(name = "", group, rng = NULL)

#### Arguments

- `name`:

  The name for the new axis if the `rng` argument is provided.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md)
  where the copy of this axis will live.

- `rng`:

  The range of indices whose values from this axis to include in the
  returned axis. If the value of the argument is `NULL`, return a copy
  of the axis.

#### Returns

`NULL`

------------------------------------------------------------------------

### `CFAxis$indexOf()`

Find indices in the axis domain. Given a vector of numerical, timestamp
or categorical coordinates `x`, find their indices in the coordinates of
the axis.

This is a virtual method. For more detail, see the corresponding method
in descendant classes.

#### Usage

    CFAxis$indexOf(x, method = "constant", rightmost.closed = TRUE)

#### Arguments

- `x`:

  Vector of numeric, timestamp or categorial coordinates to find axis
  indices for. The timestamps can be either character, POSIXct or Date
  vectors. The type of the vector has to correspond to the type of the
  axis values.

- `method`:

  Single character value of "constant" or "linear".

- `rightmost.closed`:

  Whether or not to include the upper limit. Default is `TRUE`.

#### Returns

Numeric vector of the same length as `x`.

------------------------------------------------------------------------

### `CFAxis$attach_to_group()`

Attach this axis to a group. If there is another object with the same
name in this group an error is thrown. For associated objects (such as
bounds, etc), if another object with the same name is otherwise
identical to the associated object then that object will be linked from
the variable, otherwise an error is thrown.

#### Usage

    CFAxis$attach_to_group(grp, locations = list())

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

### `CFAxis$write()`

Write the axis to a netCDF file, including its attributes.

#### Usage

    CFAxis$write()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFAxis$geozarr_axis()`

Create the GeoZarr coordinate system axis for this axis, inclusive of
auxiliary coordinates. This will also include boundary values.

#### Usage

    CFAxis$geozarr_axis(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` where the axis will be located in the Zarr
  store. The axis will be written to a new Zarr array with the name of
  the axis if it is irregular and long.

#### Returns

An instance of
[geozarr::CoordinateSystemAxis](https://rdrr.io/pkg/geozarr/man/CoordinateSystemAxis.html).

------------------------------------------------------------------------

### `CFAxis$geozarr_coordinates()`

Create the GeoZarr coordinates for this axis. If the coordinate values
are not regular and longer than a set minimum, write the coordinates to
the group as a new Zarr array if it does not yet exist. This will also
include boundary values.

#### Usage

    CFAxis$geozarr_coordinates(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` where the coordinates will be located in
  the Zarr store. The coordinates will be written to a new Zarr array
  with the name based on the axis name if it is irregular and long.

#### Returns

An instance of
[geozarr::Coordinates](https://rdrr.io/pkg/geozarr/man/Coordinates.html)
or a descendant class.
