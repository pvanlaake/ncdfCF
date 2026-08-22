# CF data variable

This class represents a CF data variable, the object that provides
access to an array of data.

The CF data variable instance provides access to all the details that
have been associated with the data variable, such as axis information,
grid mapping parameters, etc.

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
`CFVariable`

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `axes`:

  (read-only) List of instances of classes descending from
  [CFAxis](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) that are
  the axes of the data object.

- `ancillary_variables`:

  A list of ancillary data variables associated with this data variable.

- `crs`:

  The coordinate reference system of this variable, as an instance of
  [CFGridMapping](https://r-cf.github.io/ncdfCF/reference/CFGridMapping.md).
  If this field is `NULL`, the horizontal component of the axes are in
  decimal degrees of longitude and latitude.

- `cell_measures`:

  (read-only) List of the
  [CFCellMeasure](https://r-cf.github.io/ncdfCF/reference/CFCellMeasure.md)
  objects of this variable, if defined.

- `dimids`:

  (read-only) Retrieve the dimension ids used by the NC variable used by
  this variable.

- `dimnames`:

  (read-only) Retrieve dimnames of the data variable.

- `auxiliary_names`:

  (read-only) Retrieve the names of the auxiliary longitude and latitude
  grids as a vector of two character strings, in that order. If no
  auxiliary grids are defined, returns `NULL`.

- `values`:

  (read-only) Retrieve the raw values of the data variable. In general
  you should use the [`raw()`](https://rdrr.io/r/base/raw.html) function
  rather than this method because the
  [`raw()`](https://rdrr.io/r/base/raw.html) function will attach
  `dimnames` to the array that is returned.

- `gridLongLat`:

  Retrieve or set the grid of longitude and latitude values of every
  grid cell when the main variable grid has a different coordinate
  system.

- `crs_wkt2`:

  (read-only) Retrieve the coordinate reference system description of
  the variable as a WKT2 string.

## Methods

### Public methods

- [`CFVariable$new()`](#method-CFVariable-initialize)

- [`CFVariable$print()`](#method-CFVariable-print)

- [`CFVariable$brief()`](#method-CFVariable-brief)

- [`CFVariable$shard()`](#method-CFVariable-shard)

- [`CFVariable$peek()`](#method-CFVariable-peek)

- [`CFVariable$detach()`](#method-CFVariable-detach)

- [`CFVariable$time()`](#method-CFVariable-time)

- [`CFVariable$raw()`](#method-CFVariable-raw)

- [`CFVariable$array()`](#method-CFVariable-array)

- [`CFVariable$subset()`](#method-CFVariable-subset)

- [`CFVariable$summarise()`](#method-CFVariable-summarise)

- [`CFVariable$profile()`](#method-CFVariable-profile)

- [`CFVariable$append()`](#method-CFVariable-append)

- [`CFVariable$is_coincident()`](#method-CFVariable-is_coincident)

- [`CFVariable$add_cell_measure()`](#method-CFVariable-add_cell_measure)

- [`CFVariable$add_auxiliary_coordinate()`](#method-CFVariable-add_auxiliary_coordinate)

- [`CFVariable$add_ancillary_variable()`](#method-CFVariable-add_ancillary_variable)

- [`CFVariable$attach_to_group()`](#method-CFVariable-attach_to_group)

- [`CFVariable$terra()`](#method-CFVariable-terra)

- [`CFVariable$data.table()`](#method-CFVariable-data.table)

- [`CFVariable$write()`](#method-CFVariable-write)

- [`CFVariable$write_geozarr()`](#method-CFVariable-write_geozarr)

- [`CFVariable$save()`](#method-CFVariable-save)

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

### `CFVariable$new()`

Create an instance of this class.

#### Usage

    CFVariable$new(
      var,
      group,
      axes,
      values = values,
      start = NA,
      count = NA,
      attributes = data.frame()
    )

#### Arguments

- `var`:

  The
  [NCVariable](https://r-cf.github.io/ncdfCF/reference/NCVariable.md)
  instance upon which this CF variable is based when read from a netCDF
  resource, or the name for the new CF variable to be created.

- `group`:

  The [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) that
  this instance will live in.

- `axes`:

  List of instances of
  [CFAxis](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) to use
  with this variable.

- `values`:

  Optional. The values of the variable in an array.

- `start`:

  Optional. Vector of indices where to start reading data along the
  dimensions of the NC variable on file. The vector must be `NA` to read
  all data, otherwise it must have agree with the dimensions of the NC
  variable. Ignored when argument `var` is not an `NCVariable` instance.

- `count`:

  Optional. Vector of number of elements to read along each dimension of
  the NC variable on file. The vector must be `NA` to read to the end of
  each dimension, otherwise its value must agree with the corresponding
  `start` value and the dimension of the NC variable. Ignored when
  argument `var` is not an `NCVariable` instance.

- `attributes`:

  Optional. A `data.frame` with the attributes of the object. When
  argument `var` is an `NCVariable` instance and this argument is an
  empty `data.frame` (default), arguments will be read from the netCDF
  resource.

#### Returns

A `CFVariable` instance.

------------------------------------------------------------------------

### `CFVariable$print()`

Print a summary of the data variable to the console.

#### Usage

    CFVariable$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

------------------------------------------------------------------------

### `CFVariable$brief()`

Some details of the data variable.

#### Usage

    CFVariable$brief()

#### Returns

A 1-row `data.frame` with some details of the data variable.

------------------------------------------------------------------------

### `CFVariable$shard()`

The information returned by this method is very concise and most useful
when combined with similar information from other variables.

#### Usage

    CFVariable$shard()

#### Returns

Character string with very basic variable information.

------------------------------------------------------------------------

### `CFVariable$peek()`

Retrieve interesting details of the data variable.

#### Usage

    CFVariable$peek()

#### Returns

A 1-row `data.frame` with details of the data variable.

------------------------------------------------------------------------

### `CFVariable$detach()`

Detach the various properties of this variable from an underlying netCDF
resource.

#### Usage

    CFVariable$detach()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$time()`

Return the time object from the axis representing time.

#### Usage

    CFVariable$time(want = "time")

#### Arguments

- `want`:

  Character string with value "axis" or "time", indicating what is to be
  returned.

#### Returns

If `want = "axis"` the
[CFAxisTime](https://r-cf.github.io/ncdfCF/reference/CFAxisTime.md)
axis; if `want = "time"` the `CFTime` instance of the axis, or `NULL` if
the variable does not have a "time" axis.

------------------------------------------------------------------------

### `CFVariable$raw()`

Retrieve the data in the object exactly as it was read from a netCDF
resource or produced by an operation.

#### Usage

    CFVariable$raw()

#### Returns

An `array`, `matrix` or `vector` with (dim)names set.

------------------------------------------------------------------------

### `CFVariable$array()`

Retrieve the data in the object in the form of an R array, with axis
ordering Y-X-others and Y values going from the top down.

#### Usage

    CFVariable$array()

#### Returns

An `array` or `matrix` of data in R ordering, or a `vector` if the data
has only a single dimension.

------------------------------------------------------------------------

### `CFVariable$subset()`

This method extracts a subset of values from the array of the variable,
with the range along each axis to extract expressed in coordinate values
of the domain of each axis.

#### Usage

    CFVariable$subset(..., rightmost.closed = FALSE, .resolution = NULL)

#### Arguments

- `...`:

  One or more arguments of the form `axis = range`. The "axis" part
  should be the name of an axis or its orientation `X`, `Y`, `Z` or `T`.
  The "range" part is a vector of values representing coordinates along
  the axis where to extract data. Axis designators and names are
  case-sensitive and can be specified in any order. If values for the
  range per axis fall outside of the extent of the axis, the range is
  clipped to the extent of the axis.

- `rightmost.closed`:

  Single logical value to indicate if the upper boundary of range in
  each axis should be included. You must use the argument name when
  specifying this, like `rightmost.closed = TRUE`, to avoid the argument
  being treated as an axis name.

- `.resolution`:

  For interpolation with auxiliary coordinates, the resolution in
  longitude and latitude directions as numeric values in decimal
  degrees, optional. If a single value is given, it will apply in both
  directions. If not supplied, the resolution in the center of the
  requested area will be calculated and applied over the entire area.

#### Details

The range of values along each axis to be subset is expressed in
coordinates of the domain of the axis. Any axes for which no selection
is made in the `...` argument are extracted in whole. Coordinates can be
specified in a variety of ways that are specific to the nature of the
axis. For numeric axes it should (resolve to) be a vector of real
values. A range (e.g. `100:200`), a vector (`c(23, 46, 3, 45, 17`), a
sequence (`seq(from = 78, to = 100, by = 2`), all work. Note, however,
that only a single range is generated from the vector so these examples
resolve to `(100, 200)`, `(3, 46)`, and `(78, 100)`, respectively. For
time axes a vector of character timestamps, `POSIXct` or `Date` values
must be specified. As with numeric values, only the two extreme values
in the vector will be used.

If the range of coordinate values for an axis in argument `...` extends
the valid range of the axis, the extracted data will start at the
beginning for smaller values and extend to the end for larger values. If
the values envelope the valid range the entire axis will be extracted in
the result. If the range of coordinate values for any axis are all
either smaller or larger than the valid range of the axis then nothing
is extracted and `NULL` is returned.

The extracted data has the same dimensional structure as the data in the
variable, with degenerate dimensions preserved. The order of the axes in
argument `...` does not reorder the axes in the result; use the
[`array()`](https://rdrr.io/r/base/array.html) method for this.

As an example, to extract values of a variable for Australia for the
year 2020, where the first axis in `x` is the longitude, the second axis
is the latitude, both in degrees, and the third (and final) axis is
time, the values are extracted by
`x$subset(X = c(112, 154), Y = c(-9, -44), T = c("2020-01-01", "2021-01-01"))`.
Note that this works equally well for projected coordinate reference
systems - the key is that the specification in argument `...` uses the
same domain of values as the respective axes in `x` use.

##### Auxiliary coordinate variables

A special case exists for variables where the horizontal dimensions (X
and Y) are not in longitude and latitude coordinates but in some other
coordinate system. In this case the netCDF resource may have so-called
*auxiliary coordinate variables* for longitude and latitude that are two
grids with the same dimension as the horizontal axes of the data
variable where each pixel gives the corresponding value for the
longitude and latitude. If the variable has such *auxiliary coordinate
variables* then you can specify their names (instead of specifying the
names of the primary planar axes). The resolution of the grid that is
produced by this method is automatically calculated. If you want to
subset those axes then specify values in decimal degrees; if you want to
extract the full extent, specify `NA` for both axes.

#### Returns

A `CFVariable` instance, having the axes and attributes of the variable,
or `NULL` if one or more of the selectors in the `...` argument fall
entirely outside of the range of the axis.

If `self` is linked to a netCDF resource then the result will be linked
to the same netCDF resource as well, except when *auxiliary coordinate
variables* have been selected for the planar axes. In all cases the
result will be attached to a private group.

------------------------------------------------------------------------

### `CFVariable$summarise()`

Summarise the temporal domain of the data, if present, to a lower
resolution, using a user-supplied aggregation function.

#### Usage

    CFVariable$summarise(name, fun, period, era = NULL, ...)

#### Arguments

- `name`:

  Character vector with a name for each of the results that `fun`
  returns. So if `fun` has 2 return values, this should be a vector of
  length 2. Any missing values are assigned a default name of
  "result\_#" (with '#' being replaced with an ordinal number).

- `fun`:

  A function or a symbol or character string naming a function that will
  be applied to each grouping of data. The function must return an
  atomic value (such as [`sum()`](https://rdrr.io/r/base/sum.html) or
  [`mean()`](https://rdrr.io/r/base/mean.html)), or a vector of atomic
  values (such as [`range()`](https://rdrr.io/r/base/range.html)). Lists
  and other objects are not allowed and will throw an error that may be
  cryptic as there is no way that this method can assert that `fun`
  behaves properly so an error will pop up somewhere, quite possibly in
  unexpected ways. The function may also be user-defined so you could
  write a wrapper around a function like
  [`lm()`](https://rdrr.io/r/stats/lm.html) to return values like the
  intercept or any coefficients from the object returned by calling that
  function.

- `period`:

  The period to summarise to. Must be one of either "day", "dekad",
  "month", "quarter", "season", "year". A "quarter" is the standard
  calendar quarter such as January-March, April-June, etc. A "season" is
  a meteorological season, such as December-February, March-May, etc.
  (any December data is from the year preceding the January data). The
  period must be of lower resolution than the resolution of the time
  axis.

- `era`:

  Optional, integer vector of years to summarise over by the specified
  `period`. The extreme values of the years will be used. This can also
  be a list of multiple such vectors. The elements in the list, if used,
  should have names as these will be used to label the results.

- `...`:

  Additional parameters passed on to `fun`.

#### Details

Attributes are copied from the input data variable or data array. Note
that after a summarisation the attributes may no longer be accurate.
This method tries to sanitise attributes but the onus is on the calling
code (or yourself as interactive coder). Attributes like `standard_name`
and `cell_methods` likely require an update in the output of this
method, but the appropriate new values are not known to this method. Use
`CFVariable$set_attribute()` on the result of this method to set or
update attributes as appropriate.

#### Returns

A `CFVariable` object, or a list thereof with as many `CFVariable`
objects as `fun` returns values, or `NULL` if the `era` argument falls
entirely outside of the range of the time axis.

------------------------------------------------------------------------

### `CFVariable$profile()`

This method extracts profiles of values from the array of the variable,
with the location along each axis to extract expressed in coordinate
values of each axis.

#### Usage

    CFVariable$profile(..., .names = NULL, .as_table = FALSE)

#### Arguments

- `...`:

  One or more arguments of the form `axis = location`. The "axis" part
  should be the name of an axis or its orientation `X`, `Y`, `Z` or `T`.
  The "location" part is a vector of values representing coordinates
  along the axis where to profile. A profile will be generated for each
  of the elements of the "location" vectors in all arguments.

- `.names`:

  A character vector with names for the results. The names will be used
  for the resulting `CFVariable` instances, or as values for the
  "location" column of the `data.table` if argument `.as_table` is
  `TRUE`. If the vector is shorter than the longest vector of locations
  in the `...` argument, a name "location\_#" will be used, with the \#
  replaced by the ordinal number of the vector element.

- `.as_table`:

  Logical to flag if the results should be `CFVariable` instances
  (`FALSE`, default) or a single `data.table` (`TRUE`). If `TRUE`, all
  `...` arguments must have the same number of elements, use the same
  axes and the `data.table` package must be installed.

#### Details

The coordinates along each axis to be sampled are expressed in values of
the domain of the axis. Any axes which are not passed as arguments are
extracted in whole to the result. If bounds are set on the axis, the
coordinate whose bounds envelop the requested coordinate is selected.
Otherwise, the coordinate along the axis closest to the supplied value
will be used. If the value for a specified axis falls outside the valid
range of that axis, `NULL` is returned.

A typical case is to extract the temporal profile as a 1D array for a
given location. In this case, use arguments for the latitude and
longitude on an X-Y-T data variable: `profile(lat = -24, lon = 3)`.
Other profiling options are also possible, such as a 2D zonal
atmospheric profile at a given longitude for an X-Y-Z data variable:
`profile(lon = 34)`.

Multiple profiles can be extracted in one call by supplying vectors for
the indicated axes: `profile(lat = c(-24, -23, -2), lon = c(5, 5, 6))`.
The vectors need not have the same length, unless `.as_table = TRUE`.
With unequal length vectors the result will be a `list` of `CFVariable`
instances with different dimensionality and/or different axes.

##### Auxiliary coordinate variables

A special case exists for variables where the horizontal dimensions (X
and Y) are not in longitude and latitude coordinates but in some other
coordinate system. In this case the netCDF resource may have so-called
*auxiliary coordinate variables*. If the variable has such *auxiliary
coordinate variables* then you can specify their names (instead of
specifying the names of the primary planar axes).

#### Returns

If `.as_table == FALSE`, a `CFVariable` instance, or a list thereof with
each having one profile for each of the elements in the "location"
vectors of argument `...` and named with the respective `.names` value.
If `.as_table == TRUE`, a `data.table` with a row for each element along
all profiles, with a ".variable" column using the values from the
`.names` argument.

------------------------------------------------------------------------

### `CFVariable$append()`

Append the data from another `CFVariable` instance to the current
instance, along one of the axes. The operation will only succeed if the
axes other than the one to append along have the same coordinates and
the coordinates of the axis to append along have to be monotonically
increasing or decreasing after appending. The attributes are not
assessed.

#### Usage

    CFVariable$append(from, along)

#### Arguments

- `from`:

  The `CFVariable` instance to append to this data variable.

- `along`:

  The name of the axis to append along. This must be a single character
  string and the named axis has to be present both in this data variable
  and in the `CFVariable` instance in argument `from`.

#### Returns

Self, invisibly, with the arrays from this data variable and `from`
appended, in a new private group.

------------------------------------------------------------------------

### `CFVariable$is_coincident()`

Tests if the `other` object is coincident with this data variable:
identical axes.

#### Usage

    CFVariable$is_coincident(other)

#### Arguments

- `other`:

  A `CFVariable` instance to compare to this data variable.

#### Returns

`TRUE` if the data variables are coincident, `FALSE` otherwise.

------------------------------------------------------------------------

### `CFVariable$add_cell_measure()`

Add a cell measure variable to this variable.

#### Usage

    CFVariable$add_cell_measure(cm)

#### Arguments

- `cm`:

  An instance of
  [CFCellMeasure](https://r-cf.github.io/ncdfCF/reference/CFCellMeasure.md).

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$add_auxiliary_coordinate()`

Add an auxiliary coordinate to the appropriate axis of this variable.
The length of the axis must be the same as the length of the auxiliary
labels.

#### Usage

    CFVariable$add_auxiliary_coordinate(aux, axis)

#### Arguments

- `aux`:

  An instance of
  [CFLabel](https://r-cf.github.io/ncdfCF/reference/CFLabel.md) or
  [CFAxis](https://r-cf.github.io/ncdfCF/reference/CFAxis.md).

- `axis`:

  An instance of `CFAxis` that these auxiliary coordinates are for.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$add_ancillary_variable()`

Add an ancillary variable to this variable.

#### Usage

    CFVariable$add_ancillary_variable(var)

#### Arguments

- `var`:

  An instance of CFVariable.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$attach_to_group()`

Attach this variable to a group. If there is another object with the
same name in this group an error is thrown. For associated objects (such
as axes, CRS, boundary variables, etc), if another object with the same
name is otherwise identical to the associated object then that object
will be linked from the variable, otherwise an error is thrown.

#### Usage

    CFVariable$attach_to_group(grp, locations = list())

#### Arguments

- `grp`:

  An instance of
  [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md).

- `locations`:

  Optional. A `list` whose named elements correspond to the names of
  objects associated with this variable (but not the variable itself).
  Each list element has a single character string indicating the group
  in the hierarchy where the object should be stored. As an example, if
  the variable has axes "lon" and "lat" and they should be stored in the
  parent group of `grp`, then specify
  `locations = list(lon = "..", lat = "..")`. Locations can use absolute
  paths or relative paths from the group. Associated objects that are
  not in the list will be stored in group `grp`. If the argument
  `locations` is not provided, all associated objects will be stored in
  this group.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$terra()`

Convert the data to a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
(3D) or a
[`terra::SpatRasterDataset`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
(4D) object. The data will be oriented to North-up. The 3rd dimension in
the data will become layers in the resulting `SpatRaster`, any 4th
dimension the data sets. The `terra` package needs to be installed for
this method to work.

#### Usage

    CFVariable$terra()

#### Returns

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
or
[`terra::SpatRasterDataset`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
instance.

------------------------------------------------------------------------

### `CFVariable$data.table()`

Retrieve the data variable in the object in the form of a `data.table`.
The `data.table` package needs to be installed for this method to work.

The attributes associated with this data variable will be mostly lost.
If present, attributes 'long_name' and 'units' are attached to the
`data.table` as attributes, but all others are lost.

#### Usage

    CFVariable$data.table(var_as_column = FALSE)

#### Arguments

- `var_as_column`:

  Logical to flag if the name of the variable should become a column
  (`TRUE`) or be used as the name of the column with the data values
  (`FALSE`, default). Including the name of the variable as a column is
  useful when multiple `data.table`s are merged by rows into one.

#### Returns

A `data.table` with all data points in individual rows. All axes will
become columns. Two attributes are added: `name` indicates the long name
of this data variable, `units` indicates the physical unit of the data
values.

------------------------------------------------------------------------

### `CFVariable$write()`

Write the data variable to a netCDF file, including all of its dependent
objects, such as axes and attributes.

Axes with `length == 1L` are written as a "scalar axis", unless they are
unlimited.

#### Usage

    CFVariable$write(pack)

#### Arguments

- `pack`:

  Optional. Logical to indicate if the data should be packed for a
  `CFVariable` first written to file. Packing is only useful for numeric
  data; packing is not performed on integer values. Packing is always to
  the "NC_SHORT" data type, i.e. 16-bits per value. If the variable has
  been written before, the packing state of the variable on file will be
  used.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$write_geozarr()`

Write the data variable to a Zarr group, including its attributes and
other assorted objects. Axes, auxiliary coordinates and boundary values
that are regular or short are written inline in the attributes of the
array, irregular ones have already been stored externally.

#### Usage

    CFVariable$write_geozarr(grp)

#### Arguments

- `grp`:

  An instance of `zarr_group` to write the data variable to. The data
  variable will be written to a new Zarr array with the name of the data
  variable.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFVariable$save()`

Save the data variable to a netCDF file, including its subordinate
objects such as axes, CRS, etc. Note that saving a data variable will
create a "bare-bones" netCDF file and its associated
[CFDataset](https://r-cf.github.io/ncdfCF/reference/CFDataset.md).

#### Usage

    CFVariable$save(fn, pack = FALSE)

#### Arguments

- `fn`:

  The name of the netCDF file to create.

- `pack`:

  Logical to indicate if the data should be packed. Packing is only
  useful for numeric data; packing is not performed on integer values.
  Packing is always to the "NC_SHORT" data type, i.e. 16-bits per value.

#### Returns

The newly create `CFDataset`, invisibly.
