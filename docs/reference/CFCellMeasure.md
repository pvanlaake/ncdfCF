# CF cell measure variable

This class represents a CF cell measure variable, the object that
indicates the area or volume of every grid cell in referencing data
variables.

If a cell measure variable is external to the current file, an instance
will still be created for it, but the user must link the external file
to this instance before it can be used in analysis.

## Active bindings

- `measure`:

  (read-only) Retrieve the measure of this instance. Either "area" or
  "volume".

- `name`:

  The name of this instance, which must refer to a NC variable or an
  external variable.

## Methods

### Public methods

- [`CFCellMeasure$new()`](#method-CFCellMeasure-initialize)

- [`CFCellMeasure$print()`](#method-CFCellMeasure-print)

- [`CFCellMeasure$data()`](#method-CFCellMeasure-data)

- [`CFCellMeasure$register()`](#method-CFCellMeasure-register)

- [`CFCellMeasure$link()`](#method-CFCellMeasure-link)

- [`CFCellMeasure$detach()`](#method-CFCellMeasure-detach)

- [`CFCellMeasure$clone()`](#method-CFCellMeasure-clone)

------------------------------------------------------------------------

### `CFCellMeasure$new()`

Create an instance of this class. The instance may be based on a NC
variable contained in the same resource as the referencing data
variable, or it may be external. If internal, the CF variable will be
created in the CF group that manages the NC group where the NC variable
is located.

#### Usage

    CFCellMeasure$new(measure, name, nc_var = NULL, axes = NULL)

#### Arguments

- `measure`:

  The measure of this object. Must be either of "area" or "volume".

- `name`:

  The name of the cell measure variable. Ignored if argument `nc_var` is
  specified.

- `nc_var`:

  The netCDF variable that defines this CF cell measure object. `NULL`
  for an external variable.

- `axes`:

  List of [CFAxis](https://r-cf.github.io/ncdfCF/reference/CFAxis.md)
  instances that describe the dimensions of the cell measure object.
  `NULL` for an external variable.

#### Returns

An instance of this class.

------------------------------------------------------------------------

### `CFCellMeasure$print()`

Print a summary of the cell measure variable to the console.

#### Usage

    CFCellMeasure$print(...)

#### Arguments

- `...`:

  Arguments passed on to other functions. Of particular interest is
  `width = ` to indicate a maximum width of attribute columns.

------------------------------------------------------------------------

### `CFCellMeasure$data()`

Retrieve the values of the cell measure variable.

#### Usage

    CFCellMeasure$data()

#### Returns

The values of the cell measure as a
[CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
instance.

------------------------------------------------------------------------

### `CFCellMeasure$register()`

Register a
[CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
which is using this cell measure variable. A check is performed on the
compatibility between the data variable and this cell measure variable.

#### Usage

    CFCellMeasure$register(var)

#### Arguments

- `var`:

  A `CFVariable` instance to link to this instance.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFCellMeasure$link()`

Link the cell measure variable to an external netCDF resource. The
resource will be opened and the appropriate data variable will be linked
to this instance. If the axes or other properties of the external
resource are not compatible with this instance, an error will be raised.

#### Usage

    CFCellMeasure$link(resource)

#### Arguments

- `resource`:

  The name of the netCDF resource to open, either a local file name or a
  remote URI.

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFCellMeasure$detach()`

Detach the internal data variable from an underlying netCDF resource.

#### Usage

    CFCellMeasure$detach()

#### Returns

Self, invisibly.

------------------------------------------------------------------------

### `CFCellMeasure$clone()`

The objects of this class are cloneable with this method.

#### Usage

    CFCellMeasure$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
