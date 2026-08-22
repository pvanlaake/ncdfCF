# Open a netCDF resource

This function will read the metadata of a netCDF resource and interpret
the netCDF dimensions, variables and attributes to generate the
corresponding CF objects. The data for the CF variables is not read,
please see
[CFVariable](https://r-cf.github.io/ncdfCF/reference/CFVariable.md) for
methods to read the variable data.

## Usage

``` r
open_ncdf(resource, write = FALSE)
```

## Arguments

- resource:

  The name of the netCDF resource to open, either a local file name or a
  remote URI.

- write:

  `TRUE` if the file is to be opened for writing, `FALSE` (default) for
  read-only access. Ignored for online resources, which are always
  opened for read-only access.

## Value

An `CFDataset` instance, or an error if the resource was not found or
errored upon reading.

## Examples

``` r
fn <- system.file("extdata",
  "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc",
  package = "ncdfCF")
(ds <- open_ncdf(fn))
#> <Dataset> pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF 
#> Resource   : /private/var/folders/gs/s0mmlczn4l7bjbmwfrrhjlt80000gn/T/RtmpkmkkEd/temp_libpath1819593f9ff9/ncdfCF/extdata/pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc 
#> Format     : netcdf4 
#> Collection : CMIP6 
#> Conventions: CF-1.7 CMIP-6.2 
#> Has groups : FALSE 
#> 
#> Variable:
#>  name long_name     units      data_type axes          
#>  pr   Precipitation kg m-2 s-1 NC_FLOAT  lon, lat, time
#> 
#> External variable: areacella
#> 
#> Attributes:
#>  name               type    length
#>  Conventions        NC_CHAR  15   
#>  source             NC_CHAR 546   
#>  experiment         NC_CHAR  30   
#>  experiment_id      NC_CHAR   6   
#>  external_variables NC_CHAR   9   
#>  institution_id     NC_CHAR  19   
#>  mip_era            NC_CHAR   5   
#>  title              NC_CHAR  38   
#>  license            NC_CHAR 845   
#>  comment            NC_CHAR 112   
#>  value                                               
#>  CF-1.7 CMIP-6.2                                     
#>  EC-Earth3-CC (2019): \naerosol: none\natmos: IFS ...
#>  update of RCP4.5 based on SSP2                      
#>  ssp245                                              
#>  areacella                                           
#>  EC-Earth-Consortium                                 
#>  CMIP6                                               
#>  EC-Earth3-CC output prepared for CMIP6              
#>  CMIP6 model data produced by EC-Earth-Consortiu...  
#>  The netCDF file, including its attributes, has ...  
```
