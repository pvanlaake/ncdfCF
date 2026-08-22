# Examine a netCDF resource

This function will read a netCDF resource and return a list of
identifying information, including data variables, axes and global
attributes. Upon returning the netCDF resource is closed.

## Usage

``` r
peek_ncdf(resource)
```

## Arguments

- resource:

  The name of the netCDF resource to open, either a local file name or a
  remote URI.

## Value

A list with elements "variables", "axes" and global "attributes", each a
`data.frame`.

## Details

If you find that you need other information to be included in the
result, [open an issue](https://github.com/R-CF/ncdfCF/issues).

## Examples

``` r
fn <- system.file("extdata",
  "pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc",
  package = "ncdfCF")
peek_ncdf(fn)
#> $uri
#> [1] "/private/var/folders/gs/s0mmlczn4l7bjbmwfrrhjlt80000gn/T/RtmpkmkkEd/temp_libpath1819593f9ff9/ncdfCF/extdata/pr_day_EC-Earth3-CC_ssp245_r1i1p1f1_gr_20230101-20231231_vncdfCF.nc"
#> 
#> $type
#> [1] "CMIP6"
#> 
#> $variables
#>    id name     long_name      standard_name      units           axes
#> pr  4   pr Precipitation precipitation_flux kg m-2 s-1 lon, lat, time
#> 
#> $axes
#>                class id axis name long_name standard_name                 units
#> time      CFAxisTime  0    T time      time          time days since 1850-01-01
#> lon  CFAxisLongitude  2    X  lon Longitude     longitude          degrees_east
#> lat   CFAxisLatitude  3    Y  lat  Latitude      latitude         degrees_north
#>      length unlimited                                        values has_bounds
#> time    365      TRUE [2023-01-01T12:00:00 ... 2023-12-31T12:00:00]       TRUE
#> lon      14     FALSE                         [5.625 ... 14.765625]      FALSE
#> lat      14     FALSE                       [40.35078 ... 49.47356]      FALSE
#>      coordinate_sets
#> time               1
#> lon                1
#> lat                1
#> 
#> $attributes
#>                  name    type length
#> 1         Conventions NC_CHAR     15
#> 2              source NC_CHAR    546
#> 3          experiment NC_CHAR     30
#> 4       experiment_id NC_CHAR      6
#> 5  external_variables NC_CHAR      9
#> 6      institution_id NC_CHAR     19
#> 7             mip_era NC_CHAR      5
#> 8               title NC_CHAR     38
#> 9             license NC_CHAR    845
#> 10            comment NC_CHAR    112
#>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            value
#> 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                CF-1.7 CMIP-6.2
#> 2                                                                                                                                                                                                                                                                                                     EC-Earth3-CC (2019): \naerosol: none\natmos: IFS cy36r4 (TL255, linearly reduced Gaussian grid equivalent to 512 x 256 longitude/latitude; 91 levels; top level 0.01 hPa)\natmosChem: TM5 (3 x 2 degrees; 120 x 90 longitude/latitude; 34 levels; top level: 0.1 hPa)\nland: HTESSEL (land surface scheme built in IFS) and LPJ-GUESS v4\nlandIce: none\nocean: NEMO3.6 (ORCA1 tripolar primarily 1 degree with meridional refinement down to 1/3 degree in the tropics; 362 x 292 longitude/latitude; 75 levels; top grid cell 0-1 m)\nocnBgchem: PISCES v2\nseaIce: LIM3
#> 3                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 update of RCP4.5 based on SSP2
#> 4                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ssp245
#> 5                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      areacella
#> 6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            EC-Earth-Consortium
#> 7                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          CMIP6
#> 8                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         EC-Earth3-CC output prepared for CMIP6
#> 9  CMIP6 model data produced by EC-Earth-Consortium is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License (https://creativecommons.org/licenses). Consult https://pcmdi.llnl.gov/CMIP6/TermsOfUse for terms of use governing CMIP6 output, including citation requirements and proper acknowledgment. Further information about this data, including some limitations, can be found via the further_info_url (recorded as a global attribute in this file) and at http://www.ec-earth.org. The data producers and data providers make no warranty, either express or implied, including, but not limited to, warranties of merchantability and fitness for a particular purpose. All liabilities arising from the supply of the information (including any liability arising in negligence) are excluded to the fullest extent permitted by law.
#> 10                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              The netCDF file, including its attributes, has been modified for demonstration purposes for the R ncdfCF package
#> 
```
