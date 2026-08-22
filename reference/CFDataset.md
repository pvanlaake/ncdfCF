# CF data set

This class represents a CF data set, the object that encapsulates a
netCDF resource. You should never instantiate this class directly;
instead, call
[`open_ncdf()`](https://r-cf.github.io/ncdfCF/reference/open_ncdf.md)
which will return an instance that has all properties read from the
netCDF resource, or
[`create_ncdf()`](https://r-cf.github.io/ncdfCF/reference/create_ncdf.md)
for a new, empty instance. Class methods can then be called, or the base
R functions called with this instance.

The CF data set instance provides access to all the objects in the
netCDF resource, organized in groups.

## Public fields

- `name`:

  The name of the netCDF resource. This is extracted from the URI (file
  name or URL).

- `root`:

  Root of the group hierarchy through which all elements of the netCDF
  resource are accessed. It is **strongly discouraged** to manipulate
  the objects in the group hierarchy directly. Use the provided access
  methods instead.

- `file_type`:

  The type of data in the netCDF resource, if identifiable. In terms of
  the CF Metadata Conventions, this includes discrete sampling
  geometries (DSG). Other file types that can be identified include L3b
  files used by NASA and NOAA for satellite imagery (these data sets
  need special processing), and CMIP5, CMIP6 and CORDEX climate
  projection data.

## Active bindings

- `friendlyClassName`:

  (read-only) A nice description of the class.

- `resource`:

  (read-only) The connection details of the netCDF resource. This is for
  internal use only.

- `uri`:

  (read-only) The connection string to the netCDF resource.

- `conventions`:

  (read-only) Returns the conventions that this netCDF resource conforms
  to.

- `var_names`:

  (read-only) Vector of names of variables in this data set.

- `axis_names`:

  (read-only) Vector of names of axes in this data set.

## Methods

### Public methods

- [`CFDataset$new()`](#method-CFDataset-initialize)

- [`CFDataset$print()`](#method-CFDataset-print)

- [`CFDataset$hierarchy()`](#method-CFDataset-hierarchy)

- [`CFDataset$objects_by_standard_name()`](#method-CFDataset-objects_by_standard_name)

- [`CFDataset$has_subgroups()`](#method-CFDataset-has_subgroups)

- [`CFDataset$find_by_name()`](#method-CFDataset-find_by_name)

- [`CFDataset$variables()`](#method-CFDataset-variables)

- [`CFDataset$axes()`](#method-CFDataset-axes)

- [`CFDataset$attributes()`](#method-CFDataset-attributes)

- [`CFDataset$attribute()`](#method-CFDataset-attribute)

- [`CFDataset$set_attribute()`](#method-CFDataset-set_attribute)

- [`CFDataset$append_attribute()`](#method-CFDataset-append_attribute)

- [`CFDataset$delete_attribute()`](#method-CFDataset-delete_attribute)

- [`CFDataset$add_variable()`](#method-CFDataset-add_variable)

- [`CFDataset$save()`](#method-CFDataset-save)

- [`CFDataset$geozarr()`](#method-CFDataset-geozarr)

- [`CFDataset$clone()`](#method-CFDataset-clone)

------------------------------------------------------------------------

### `CFDataset$new()`

Create an instance of this class. Do not instantiate this class
directly; instead, call
[`open_ncdf()`](https://r-cf.github.io/ncdfCF/reference/open_ncdf.md)
which will return an instance that has all properties read from the
netCDF resource, or
[`create_ncdf()`](https://r-cf.github.io/ncdfCF/reference/create_ncdf.md)
for a new, empty instance.

#### Usage

    CFDataset$new(resource, format)

#### Arguments

- `resource`:

  An instance of `NCResource` that links to the netCDF resource, or a
  character string with the name of a new data set.

- `format`:

  Character string with the format of the netCDF resource as reported by
  the call opening the resource. Ignored when argument `resource` is a
  character string.

------------------------------------------------------------------------

### `CFDataset$print()`

Summary of the data set printed to the console.

#### Usage

    CFDataset$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

------------------------------------------------------------------------

### `CFDataset$hierarchy()`

Print the group hierarchy to the console.

#### Usage

    CFDataset$hierarchy()

------------------------------------------------------------------------

### `CFDataset$objects_by_standard_name()`

Get objects by standard_name. Several conventions define standard
vocabularies for physical properties. The standard names from those
vocabularies are usually stored as the "standard_name" attribute with
variables or axes. This method retrieves all variables or axes that list
the specified "standard_name" in its attributes.

#### Usage

    CFDataset$objects_by_standard_name(standard_name)

#### Arguments

- `standard_name`:

  Optional, a character string to search for a specific "standard_name"
  value in variables and axes.

#### Returns

If argument `standard_name` is provided, a character vector of variable
or axis names. If argument `standard_name` is missing or an empty
string, a named list with all "standard_name" attribute values in the
the netCDF resource; each list item is named for the variable or axis.

------------------------------------------------------------------------

### `CFDataset$has_subgroups()`

Does the netCDF resource have subgroups? Newer versions of the `netcdf`
library, specifically `netcdf4`, can organize dimensions and variables
in groups. This method will report if the data set is indeed organized
with subgroups.

#### Usage

    CFDataset$has_subgroups()

#### Returns

Logical to indicate that the netCDF resource uses subgroups.

------------------------------------------------------------------------

### `CFDataset$find_by_name()`

Find an object by its name. Given the name of a CF data variable or
axis, possibly preceded by an absolute group path, return the object to
the caller.

#### Usage

    CFDataset$find_by_name(name)

#### Arguments

- `name`:

  The name of a CF data variable or axis, with an optional absolute
  group path.

#### Returns

The object with the provided name. If the object is not found, returns
`NULL`.

------------------------------------------------------------------------

### `CFDataset$variables()`

This method lists the CF data variables located in this netCDF resource,
including those in subgroups.

#### Usage

    CFDataset$variables()

#### Returns

A list of `CFVariable` instances.

------------------------------------------------------------------------

### `CFDataset$axes()`

This method lists the axes located in this netCDF resource, including
axes in subgroups.

#### Usage

    CFDataset$axes()

#### Returns

A list of `CFAxis` descendants.

------------------------------------------------------------------------

### `CFDataset$attributes()`

List all the attributes of a group. This method returns a `data.frame`
containing all the attributes of the indicated `group`.

#### Usage

    CFDataset$attributes(group)

#### Arguments

- `group`:

  The name of the group whose attributes to return. If the argument is
  missing, the global attributes will be returned.

#### Returns

A `data.frame` of attributes.

------------------------------------------------------------------------

### `CFDataset$attribute()`

Retrieve global attributes of the data set.

#### Usage

    CFDataset$attribute(att, field = "value")

#### Arguments

- `att`:

  Vector of character strings of attributes to return.

- `field`:

  The field of the attribute to return values from. This must be "value"
  (default) or "type".

#### Returns

If the `field` argument is "type", a character string. If `field` is
"value", a single value of the type of the attribute, or a vector when
the attribute has multiple values. If no attribute is named with a value
of argument `att` `NA` is returned.

------------------------------------------------------------------------

### `CFDataset$set_attribute()`

Add an attribute to the global attributes. If an attribute `name`
already exists, it will be overwritten.

#### Usage

    CFDataset$set_attribute(name, type, value)

#### Arguments

- `name`:

  The name of the attribute. The name must begin with a letter and be
  composed of letters, digits, and underscores, with a maximum length of
  255 characters. UTF-8 characters are not supported in attribute names.

- `type`:

  The type of the attribute, as a string value of a netCDF data type.

- `value`:

  The value of the attribute. This can be of any supported type,
  including a vector or list of values. Matrices, arrays and like
  compound data structures should be stored as a data variable, not as
  an attribute and they are thus not allowed. In general, an attribute
  should be a character value, a numeric value, a logical value, or a
  short vector or list of any of these. Values passed in a list will be
  coerced to their common mode.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFDataset$append_attribute()`

Append the text value of a global attribute. If an attribute `name`
already exists, the `value` will be appended to the existing value of
the attribute. If the attribute `name` does not exist it will be
created. The attribute must be of "NC_CHAR" or "NC_STRING" type; in the
latter case having only a single string value.

#### Usage

    CFDataset$append_attribute(name, value, sep = "; ", prepend = FALSE)

#### Arguments

- `name`:

  The name of the attribute. The name must begin with a letter and be
  composed of letters, digits, and underscores, with a maximum length of
  255 characters. UTF-8 characters are not supported in attribute names.

- `value`:

  The character value of the attribute to append. This must be a
  character string.

- `sep`:

  The separator to use. Default is `"; "`.

- `prepend`:

  Logical to flag if the supplied `value` should be placed before the
  existing value. Default is `FALSE`.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFDataset$delete_attribute()`

Delete attributes. If an attribute `name` is not present this method
simply returns.

#### Usage

    CFDataset$delete_attribute(name)

#### Arguments

- `name`:

  Vector of names of the attributes to delete.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFDataset$add_variable()`

Add a
[CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
object to the data set. If there is another object with the same name in
the group where the data variable should be placed an error is thrown.
For objects associated with the data variable (such as axes, CRS,
boundary variables, etc), if another object with the same name is
otherwise identical to the associated object then that object will be
linked from the variable, otherwise an error is thrown.

#### Usage

    CFDataset$add_variable(var, group, locations = list())

#### Arguments

- `var`:

  An instance of `CFVariable` or any of its descendants.

- `group`:

  Optional. An instance of
  [CFGroup](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) where
  the data variable should be located. If omitted, the data variable
  will be stored in the root group.

- `locations`:

  Optional. A `list` whose named elements correspond to the names of
  objects associated with the data variable in argument `var`. Each list
  element has a single character string indicating the group in the
  hierarchy where the object should be stored. As an example, if the
  data variable has axes "lon" and "lat" and they should be stored in
  the parent group of `group`, then specify
  `locations = list(lon = "..", lat = "..")`. Locations can use absolute
  paths or relative paths from the `group`. Associated objects that are
  not in the list will be stored in `group`. If the argument `locations`
  is not provided, all associated objects will be stored in `group`.

#### Returns

Argument `var`, invisibly.

------------------------------------------------------------------------

### `CFDataset$save()`

Save the data set to file, including its subordinate objects such as
attributes, data variables, axes, CRS, etc.

#### Usage

    CFDataset$save(fn = NULL, pack = FALSE)

#### Arguments

- `fn`:

  Optional. Fully-qualified file name indicating where to save the data
  set to. This argument must be provided if the data set is virtual. If
  the argument is provided on a data set that was read from a netCDF
  file and it does not point to that netCDF file, a new netCDF file will
  be written to the indicated location. If the argument is the same file
  name as before, the existing netCDF file will be updated.

- `pack`:

  Optional. Logical to indicate if the data should be packed; default is
  `FALSE`. Packing is only useful for numeric data; packing is not
  performed on integer values. Packing is always to the "NC_SHORT" data
  type, i.e. 16-bits per value.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFDataset$geozarr()`

Save the data set to a Zarr store with GeoZarr conventions, including
its subordinate objects such as attributes, data variables, axes, CRS,
etc. Every principal `CFVariable` will become a `geozarr_array` and
every `CFGroup` a `zarr_group`. Ancillary data variables will typically
become a `zarr_array`, i.e. an array not having GeoZarr convention
attributes. Axes with regular coordinate values will be stored in the
attributes, saving space and reducing the number of such ancillary
arrays.

The data set will have the same hierarchy in the Zarr store as this data
set, possibly anchored in some subgroup inside the Zarr store. It is
highly recommended to use separate empty (or non-existing) groups to
anchor multiple data sets to avoid the possibility of name collisions.

Supported GeoZarr conventions for supplying coordinates are `cs` and
`spatial`. Due to the limited scope of the latter convention (North-up Y
coordinates, no support for time or vertical coordinates, 3 axes at
most) most Zarr arrays will use the `cs` convention. Supporting
conventions, like `proj` or `ref`, will be used as needed.

#### Usage

    CFDataset$geozarr(zarr, dataset_root = "/")

#### Arguments

- `zarr`:

  Optional. Fully-qualified file name or URI indicating where to save
  the data set to, or a `zarr` object. If a file name or URI, it must
  point to an existing Zarr store where the data from this dat aset will
  be appended, or a new Zarr store will be created by that name and then
  it can not already exist. By convention, a new Zarr store should have
  a ".zarr" file name extension. If missing, create a Zarr store in
  memory.

- `dataset_root`:

  Optional. Path to a node in the Zarr store where this data set will be
  anchored. If the node does not yet exist, it will be created. A path
  must start from the root node of the Zarr store and be specified like
  "/subgroup/sub/here" with the root of this data set starting at the
  indicated path. Defaults to the root of the Zarr store, "/".
  Alternatively, this may be a `zarr_group` to be used as the root for
  this data set, but only if argument `zarr` is a `zarr` object. If the
  `zarr` argument is not provided, this argument will be ignored.

#### Returns

The `zarr` object to which the data set was written.

------------------------------------------------------------------------

### `CFDataset$clone()`

The objects of this class are cloneable with this method.

#### Usage

    CFDataset$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
