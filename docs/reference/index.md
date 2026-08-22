# Package index

## Main ncdfCF classes and operations

### Opening and inspecting netCDF resources

NetCDF resources can be accessed on local (or networked) file systems,
or on THREDDS server on the internet. NetCDF resources are opened by
default for read-only access but local resources may be opened for
writing as well (THREDDS servers do not support writing).

- [`open_ncdf()`](https://r-cf.github.io/ncdfCF/reference/open_ncdf.md)
  : Open a netCDF resource
- [`peek_ncdf()`](https://r-cf.github.io/ncdfCF/reference/peek_ncdf.md)
  : Examine a netCDF resource

### Data set

The main object that the ncdfCF package presents to the R user is a
`CFDataset`. When opening an existing netCDF resource, the `CFDataset`
will provide access to all data variables and associated objects in the
resource, including its attributes, in a ready-made way for usage. The
CF Conventions will have been applied and the objects within the
`CFDataset` are thus fully formed and linked.

- [`create_ncdf()`](https://r-cf.github.io/ncdfCF/reference/create_ncdf.md)
  : Create a new data set

- [`as_CF()`](https://r-cf.github.io/ncdfCF/reference/as_CF.md) :

  Create a `CFDataset` or `CFVariable` instance from an R object

- [`CFDataset`](https://r-cf.github.io/ncdfCF/reference/CFDataset.md) :
  CF data set

- [`CFGroup`](https://r-cf.github.io/ncdfCF/reference/CFGroup.md) :
  Group for CF objects

- [`names(`*`<CFDataset>`*`)`](https://r-cf.github.io/ncdfCF/reference/dimnames.md)
  : Names or axis values of an CF object

- [`groups()`](https://r-cf.github.io/ncdfCF/reference/groups.md) : List
  the groups in the CF object, recursively.

- [`makeGroup()`](https://r-cf.github.io/ncdfCF/reference/makeGroup.md)
  : Create a new group

- [`` `[[`( ``*`<CFDataset>`*`)`](https://r-cf.github.io/ncdfCF/reference/sub-sub-.CFDataset.md)
  : Get a CF object from a data set

### Data variable

A data set can hold one or more data variables. A data variable is the
object that holds the data and descriptive metadata for a variable of
interest, such as daily maximum temperature. In R you can operate
directly on a data variable but it can also be subsetted, profiled and
summarised over the “time” dimension. It can be saved to a new netCDF
resource or exported to some other format.

- [`CFVariable`](https://r-cf.github.io/ncdfCF/reference/CFVariable.md)
  : CF data variable

- [`CFVariableL3b`](https://r-cf.github.io/ncdfCF/reference/CFVariableL3b.md)
  : CF data variable for the NASA L3b format

- [`CFGridMapping`](https://r-cf.github.io/ncdfCF/reference/CFGridMapping.md)
  : CF grid mapping object

- [`CFCellMeasure`](https://r-cf.github.io/ncdfCF/reference/CFCellMeasure.md)
  : CF cell measure variable

- [`CFAuxiliaryLongLat`](https://r-cf.github.io/ncdfCF/reference/CFAuxiliaryLongLat.md)
  : CF auxiliary longitude-latitude variable

- [`` `[`( ``*`<CFVariable>`*`)`](https://r-cf.github.io/ncdfCF/reference/sub-.CFVariable.md)
  : Extract data for a variable

- [`` `[`( ``*`<CFVariableL3b>`*`)`](https://r-cf.github.io/ncdfCF/reference/sub-.CFVariableL3b.md)
  : Extract data for a variable

- [`aoi()`](https://r-cf.github.io/ncdfCF/reference/aoi.md) : Area of
  Interest

- [`dim(`*`<AOI>`*`)`](https://r-cf.github.io/ncdfCF/reference/dim.AOI.md)
  : The dimensions of the grid of an AOI

- [`Ops(`*`<CFVariable>`*`)`](https://r-cf.github.io/ncdfCF/reference/arrayOps.md)
  [`Math(`*`<CFVariable>`*`)`](https://r-cf.github.io/ncdfCF/reference/arrayOps.md)
  : Operations on CFVariable objects

- [`geom_ncdf()`](https://r-cf.github.io/ncdfCF/reference/geom_ncdf.md)
  :

  Create a plot object for a `CFVariable`

### Axes

The shape of a data variable is described by the set of axes that it
links to. There are specialised axes for specific types of axes, such as
for longitude and latitude, or more generic types, each having their own
class inheriting from the “virtual” `CFAxis` class.

- [`makeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeAxis.md) :
  Create an axis
- [`makeCharacterAxis()`](https://r-cf.github.io/ncdfCF/reference/makeCharacterAxis.md)
  : Create a character axis
- [`makeDiscreteAxis()`](https://r-cf.github.io/ncdfCF/reference/makeDiscreteAxis.md)
  : Create a discrete axis
- [`makeLongitudeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeLongitudeAxis.md)
  : Create a longitude axis
- [`makeLatitudeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeLatitudeAxis.md)
  : Create a latitude axis
- [`makeTimeAxis()`](https://r-cf.github.io/ncdfCF/reference/makeTimeAxis.md)
  : Create a time axis
- [`makeVerticalAxis()`](https://r-cf.github.io/ncdfCF/reference/makeVerticalAxis.md)
  : Create a vertical axis
- [`CFAxis`](https://r-cf.github.io/ncdfCF/reference/CFAxis.md) : CF
  axis object
- [`CFAxisCharacter`](https://r-cf.github.io/ncdfCF/reference/CFAxisCharacter.md)
  : CF character axis object
- [`CFAxisDiscrete`](https://r-cf.github.io/ncdfCF/reference/CFAxisDiscrete.md)
  : CF discrete axis object
- [`CFAxisNumeric`](https://r-cf.github.io/ncdfCF/reference/CFAxisNumeric.md)
  : Numeric CF axis object
- [`CFAxisLongitude`](https://r-cf.github.io/ncdfCF/reference/CFAxisLongitude.md)
  : Longitude CF axis object
- [`CFAxisLatitude`](https://r-cf.github.io/ncdfCF/reference/CFAxisLatitude.md)
  : Latitude CF axis object
- [`CFAxisTime`](https://r-cf.github.io/ncdfCF/reference/CFAxisTime.md)
  : Time axis object
- [`CFAxisVertical`](https://r-cf.github.io/ncdfCF/reference/CFAxisVertical.md)
  : Vertical CF axis object
- [`CFVerticalParametricTerm`](https://r-cf.github.io/ncdfCF/reference/CFVerticalParametricTerm.md)
  : Parametric formula term for a vertical CF axis object
- [`CFLabel`](https://r-cf.github.io/ncdfCF/reference/CFLabel.md) : CF
  label object
- [`dim(`*`<CFAxis>`*`)`](https://r-cf.github.io/ncdfCF/reference/dim.CFAxis.md)
  : Axis length

### ncdfCF objects

This package uses many base classes to “glue” all the objects together.
In typical use of the package these classes are not very useful, the
higher-level objects encapsulate these low-level objects. For developers
it could be useful to study or directly access these classes.

- [`CFObject`](https://r-cf.github.io/ncdfCF/reference/CFObject.md) : CF
  base object
- [`CFBounds`](https://r-cf.github.io/ncdfCF/reference/CFBounds.md) : CF
  boundary variable
- [`CFData`](https://r-cf.github.io/ncdfCF/reference/CFData.md) : CF
  data object
- [`CFStandardNames`](https://r-cf.github.io/ncdfCF/reference/CFStandardNames.md)
  : CF Standard names table

### NetCDF objects

When opening an existing netCDF resource, or after writing a new netCDF
file, the contents of the netCDF resource are captured in a hierarchy of
NC objects. These objects are immutable for the R user because they
reflect what is in the resource.

- [`NCResource`](https://r-cf.github.io/ncdfCF/reference/NCResource.md)
  : NetCDF resource object
- [`NCObject`](https://r-cf.github.io/ncdfCF/reference/NCObject.md) :
  NetCDF base object
- [`NCGroup`](https://r-cf.github.io/ncdfCF/reference/NCGroup.md) :
  NetCDF group
- [`NCDimension`](https://r-cf.github.io/ncdfCF/reference/NCDimension.md)
  : NetCDF dimension object
- [`NCVariable`](https://r-cf.github.io/ncdfCF/reference/NCVariable.md)
  : NetCDF variable

### Other functions

Assorted other functions.

- [`aggregate_geozarr()`](https://r-cf.github.io/ncdfCF/reference/aggregate_geozarr.md)
  : Aggregate multiple CF files into GeoZarr arrays
