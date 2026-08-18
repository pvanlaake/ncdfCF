# Standard names for grid mappings
CRS_names <- c("albers_conical_equal_area", "azimuthal_equidistant",
               "geostationary", "lambert_azimuthal_equal_area",
               "lambert_conformal_conic", "lambert_cylindrical_equal_area",
               "latitude_longitude", "mercator", "oblique_mercator",
               "orthographic", "polar_stereographic",
               "rotated_latitude_longitude", "sinusoidal", "stereographic",
               "transverse_mercator", "vertical_perspective")

#' CF grid mapping object
#'
#' @description This class contains the details for a coordinate reference
#' system, or grid mapping in CF terms, of a data variable.
#'
#' When reporting the coordinate reference system to the caller, a character
#' string in WKT2 format is returned, following the OGC standard.
#'
#' @references https://docs.ogc.org/is/18-010r11/18-010r11.pdf
#' https://cfconventions.org/cf-conventions/cf-conventions.html#appendix-grid-mappings
#'
#' @docType class
CFGridMapping <- R6::R6Class("CFGridMapping",
  inherit = CFObject,
  cloneable = FALSE,
  private = list(
    # The formal grid mapping name as defined in CF
    .grid_mapping_name = "latitude_longitude",

    # === CF grid_mapping_name METHOD & PARAMETER rendering ====================
    aea = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      wkt2 <- paste0('METHOD["Albers Equal Area",', .wkt2_id(9822), ']')
      if (!is.na(lat0 <- self$attribute("latitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of false origin",', lat0, ',', angle, ']')
      if (!is.na(lon0 <- self$attribute("longitude_of_central_meridian")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of false origin",', lon0, ',', angle, ']')
      if (!is.na(lat1 <- self$attribute("standard_parallel")) && length(lat1) == 2L)
        wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of 1st standard parallel",', lat1[1L], ',', angle, ']',
                             ',PARAMETER["Latitude of 2nd standard parallel",', lat1[2L], ',', angle, ']')

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (!(is.na(fe) && is.na(fn))) {
        if (is.na(fe)) fe <- 0
        if (is.na(fn)) fn <- 0
        wkt2 <- paste0(wkt2, ',PARAMETER["Easting at false origin",', fe, ',', length,
                             '],PARAMETER["Northing at false origin",', fn, ',', length, ']')
      }
      wkt2
    },

    aeqd = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      wkt2 <- paste0('METHOD["Azimuthal Equidistant",', .wkt2_id(1125), ']')
      if (!is.na(lat0 <- self$attribute("latitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']')
      if (!is.na(lon0 <- self$attribute("longitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']')

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (!(is.na(fe) && is.na(fn))) {
        if (is.na(fe)) fe <- 0
        if (is.na(fn)) fn <- 0
        wkt2 <- paste0(wkt2, ',PARAMETER["Easting at false origin",', fe, ',', length,
                       '],PARAMETER["Northing at false origin",', fn, ',', length, ']')
      }
      wkt2
    },

    geos = function() {
      # Not in the EPSG database

      if (is.na(h <- self$attribute("perspective_point_height"))) h <- 0
      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0
      if (is.na(sweep <- self$attribute("sweep_angle_axis")))
        if (is.na(sweep <- self$attribute("fixed_angle_axis")))
          sweep <- 'y'
        else
          sweep <- c('x', 'y')[as.integer(sweep == 'x') + 1L]

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      paste0('METHOD["PROJ geos h=', h, ' lon_0=', lon0, ' sweep=', sweep, fe_fn, '"]')
    },

    laea = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      wkt2 <- paste0('METHOD["Lambert Azimuthal Equal Area",', .wkt2_id(9820), ']')
      if (!is.na(lat0 <- self$attribute("latitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, 'PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']')
      if (!is.na(lon0 <- self$attribute("longitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, 'PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']')

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (!(is.na(fe) && is.na(fn))) {
        if (is.na(fe)) fe <- 0
        if (is.na(fn)) fn <- 0
        wkt2 <- paste0(wkt2, ',PARAMETER["Easting at false origin",', fe, ',', length,
                       '],PARAMETER["Northing at false origin",', fn, ',', length, ']')
      }
      wkt2
    },

    lcc = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.
      # For EPSG:9801 "Scale factor at natural origin" is 1 and not specified in an attribute!

      lat1 <- self$attribute("standard_parallel")
      if (all(is.na(lat1))) return("")
      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")

      lat0 <- self$attribute("latitude_of_projection_origin")
      lon0 <- self$attribute("longitude_of_central_meridian")
      if (length(lat1) == 1L) {
        wkt2 <- paste0('METHOD["Lambert Conic Conformal (1SP)",', .wkt2_id(9801), ']')
        if (!is.na(lat0))
          wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']')
        if (!is.na(lon0))
          wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']')
        wkt2 <- paste0(wkt2, ',PARAMETER["Scale factor at natural origin",1,', .wkt2_uom(9201), ']')
        if (!(is.na(fe) && is.na(fn))) {
          if (is.na(fe)) fe <- 0
          if (is.na(fn)) fn <- 0
          wkt2 <- paste0(wkt2, ',PARAMETER["False easting",', fe, ',', length,
                         '],PARAMETER["False northing",', fn, ',', length, ']')
        }
      } else {
        wkt2 <- paste0('METHOD["Lambert Conic Conformal (2SP)",', .wkt2_id(9802), ']')
        if (!is.na(lat0))
          wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of false origin",', lat0, ',', angle, ']')
        if (!is.na(lon0))
          wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of false origin",', lon0, ',', angle, ']')
        wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of 1st standard parallel",', lat1[1L], ',', angle, ']',
                             ',PARAMETER["Latitude of 2nd standard parallel",', lat1[2L], ',', angle, ']')

        if (!(is.na(fe) && is.na(fn))) {
          if (is.na(fe)) fe <- 0
          if (is.na(fn)) fn <- 0
          wkt2 <- paste0(wkt2, ',PARAMETER["Easting at false origin",', fe, ',', length,
                              '],PARAMETER["Northing at false origin",', fn, ',', length, ']')
        }
      }
      wkt2
    },

    lcea = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.
      # FIXME: EPSG:9834 is on a spheroid

      wkt2 <- paste0('METHOD["Lambert Cylindrical Equal Area",', .wkt2_id(9835),
                     '],PARAMETER["Latitude of 1st standard parallel",0,', angle, ']')
      if (!is.na(lon0 <- self$attribute("longitude_of_central_meridian")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']')

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (!(is.na(fe) && is.na(fn))) {
        if (is.na(fe)) fe <- 0
        if (is.na(fn)) fn <- 0
        wkt2 <- paste0(wkt2, ',PARAMETER["Easting at false origin",', fe, ',', length,
                       '],PARAMETER["Northing at false origin",', fn, ',', length, ']')
      }
      wkt2
    },

    merc = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0
      if (is.na(lat0 <- self$attribute("standard_parallel"))) lat0 <- 0
      if (is.na(scl <- self$attribute("scale_factor_at_projection_origin"))) scl <- 1

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      if (scl != 1) {
        paste0('METHOD["Mercator (variant A)",', .wkt2_id(9804), ']',
               ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']',
               ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
               ',PARAMETER["Scale factor at natural origin",', scl, ',', .wkt2_uom(9201), ']',
               fe_fn)
      } else {
        paste0('Mercator (variant B)",', .wkt2_id(9805), ']',
               ',PARAMETER["Latitude of 1st standard parallel",', lat0, ',', angle, ']',
               ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
               fe_fn)
      }
    },

    omerc = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      wkt2 <- paste0('METHOD["Hotine Oblique Mercator (variant B)",', .wkt2_id(9815), ']')
      if (!is.na(lat0 <- self$attribute("latitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Latitude of projection center",', lat0, ',', angle, ']')
      if (!is.na(lon0 <- self$attribute("longitude_of_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Longitude of projection center",', lon0, ',', angle, ']')
      if (!is.na(az <- self$attribute("azimuth_of_central_line")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Azimuth at projection center",', az, ',', angle, ']')
      if (!is.na(k0 <- self$attribute("scale_factor_at_projection_origin")))
        wkt2 <- paste0(wkt2, ',PARAMETER["Scale factor at projection center",', k0, ',', .wkt2_uom(9201), ']')

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (!(is.na(fe) && is.na(fn))) {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fng <- 0
        wkt2 <- paste0(wkt2, ',PARAMETER["Easting at projection center",', fe, ',', length,
                            '],PARAMETER["Northing at projection center",', fn, ',', length, ']')
      }
      wkt2
    },

    ortho = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0
      if (is.na(lat0 <- self$attribute("latitude_of_projection_origin"))) lat0 <- 0

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      paste0('METHOD["Orthographic",', .wkt2_id(9840), ']',
             ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']',
             ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
             fe_fn)
    },

    ps = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin")))
        if (is.na(lon0 <- self$attribute("straight_vertical_longitude_from_pole")))
          lon0 <- 0
      if (is.na(lat0 <- self$attribute("latitude_of_projection_origin")))lat0 <- 0

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      if (!is.na(scl <- self$attribute("scale_factor_at_projection_origin"))) {
        paste0('METHOD["Polar Stereographic (variant A)",', .wkt2_id(9810), ']',
               ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']',
               ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
               ',PARAMETER["Scale factor at natural origin",', scl, ',', .wkt2_uom(9201), ']',
               fe_fn)
      } else {
        if (is.na(latts <- sef$attribute("standard_parallel"))) latts <- 0
        paste0('METHOD["Polar Stereographic (variant B)",', .wkt2_id(9829), ']',
               ',PARAMETER["Latitude of standard parallel",', latts, ',', angle, ']',
               ',PARAMETER["Longitude of origin",', lon0, ',', angle, ']',
               fe_fn)
      }
    },

    rot = function() {
      # The rotated latitude and longitude coordinates are identified by the standard_name attribute
      # values grid_latitude and grid_longitude respectively.
      # Not in the EPSG database
      # CF argument north_pole_grid_longitude not used

      # The below is not elegant, but it fixes incomplete specification
      if (is.na(lat <- self$attribute("grid_north_pole_latitude"))) lat <- 0
      if (is.na(lon <- self$attribute("grid_north_pole_longitude"))) lon <- 0

      paste0('METHOD["PROJ ob_tran o_proj=latlon o_lat_p=', lat, ' o_lon_p=', lon, '"]')
    },

    sinus = function() {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.
      # Not in the EPSG database

      lon0 <- if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      paste0('METHOD["PROJ sinu o_lon=', lon0, fe_fn, '"]')
    },

    stereo = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.

      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0
      if (is.na(lat0 <- self$attribute("latitude_of_projection_origin"))) lat0 <- 0
      if (is.na(scl <- self$attribute("scale_factor_at_projection_origin"))) scl <- 1

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      paste0('METHOD["Oblique Stereographic",', .wkt2_id(9809), ']',
             ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']',
             ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
             ',PARAMETER["Scale factor at natural origin",', scl, ',', .wkt2_uom(9201), ']',
             fe_fn)
    },

    tmerc = function(angle, length) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.
      # EPSG:9807

      if (is.na(lon0 <- self$attribute("longitude_of_central_meridian"))) lon0 <- 0
      if (is.na(lat0 <- self$attribute("latitude_of_projection_origin"))) lat0 <- 0
      if (is.na(scl <- self$attribute("scale_factor_at_central_meridian"))) scl <- 1

      fe <- self$attribute("false_easting")
      fn <- self$attribute("false_northing")
      if (is.na(fe) && is.na(fn))
        fe_fn <- ''
      else {
        if (is.null(fe)) fe <- 0
        if (is.null(fn)) fn <- 0
        fe_fn <- paste0(' x_0=', fe, ' y_0=', fn)
      }

      paste0('METHOD["Transverse Mercator",', .wkt2_id(9807), ']',
             ',PARAMETER["Latitude of natural origin",', lat0, ',', angle, ']',
             ',PARAMETER["Longitude of natural origin",', lon0, ',', angle, ']',
             ',PARAMETER["Scale factor at natural origin",', scl, ',', .wkt2_uom(9201), ']',
             fe_fn)
    },

    persp = function(angle) {
      # The x (abscissa) and y (ordinate) rectangular coordinates are identified by the standard_name
      # attribute values projection_x_coordinate and projection_y_coordinate respectively.
      # CF parameters false_easting and false_northing not used in EPSG

      if (is.na(h <- self$attribute("perspective_point_height"))) h <- 0
      if (is.na(lon0 <- self$attribute("longitude_of_projection_origin"))) lon0 <- 0
      if (is.na(lat0 <- self$attribute("latitude_of_projection_origin"))) lat0 <- 0

      paste0('METHOD["Vertical Perspective",', .wkt2_id(9838), ']',
             ',PARAMETER["Latitude of topocentric origin",', lat0, ',', angle, ']',
             ',PARAMETER["Longitude of topocentric origin",', lon0, ',', angle, ']',
             ',PARAMETER["Viewpoint height",', h, ',', .wkt2_uom(9001), ']')
    },

    # === CRS objects ==========================================================

    # This method creates an UOM WKT2 string from a specified UOM name. This is
    # typically called to describe the UOM of CFVariable axes for the CS section
    # of a full WKT2 string for a CFVariable instance.
    # Known aliases (by the EPSG database) are interpreted correctly, with the
    # resulting WKT2 string using the default name of the UOM. If no alias is
    # found, the method returns an empty string, otherwise the WKT2 string.
    # If argument `id` is `TRUE`, include an ID section, exclude otherwise.
    uom = function(name, id = FALSE) {
      if (name %in% c("degrees", "meters", "kilometers", "metres", "kilometres",
                      "seconds", "minutes", "hours", "days", "months", "years"))
        name <- trimws(name, whitespace = "s")
      details <- epsg_uom[epsg_uom$unit_of_meas_name == name, ]
      if (nrow(details)) .wkt2_uom(details$uom_code, id)
      else {
        details <- epsg_uom_alias[epsg_uom_alias$alias == name, ]
        if (nrow(details)) .wkt2_uom(details$object_code, id)
        else return('')
      }
    },

    # Create an ellipsoid WKT2 from attributes by finding an EPSG code by (1)
    # name or (2) other attributes, or (3) otherwise a "manual" string from
    # attributes, or (4) an empty string if no attributes are present, in that
    # order. Note that the semi_major_axis, semi_minor_axis and earth_radius are
    # required to be in meters, meaning that 9 EPSG ellipsoids cannot be
    # represented through attributes.
    ellipsoid = function() {
      # (1) Find an EPSG code by name, set ellipsoid name otherwise
      if (is.na(ell_name <- self$attribute("reference_ellipsoid_name")))
        ell_name <- 'unknown'
      else {
        epsg_code <- epsg_ell[epsg_ell$ellipsoid_name == ell_name, "ellipsoid_code"]
        if (length(epsg_code)) return(.wkt2_ellipsoid(epsg_code))
      }

      a <- self$attribute("semi_major_axis")
      b <- self$attribute("semi_minor_axis")
      invf <- self$attribute("inverse_flattening")
      r <- self$attribute("earth_radius")

      # (2) Find an EPSG code by set of attributes
      details <- if (is.na(a)) {
        if (is.na(r)) data.frame()
        else epsg_ell[isTRUE(all.equal(epsg_ell$semi_major_axis, r)), ]
      } else {
        if (!is.na(invf))
          epsg_ell[isTRUE(all.equal(c(epsg_ell$semi_major_axis, epsg_ell$inv_flattening), c(a, invf))), ]
        else if (!is.na(b))
          epsg_ell[isTRUE(all.equal(c(epsg_ell$semi_major_axis, epsg_ell$semi_minor_axis), c(a, b))), ]
        else
          epsg_ell[isTRUE(all.equal(c(epsg_ell$semi_major_axis, epsg_ell$semi_minor_axis), c(a, a))), ]
      }

      if (nrow(details) == 1L)
        .wkt2_ellipsoid(details$ellipsoid_code)
      else {
        # (3) Manual WKT
        uom <- .wkt2_uom(9001L) # CF only supports meter uom
        if (!is.na(a)) {
          if (is.na(invf))
            invf <- if (is.na(b)) 0 else a / (a - b)
          paste0('ELLIPSOID["', ell_name, '",', a, ',', invf, ',', uom, ']')
        } else if (!is.na(r)) {
          paste0('ELLIPSOID["', ell_name, '",', r, ',0,', uom, ']')
        } else '' # (4) fail
      }
    },

    # Create a prime meridian WKT2 from attributes by finding an EPSG code by
    # name or longitude, or an empty string if no attributes are present.
    # The return value is a list with two elements: WKT2 holds the WKT2 string,
    # ANGLEUNIT holds the EPSG code of the UOM.
    prime_meridian = function() {
      details <- if (!is.na(pm <- self$attribute("prime_meridian_name"))) {
        epsg_pm[epsg_pm$prime_meridian_name == pm, ]
      } else if (!is.na(lon <- self$attribute("longitude_of_prime_meridian"))) {
        epsg_pm[isTRUE(all.equal(epsg_pm$greenwich_longitude, lon)), ]
      } else data.frame()
      if (nrow(details)) list(WKT2 = .wkt2_pm(details$prime_meridian_code), ANGLEUNIT = details$uom_code)
      else list(WKT2 = '', ANGLEUNIT = 9102)
    },

    # Return the EPSG code of the ANGLEUNIT of the prime meridian used by the
    # geodetic datum or its ensemble.
    datum_angleunit = function(epsg_code) {
      datum <- epsg_datum[epsg_datum$datum_code == epsg_code, ]
      if (datum$datum_type == "vertical")
        stop("Only call this function for a geodetic datum.")

      if (datum$datum_type == "ensemble") {
        members <- epsg_datum_ensemble[epsg_datum_ensemble$datum_ensemble_code == datum$datum_code, ]
        datum <- epsg_datum[epsg_datum$datum_code == members$member_code[1L], ]
      }

      epsg_pm[epsg_pm$prime_meridian_code == datum$prime_meridian_code[1L], "uom_code"]
    },

    # Create a geodetic datum WKT2 from attributes by finding an EPSG code by
    # name. If there is no attribute to name the datum or the name is not
    # present in the EPSG database, an ellipsoid is sought for. If an ellipsoid
    # is found, a "manual" WKT is made, possibly with a prime meridian if
    # specified. Otherwise a WGS84 datum is returned, as the default. Note that
    # this procedure extends the CF guidance, which requires that any name be
    # a valid EPSG database datum name.
    # The return value is a list with two elements: WKT2 holds the WKT2 string,
    # ANGLEUNIT holds the EPSG code of the UOM used by the datum
    datum_geo = function() {
      dtm_name <- self$attribute("horizontal_datum_name")

      # EPSG datum from attribute name
      if (!is.na(dtm_name)) {
        dtm_code <- epsg_datum[epsg_datum$cf_name == dtm_name, "datum_code"]
        if (!length(dtm_code))
          dtm_code <- epsg_datum[epsg_datum$datum_name == dtm_name, "datum_code"]
        if (length(dtm_code))
          return(list(source = "EPSG", WKT2 = .wkt2_datum_geo(dtm_code), ANGLEUNIT = private$datum_angleunit(dtm_code)))
      } else dtm_name <- 'WGS1984'

      # Manual
      ellipsoid <- private$ellipsoid()
      if (nzchar(ellipsoid)) {
        pm <- private$prime_meridian()
        if (nzchar(pm$WKT2)) pm$WKT2 <- paste0(',', pm$WKT2)
        list(source = "manual", WKT2 = paste0('DATUM["', dtm_name, '",', ellipsoid, ']', pm$WKT2), ANGLEUNIT = pm$ANGLEUNIT)
      } else
        list(source = "default", WKT2 = .wkt2_datum_geo(6326L), ANGLEUNIT = private$datum_angleunit(6326L))
    },

    datum_vert = function(name) {
      details <- epsg_datum[epsg_datum$datum_name == name, ]
      if (nrow(details) == 1L)
        .wkt2_datum_vert(details$datum_code)
      else paste0('VDATUM["', name, '"]')
    },

    # Coordinate system
    coordsys = function(epsg_code) {
      # FIXME: axis ordering
      .wkt2_coordsys(epsg_code)
    },

    # Either the epsg_code argument or the name argument has to be specified. If
    # both are specified, the name argument will be ignored.
    # The name argument is not unique. If zero or multiple rows are found, an
    # empty string is returned and a WKT will have to be constructed from other
    # supplied parameters, except when multiple rows are found and the
    # grid_mapping_name is "latitude_longitude" which will select the
    # "geographic 2D" version of the CRS (which should be always present).
    geo_crs = function(epsg_code = NULL, name = NULL) {
      if (is.null(epsg_code)) {
        details <- epsg_geo_crs[epsg_geo_crs$coord_ref_sys_name == name, ]
        if (!nrow(details)) return('')
        if (nrow(details) > 1L) {
          if (private$.grid_mapping_name == "latitude_longitude")
            details <- details[details$coord_ref_sys_kind == "geographic 2D", ]
          else return('')
        }
        epsg_code <- details$coord_ref_sys_code
      }

      .wkt2_crs_geo(epsg_code)
    },

    # Either the epsg_code argument or the name argument has to be specified. If
    # both are specified, the name argument will be ignored.
    # The arguments may refer to a projected CRS or a compound CRS.
    #
    # A PROJCRS always has a base_crs_code, projection_conv_code and coord_sys_code
    proj_crs = function(epsg_code = NULL, name = NULL) {
      if (!is.null(epsg_code)) {
        details <- epsg_proj_crs[epsg_proj_crs$coord_ref_sys_code == epsg_code, ]
        if (nrow(details) == 0L) return(private$cmpd_crs(epsg_code, name))
      } else if (!is.null(name)) {
        details <- epsg_proj_crs[epsg_proj_crs$coord_ref_sys_name == name, ]
        if (nrow(details) == 0L)  return(private$cmpd_crs(epsg_code, name))
        if (nrow(details) > 1L) {
          warning(paste0("Multiple CRS entries found for '", name, "'. Using the first entry."))
          details <- details[1L, ]
        }
      } else return('')

      paste0('PROJCRS["', details$coord_ref_sys_name, '",',
             .wkt2_crs_base(details$base_crs_code), ',',
             .wkt2_conversion(details$projection_conv_code), ',',
             private$coordsys(details$coord_sys_code), ',',
             .wkt2_id(details$coord_ref_sys_code), ']')
    },

    vert_crs = function(epsg_code) {
      .wkt2_crs_vert(epsg_code)
    },

    # Either the epsg_code argument or the name argument has to be specified. If
    # both are specified, the name argument will be ignored.
    cmpd_crs = function(epsg_code = NULL, name = NULL) {
      if (is.null(epsg_code)) {
        details <- epsg_cmpd_crs[epsg_cmpd_crs$coord_ref_sys_name == name, ]
        if (nrow(details) == 0L)  return('')
        epsg_code <- details$coord_ref_sys_code
      }

      .wkt2_crs_compound(epsg_code)
    }
  ),
  public = list(
    #' @description Create a new instance of this class.
    #'
    #'   Note that when a new grid mapping object is created (as opposed to
    #'   reading from a netCDF resource), only the `grid_mapping_name` attribute
    #'   will be set. The caller must set all other parameters through their
    #'   respective attributes, following the CF Metadata Conventions.
    #' @param var When creating a new grid mapping object, the name of the
    #'   object. When reading from a netCDF resource, the netCDF variable that
    #'   describes this instance.
    #' @param group The [CFGroup] that this instance will live in.
    #' @param grid_mapping_name Optional. When creating a new grid mapping
    #'   object, the formal name of the grid mapping, as specified in the CF
    #'   Metadata Conventions. This value is stored in the new object as
    #'   attribute "grid_mapping_name". Ignored when argument `var` is a NC
    #'   object.
    initialize = function(var, group, grid_mapping_name) {
      super$initialize(var, group = group)

      if (is.character(var)) {
        if (missing(grid_mapping_name))
          stop("Must provide the `grid_mapping_name` argument when creating a new grid mapping object.", call. = FALSE) # nocov
        grid_mapping_name <- grid_mapping_name[1L]
        if (!(grid_mapping_name %in% CRS_names))
          stop("Unrecognized grid mapping name.", call. = FALSE) # nocov
        private$.grid_mapping_name <- grid_mapping_name
        self$set_attribute("grid_mapping_name", "NC_CHAR", grid_mapping_name)
      } else
        private$.grid_mapping_name <- self$attribute("grid_mapping_name")
    },

    #' @description Prints a summary of the grid mapping to the console.
    print = function() {
      cat("<Grid mapping>", self$name, "\n")
      cat("Grid mapping name:", private$.grid_mapping_name, "\n")
      if (self$group$name != "/")
        cat("Group            :", self$group$name, "\n")

      self$print_attributes()
    },

    #' @description Retrieve a 1-row `data.frame` with some information on this
    #'   grid mapping.
    brief = function() {
      data.frame(name = self$fullname, grid_mapping = private$.grid_mapping_name)
    },

    #' @description Retrieve the CRS string for a specific variable.
    #' @param axis_info A list with information that describes the axes of the
    #' [CFVariable] instance to describe. This list can be generated for a
    #' `CFVariable` using the `.wkt2_axis_info()` function (not exported).
    #' @return A character string with the CRS in WKT2 format.
    wkt2 = function(axis_info) {
      crs_attr <- self$attribute("crs_wkt")
      if (!is.na(crs_attr)) return(crs_attr)

      projcrs_name <- self$attribute("projected_crs_name")
      if (!is.na(projcrs_name)) {
        proj <- private$proj_crs(name = projcrs_name)
        if (nzchar(proj)) return(proj)
      } else projcrs_name <- 'unknown'

      geocrs_name <- self$attribute("geographic_crs_name")
      if (!is.na(geocrs_name)) {
        geo <- private$geo_crs(name = geocrs_name)
        if (nzchar(geo)) return(geo)
      } else geocrs_name <- 'unknown'

      # If code reaches here, any set name is not present in the EPSG
      # database so create a manual WKT from it
      datum <- private$datum_geo()
      angle <- .wkt2_uom(datum$ANGLEUNIT)

      if (private$.grid_mapping_name == "latitude_longitude")
        return(paste0('GEOGCRS["', geocrs_name, '",', datum$WKT2,
                      ',CS[ellipsoidal,2],AXIS["north (Lat)",north,ORDER[1],',
                      angle, '],AXIS["east (Lon)",east,ORDER[2],', angle, ']]'))

      length <- private$uom(axis_info$LENGTHUNIT)

      # Is there a vertical axis?
      if (is.na(vdatum <- self$attribute("geoid_name")))
        if (is.na(vdatum <- self$attribute("geopotential_datum_name")))
          vdatum <- ''

      # Compound CRS
      wkt <- if (nzchar(vdatum)) 'COMPOUNDCRS["unknown",' else ''

      # Projected CRS
      wkt <- paste0(wkt, 'PROJCRS["', projcrs_name, '",BASEGEOGCRS["', geocrs_name,
                    '",', datum$WKT2, '],CONVERSION["unknown",')

      # Coordinate operation method
      wkt <- paste0(wkt,
             switch(private$.grid_mapping_name,
               "albers_conical_equal_area" = private$aea(angle, length),
               "azimuthal_equidistant" = private$aeqd(angle, length),
               "geostationary" = private$geos(),
               "lambert_azimuthal_equal_area" = private$laea(angle, length),
               "lambert_conformal_conic" = private$lcc(angle, length),
               "lambert_cylindrical_equal_area" = private$lcea(angle, length),
               "mercator" = private$merc(angle, length),
               "oblique_mercator" = private$omerc(angle, length),
               "orthographic" = private$ortho(angle, length),
               "polar_stereographic" = private$ps(angle, length),
               "rotated_latitude_longitude" = private$rot(),
               "sinusoidal" = private$sinus(),
               "stereographic" = private$stereo(angle, length),
               "transverse_mercator" = private$tmerc(angle, length),
               "vertical_perspective" = private$persp(angle)
             ))

      # Coordinate system and close the PROJCRS
      wkt <- paste0(wkt, '],CS[Cartesian,2],AXIS["(E)",east,ORDER[1]],AXIS["(N)",north,ORDER[2]],', length, ']')

      # Compound CRS?
      if (nzchar(vdatum)) {
        vert <- axis_info$VERTINFO
        wkt <- paste0(wkt, ',VERTCRS["unknown",', private$datum_vert(vdatum),
                      ',CS[vertical,1],AXIS["', vert$standard_name, '",',
                      vert$positive, '],', private$uom(vert$units), ']]')
      }

      wkt
    },

    #' @description Write the CRS object to a netCDF file.
    #' @return Self, invisibly.
    write = function() {
      if (is.null(private$.NCobj)) {
        private$.NCobj <- NCVariable$new(NA, self$name, self$group$NC, "NC_CHAR", NA)
        private$.id <- private$.NCobj$id
        private$.NCobj$CF <- self
      }
      self$write_attributes()
      invisible(self)
    }
  ),

  active = list(
    #' @field friendlyClassName (read-only) A nice description of the class.
    friendlyClassName = function(value) {
      if (missing(value))
        "Grid mapping"
    }
  )
)

# ==============================================================================
# Helper function

# Return the axis information from a `CFVariable` object to construct a
# WKT2 string of the CRS of this variable. Returns a list with relevant
# information. In the EPSG database, X and Y UOMs are always the same. Hence
# only one UOM is reported back. Furthermore, axis order is considered important
# only in the context of providing coordinated tuples to a coordinate
# transformation engine, something this package is not concerned with.
# Consequently, axis order is always reported as the standard X,Y. R packages
# like terra and stars deal with the idiosyncracies of R arrays. This has been
# tested with the results of [CFVariable] functions. This function may be extended
# in the future to inject more intelligence into the WKT2 strings produced.
# Currently it just returns the "units" string of the X axis (the Y axis has the
# same unit), and the Z axis, if present, in a list.
.wkt2_axis_info <- function(obj) {
  # Horizontal axes unit
  x_attributes <- c("projection_x_coordinate", "grid_longitude", "projection_x_angular_coordinate")
  ax <- lapply(obj$axes, function(x) {
    if (x$attribute("standard_name") %in% x_attributes) x
  })
  ax <- ax[lengths(ax) > 0L]
  horz <- if (length(ax) > 0L) list(LENGTHUNIT = ax[[1L]]$attribute("units"))
  else list()

  # Vertical axes unit
  z <- sapply(obj$axes, function(x) x$orientation)
  ndx <- which(z == "Z")
  vert <- if (length(ndx)) {
    z <- obj$axes[[ndx]]
    if (inherits(z, "CFAxis"))
      list(VERTINFO = c(z$attribute("standard_name"), z$attribute("positive"), z$attribute("units")))
    else list()
  } else list()
  c(horz, vert)
}
