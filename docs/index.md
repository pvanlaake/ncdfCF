# ncdfCF

The `ncdfCF` package provides an easy to use interface to netCDF
resources in R, either in local files or remotely on a THREDDS server.
It is built on the `RNetCDF` package which, like package `ncdf4`,
provides a basic interface to the `netcdf` library, but which lacks an
intuitive user interface. Package `ncdfCF` provides a high-level
interface using functions and methods that are familiar to the R user.
It reads the structural metadata and also the attributes upon opening
the resource. In the process, the `ncdfCF` package also applies CF
Metadata Conventions to interpret the data.

## Basic usage

Opening and inspecting the contents of a netCDF resource is very
straightforward:

``` r

library(ncdfCF)

# Get any netCDF file
fn <- system.file("extdata", "ERA5land_Rwanda_20160101.nc", package = "ncdfCF")

# Open the file, all metadata is read
(ds <- open_ncdf(fn))
#> <Dataset> ERA5land_Rwanda_20160101 
#> Resource   : /Library/Frameworks/R.framework/Versions/4.6/Resources/library/ncdfCF/extdata/ERA5land_Rwanda_20160101.nc 
#> Format     : offset64 
#> Collection : Generic netCDF data 
#> Conventions: CF-1.6 
#> 
#> Variables:
#>  name long_name             units data_type axes                     
#>  t2m  2 metre temperature   K     NC_DOUBLE longitude, latitude, time
#>  pev  Potential evaporation m     NC_DOUBLE longitude, latitude, time
#>  tp   Total precipitation   m     NC_DOUBLE longitude, latitude, time
#> 
#> Attributes:
#>  name        type    length value                             
#>  Conventions NC_CHAR  6     CF-1.6                            
#>  history     NC_CHAR 34     Attributes simplified for example.
```

You can convert a suitable R object into a `CFVariable` instance quite
easily. R objects that are supported include arrays, matrices and
vectors of type logical, integer, numeric or logical.

If the R object has `dimnames` set, these will be used to create more
informed axes. More interestingly, if your array represents some spatial
data you can give your `dimnames` appropriate names (“lat”, “lon”,
“latitude”, “longitude”, case-insensitive) and the corresponding axis
will be created (if the coordinate values in the `dimnames` are within
the domain of the axis type). For “time” coordinates, these are
automatically detected irrespective of the name.

``` r

# Note the use of named dimnames: these will become the names of the axes
arr <- array(rnorm(120), dim = c(6, 5, 4))
dimnames(arr) <- list(lat = c(45, 44, 43, 42, 41, 40), lon = c(0, 1, 2, 3, 4), 
                      time = c("2025-07-01", "2025-07-02", "2025-07-03", "2025-07-04"))

(obj <- as_CF("a_new_CF_object", arr))
#> <Variable> a_new_CF_object 
#> 
#> Values: [-2.54328 ... 2.501505] 
#>     NA: 0 (0.0%)
#> 
#> Axes:
#>  axis name length values                      unit                          
#>  Y    lat  6      [45 ... 40]                 degrees_north                 
#>  X    lon  5      [0 ... 4]                   degrees_east                  
#>  T    time 4      [2025-07-01 ... 2025-07-04] days since 1970-01-01T00:00:00
#> 
#> Attributes:
#>  name         type      length value             
#>  actual_range NC_DOUBLE 2      -2.54328, 2.501505

# Axes are of a specific type and have basic attributes set
obj$axes[["lat"]]
#> <Latitude axis> [-2] lat
#> Length     : 6
#> Axis       : Y 
#> Coordinates: 45, 44, 43, 42, 41, 40 (degrees_north)
#> Bounds     : (not set)
#> 
#> Attributes:
#>  name          type      length value        
#>  actual_range  NC_DOUBLE  2     40, 45       
#>  axis          NC_CHAR    1     Y            
#>  standard_name NC_CHAR    8     latitude     
#>  units         NC_CHAR   13     degrees_north

obj$axes[["time"]]
#> <Time axis> [-4] time
#> Length     : 4
#> Axis       : T 
#> Calendar   : standard 
#> Range      : 2025-07-01 ... 2025-07-04 (days) 
#> Bounds     : (not set) 
#> 
#> Attributes:
#>  name          type      length value                         
#>  actual_range  NC_DOUBLE  2     20270, 20273                  
#>  axis          NC_CHAR    1     T                             
#>  standard_name NC_CHAR    4     time                          
#>  units         NC_CHAR   30     days since 1970-01-01T00:00:00
#>  calendar      NC_CHAR    8     standard
```

You can further modify the resulting `CFVariable` by setting other
properties, such as attributes or a coordinate reference system. Once
the object is complete, you can export or save it.

More detailed operations and options are given on the [package web
site](https://r-cf.github.io/ncdfCF/).

## Development plan

Package `ncdfCF` currently supports reading of all data objects from
netCDF resources in “classic” and “netcdf4” formats; and can write data
variables back to a netCDF file. From the CF Metadata Conventions it
supports identification of axes, interpretation of the “time” axis, name
resolution when using groups, cell boundary information, auxiliary
coordinate variables, labels, cell measures, attributes and grid mapping
information, among others.

Development plans for the near future focus on supporting the below
features:

##### netCDF

- Writing data to an unlimited dimension of a data variable.

##### CF Metadata Conventions

- Cell methods.
- Support for discrete sampling geometries.
- Compliance with CMIP5 / CMIP6 requirements.

## Installation

While package `ncdfCF` is extensively tested on multiple well-structured
data sets, errors may still occur, particularly in data sets that do not
adhere to the CF Metadata Conventions. The API may still change and
although care is taken not to make breaking changes, sometimes this is
unavoidable.

Installation from CRAN of the latest release:

``` R
install.packages("ncdfCF")
```

You can install the development version of `ncdfCF` from
[GitHub](https://github.com/) with:

``` R
# install.packages("devtools")
devtools::install_github("R-CF/ncdfCF")
```
