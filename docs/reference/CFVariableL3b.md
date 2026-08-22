# CF data variable for the NASA L3b format

This class represents a CF data variable that provides access to data
sets in NASA level-3 binned format, used extensively for satellite
imagery.

## References

https://oceancolor.gsfc.nasa.gov/resources/docs/technical/ocean_level-3_binned_data_products.pdf

## Super classes

[`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) -\>
[`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) -\>
[`CFVariable`](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
-\> `CFVariableL3b`

## Methods

### Public methods

- [`CFVariableL3b$new()`](#method-CFVariableL3b-initialize)

- [`CFVariableL3b$subset()`](#method-CFVariableL3b-subset)

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
- [`CFVariable$add_ancillary_variable()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-add_ancillary_variable)
- [`CFVariable$add_auxiliary_coordinate()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-add_auxiliary_coordinate)
- [`CFVariable$add_cell_measure()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-add_cell_measure)
- [`CFVariable$append()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-append)
- [`CFVariable$array()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-array)
- [`CFVariable$attach_to_group()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-attach_to_group)
- [`CFVariable$brief()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-brief)
- [`CFVariable$data.table()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-data.table)
- [`CFVariable$detach()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-detach)
- [`CFVariable$is_coincident()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-is_coincident)
- [`CFVariable$peek()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-peek)
- [`CFVariable$print()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-print)
- [`CFVariable$profile()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-profile)
- [`CFVariable$raw()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-raw)
- [`CFVariable$save()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-save)
- [`CFVariable$shard()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-shard)
- [`CFVariable$summarise()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-summarise)
- [`CFVariable$terra()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-terra)
- [`CFVariable$time()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-time)
- [`CFVariable$write()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-write)
- [`CFVariable$write_geozarr()`](https://r-cf.github.io/ncdfCF/reference/CFVariable.html#method-write_geozarr)

------------------------------------------------------------------------

### `CFVariableL3b$new()`

Create an instance of this class.

#### Usage

    CFVariableL3b$new(grp, units)

#### Arguments

- `grp`:

  The group that this CF variable lives in. Must be called
  "/level-3_binned_data".

- `units`:

  Vector of two character strings with the variable name and the
  physical units of the data variable in the netCDF resource.

#### Returns

An instance of this class.

------------------------------------------------------------------------

### `CFVariableL3b$subset()`

This method extracts a subset of values from the data of the variable,
with the range along both axes expressed in decimal degrees.

#### Usage

    CFVariableL3b$subset(..., rightmost.closed = FALSE)

#### Arguments

- `...`:

  One or more arguments of the form `axis = range`. The "axis" part
  should be the name of axis `longitude` or `latitude` or its
  orientation `X` or `Y`. The "range" part is a vector of values
  representing coordinates along the axis where to extract data. Axis
  designators and names are case-sensitive and can be specified in any
  order. If values for the range of an axis fall outside of the extent
  of the axis, the range is clipped to the extent of the axis.

- `rightmost.closed`:

  Single logical value to indicate if the upper boundary of range in
  each axis should be included.

#### Details

The range of values along both axes of latitude and longitude is
expressed in decimal degrees. Any axes for which no information is
provided in the `subset` argument are extracted in whole. Values can be
specified in a variety of ways that should (resolve to) be a vector of
real values. A range (e.g. `100:200`), a vector (`c(23, 46, 3, 45, 17`),
a sequence (`seq(from = 78, to = 100, by = 2`), all work. Note, however,
that only a single range is generated from the vector so these examples
resolve to `(100, 200)`, `(3, 46)`, and `(78, 100)`, respectively.

If the range of values for an axis in argument `subset` extend the valid
range of the axis in `x`, the extracted slab will start at the beginning
for smaller values and extend to the end for larger values. If the
values envelope the valid range the entire axis will be extracted in the
result. If the range of `subset` values for any axis are all either
smaller or larger than the valid range of the axis in `x` then nothing
is extracted and `NULL` is returned.

The extracted data has the same dimensional structure as the data in the
variable, with degenerate dimensions dropped. The order of the axes in
argument `subset` does not reorder the axes in the result; use the
[CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)\$array()
method for this.

#### Returns

A [CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
instance, having an array with axes and attributes of the variable, or
`NULL` if one or more of the elements in the `...` argument falls
entirely outside of the range of the axis. Note that degenerate
dimensions (having `length(.) == 1`) are dropped from the array but the
corresponding axis is maintained in the result as a scalar axis.
