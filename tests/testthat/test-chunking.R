test_that(".chunk_plan: whole array fits in budget as a single block", {
  plan <- .chunk_plan(shape = 100L, chunk_shape = 10L, start = 1L, count = 100L,
                      itemsize = 4L, budget_bytes = 1000L)
  expect_length(plan, 1L)
  expect_equal(plan[[1L]]$start, 1L)
  expect_equal(plan[[1L]]$count, 100L)
})

test_that(".chunk_plan: grouping, full window, tight budget", {
  # native chunk = 10 elements = 40 bytes; budget covers 2 native chunks (80B)
  plan <- .chunk_plan(shape = 100L, chunk_shape = 10L, start = 1L, count = 100L,
                      itemsize = 4L, budget_bytes = 80L)
  counts <- sapply(plan, function(p) p$count)
  starts <- sapply(plan, function(p) p$start)
  expect_true(all(counts * 4L <= 80L))
  expect_equal(sum(counts), 100L)
  # contiguous, gap-free, non-overlapping coverage
  ord <- order(starts)
  ends <- starts[ord] + counts[ord] - 1L
  expect_equal(starts[ord][1L], 1L)
  expect_equal(ends[length(ends)], 100L)
  expect_true(all(starts[ord][-1L] == ends[-length(ends)] + 1L))
})

test_that(".chunk_plan: grouping, off-boundary partial window", {
  # window [15,64] within a 100-length, chunk-10 array; budget = 2 native chunks
  plan <- .chunk_plan(shape = 100L, chunk_shape = 10L, start = 15L, count = 50L,
                      itemsize = 4L, budget_bytes = 80L)
  counts <- sapply(plan, function(p) p$count)
  starts <- sapply(plan, function(p) p$start)
  expect_true(all(counts * 4L <= 80L))
  expect_equal(sum(counts), 50L)  # exact coverage, no double-counted overlap
  ord <- order(starts)
  ends <- starts[ord] + counts[ord] - 1L
  expect_equal(starts[ord][1L], 15L)
  expect_equal(ends[length(ends)], 64L)
  expect_true(all(starts[ord][-1L] == ends[-length(ends)] + 1L))
})

test_that(".chunk_plan: multi-dimensional grouping covers the window exactly once", {
  shape <- c(288L, 180L, 9645L)        # (lon, lat, time), as RNetCDF reports it
  chunk <- c(58L, 36L, 1929L)          # this file's actual native chunk
  start <- c(1L, 1L, 1L)
  count <- c(288L, 180L, 1929L)        # one full time-chunk's worth, full space
  itemsize <- 4L
  budget <- 8L * 1024^2                # 8MB -- forces splitting below the ~16MB full slab

  plan <- .chunk_plan(shape, chunk, start, count, itemsize, budget)
  total_elems <- sum(sapply(plan, function(p) prod(p$count)))
  expect_equal(total_elems, prod(count))
  expect_true(all(sapply(plan, function(p) prod(p$count) * itemsize <= budget)))
})

test_that(".chunk_plan: single native chunk exceeds budget, must shrink below it", {
  shape <- c(288L, 180L, 9645L)
  chunk <- c(58L, 36L, 1929L)          # ~16MB uncompressed
  plan <- .chunk_plan(shape, chunk, start = c(1L, 1L, 1L), count = c(58L, 36L, 1929L),
                      itemsize = 4L, budget_bytes = 100L)  # absurdly tight on purpose
  expect_true(all(sapply(plan, function(p) prod(p$count) * 4L <= 100L)))
  total_elems <- sum(sapply(plan, function(p) prod(p$count)))
  expect_equal(total_elems, 58L * 36L * 1929L)
})

test_that(".chunk_plan: contiguous storage falls back to slabbing on the first dimension", {
  plan <- .chunk_plan(shape = c(50L, 20L), chunk_shape = NULL,
                      start = c(1L, 1L), count = c(50L, 20L),
                      itemsize = 8L, budget_bytes = 8L * 20L * 5L)  # 5 rows at a time
  counts <- t(sapply(plan, function(p) p$count))
  expect_true(all(counts[, 2L] == 20L))       # second dim never split
  expect_equal(sum(counts[, 1L]), 50L)
})

test_that(".chunk_plan: errors when budget can't hold a single element", {
  expect_error(.chunk_plan(10L, 5L, 1L, 10L, itemsize = 8L, budget_bytes = 4L))
})

test_that(".chunk_plan: contiguous storage shrinks non-first dimensions when they dominate", {
  # First dimension is small; the fallback's chunk_shape[1] <- 1L must not be
  # treated as a floor -- the shrink logic still has to reduce dims 2/3.
  shape <- c(5L, 20000L, 20000L)
  plan <- .chunk_plan(shape, chunk_shape = NULL,
                      start = c(1L, 1L, 1L), count = shape,
                      itemsize = 8L, budget_bytes = 1e6)
  expect_true(all(sapply(plan, function(p) prod(p$count) * 8L <= 1e6)))
  total <- sum(sapply(plan, function(p) prod(p$count)))
  expect_equal(total, prod(shape))
})

test_that("read_window splits large reads via .chunk_plan and reassembles correctly", {
  skip_if_not_installed("RNetCDF")

  fn <- tempfile(fileext = ".nc")
  nc <- RNetCDF::create.nc(fn, format = "netcdf4")
  RNetCDF::dim.def.nc(nc, "x", 20L)
  RNetCDF::dim.def.nc(nc, "y", 15L)
  RNetCDF::var.def.nc(nc, "v", "NC_DOUBLE", c("x", "y"),
                      chunking = TRUE, chunksizes = c(4L, 3L))
  data <- matrix(as.double(seq_len(20L * 15L)), nrow = 20L, ncol = 15L)
  RNetCDF::var.put.nc(nc, "v", data)
  RNetCDF::close.nc(nc)
  on.exit(unlink(fn))

  old_limit <- CF.options$memory_cell_limit
  assign("memory_cell_limit", 200L * 8L, envir = CF.options)  # forces splitting
  on.exit(assign("memory_cell_limit", old_limit, envir = CF.options), add = TRUE)

  ds <- open_ncdf(fn)
  v <- ds[[ds$var_names[1L]]]

  expect_warning(full <- v$read_window(c(1L, 1L), c(20L, 15L)))
  slice <- v$read_window(c(3L, 2L), c(10L, 8L))

  expect_equal(full, data)
  expect_equal(slice, data[3:12, 2:9])
})

test_that("process_data() streams sum/mean via .chunk_plan() and matches the materialized result", {
  skip_if_not_installed("RNetCDF")

  fn <- tempfile(fileext = ".nc")
  nc <- RNetCDF::create.nc(fn, format = "netcdf4")
  RNetCDF::dim.def.nc(nc, "lon", 6L)
  RNetCDF::dim.def.nc(nc, "lat", 5L)
  RNetCDF::dim.def.nc(nc, "time", 60L)

  RNetCDF::var.def.nc(nc, "lon", "NC_DOUBLE", "lon")
  RNetCDF::att.put.nc(nc, "lon", "units", "NC_CHAR", "degrees_east")
  RNetCDF::att.put.nc(nc, "lon", "standard_name", "NC_CHAR", "longitude")
  RNetCDF::att.put.nc(nc, "lon", "axis", "NC_CHAR", "X")
  RNetCDF::var.put.nc(nc, "lon", seq(0, 5))

  RNetCDF::var.def.nc(nc, "lat", "NC_DOUBLE", "lat")
  RNetCDF::att.put.nc(nc, "lat", "units", "NC_CHAR", "degrees_north")
  RNetCDF::att.put.nc(nc, "lat", "standard_name", "NC_CHAR", "latitude")
  RNetCDF::att.put.nc(nc, "lat", "axis", "NC_CHAR", "Y")
  RNetCDF::var.put.nc(nc, "lat", seq(0, 4))

  RNetCDF::var.def.nc(nc, "time", "NC_DOUBLE", "time")
  RNetCDF::att.put.nc(nc, "time", "units", "NC_CHAR", "days since 2000-01-01")
  RNetCDF::att.put.nc(nc, "time", "standard_name", "NC_CHAR", "time")
  RNetCDF::att.put.nc(nc, "time", "axis", "NC_CHAR", "T")
  RNetCDF::att.put.nc(nc, "time", "calendar", "NC_CHAR", "standard")
  RNetCDF::var.put.nc(nc, "time", 0:59)

  RNetCDF::var.def.nc(nc, "temp", "NC_DOUBLE", c("lon", "lat", "time"),
                      chunking = TRUE, chunksizes = c(2L, 2L, 5L))
  set.seed(1)
  data <- array(rnorm(6L * 5L * 60L), dim = c(6L, 5L, 60L))
  data[1L, 1L, 3L] <- NA_real_  # exercises na.rm handling at one location
  RNetCDF::var.put.nc(nc, "temp", data)
  RNetCDF::close.nc(nc)
  on.exit(unlink(fn))

  old_limit <- CF.options$memory_cell_limit
  on.exit(assign("memory_cell_limit", old_limit, envir = CF.options), add = TRUE)

  ds <- open_ncdf(fn)
  v <- ds[[ds$var_names[1L]]]

  assign("memory_cell_limit", 1e9, envir = CF.options)  # generous: materialize path
  sum_full  <- v$summarise("total", sum,  "month", na.rm = TRUE)
  mean_full <- v$summarise("avg",   mean, "month", na.rm = TRUE)

  assign("memory_cell_limit", 6L * 5L * 3L * 8L, envir = CF.options)  # forces streaming
  sum_stream  <- v$summarise("total", sum,  "month", na.rm = TRUE)
  mean_stream <- v$summarise("avg",   mean, "month", na.rm = TRUE)

  expect_equal(sum_stream$values, sum_full$values)
  expect_equal(mean_stream$values, mean_full$values)

  # na.rm = FALSE: the NA must propagate identically in both paths
  assign("memory_cell_limit", 1e9, envir = CF.options)
  sum_full_narm_false <- v$summarise("total", sum, "month")
  assign("memory_cell_limit", 6L * 5L * 3L * 8L, envir = CF.options)
  sum_stream_narm_false <- v$summarise("total", sum, "month")
  expect_equal(sum_stream_narm_false$values, sum_full_narm_false$values)
  expect_true(is.na(sum_stream_narm_false$values[1L, 1L, 1L]))
})

test_that("process_data() streams min/max/range, replicating base R's Inf/warning for all-NA locations", {
  skip_if_not_installed("RNetCDF")

  lon  <- seq(0, 5)
  lat  <- seq(0, 4)
  time <- as.character(as.Date("2000-01-01") + 0:59)
  set.seed(2)
  data <- array(rnorm(6L * 5L * 60L), dim = c(6L, 5L, 60L))
  data[1L, 1L, ] <- NA_real_  # this location is entirely NA, every level
  dimnames(data) <- list(as.character(lon), as.character(lat), time)
  names(dimnames(data)) <- c("lon", "lat", "time")

  # Ground truth: built entirely in memory via as_CF(), no file I/O, no
  # chunking question -- process_data() takes the already-materialized
  # branch immediately since .values is already set.
  v_mem <- as_CF("temp", data)

  # The streamed path needs an actual on-disk, explicitly-chunked variable;
  # as_CF()$save() can't set chunksizes (NCVariable's own header comment:
  # "chunking - .ncdf4 - Not used"), so this part still needs raw RNetCDF.
  fn <- tempfile(fileext = ".nc")
  nc <- RNetCDF::create.nc(fn, format = "netcdf4")
  RNetCDF::dim.def.nc(nc, "lon", 6L)
  RNetCDF::dim.def.nc(nc, "lat", 5L)
  RNetCDF::dim.def.nc(nc, "time", 60L)

  RNetCDF::var.def.nc(nc, "lon", "NC_DOUBLE", "lon")
  RNetCDF::att.put.nc(nc, "lon", "units", "NC_CHAR", "degrees_east")
  RNetCDF::att.put.nc(nc, "lon", "standard_name", "NC_CHAR", "longitude")
  RNetCDF::att.put.nc(nc, "lon", "axis", "NC_CHAR", "X")
  RNetCDF::var.put.nc(nc, "lon", lon)

  RNetCDF::var.def.nc(nc, "lat", "NC_DOUBLE", "lat")
  RNetCDF::att.put.nc(nc, "lat", "units", "NC_CHAR", "degrees_north")
  RNetCDF::att.put.nc(nc, "lat", "standard_name", "NC_CHAR", "latitude")
  RNetCDF::att.put.nc(nc, "lat", "axis", "NC_CHAR", "Y")
  RNetCDF::var.put.nc(nc, "lat", lat)

  RNetCDF::var.def.nc(nc, "time", "NC_DOUBLE", "time")
  RNetCDF::att.put.nc(nc, "time", "units", "NC_CHAR", "days since 2000-01-01")
  RNetCDF::att.put.nc(nc, "time", "standard_name", "NC_CHAR", "time")
  RNetCDF::att.put.nc(nc, "time", "axis", "NC_CHAR", "T")
  RNetCDF::att.put.nc(nc, "time", "calendar", "NC_CHAR", "standard")
  RNetCDF::var.put.nc(nc, "time", 0:59)

  RNetCDF::var.def.nc(nc, "temp", "NC_DOUBLE", c("lon", "lat", "time"),
                      chunking = TRUE, chunksizes = c(2L, 2L, 5L))
  RNetCDF::var.put.nc(nc, "temp", data)  # same poisoned array, written verbatim
  RNetCDF::close.nc(nc)
  on.exit(unlink(fn))

  old_limit <- CF.options$memory_cell_limit
  on.exit(assign("memory_cell_limit", old_limit, envir = CF.options), add = TRUE)
  # Feasibility floor for this shape: 6*5 (full space) * 5 (native time-chunk)
  # * 8 bytes = 1200B. Must exceed that for streaming to engage at all.
  assign("memory_cell_limit", 6L * 5L * 10L * 8L, envir = CF.options)

  ds <- open_ncdf(fn)
  v  <- ds[[ds$var_names[1L]]]

  min_full   <- suppressWarnings(v_mem$summarise("mn", min, "month", na.rm = TRUE))
  max_full   <- suppressWarnings(v_mem$summarise("mx", max, "month", na.rm = TRUE))
  range_full <- suppressWarnings(v_mem$summarise(c("rmin", "rmax"), range, "month", na.rm = TRUE))

  min_stream   <- suppressWarnings(v$summarise("mn", min, "month", na.rm = TRUE))
  max_stream   <- suppressWarnings(v$summarise("mx", max, "month", na.rm = TRUE))
  range_stream <- suppressWarnings(v$summarise(c("rmin", "rmax"), range, "month", na.rm = TRUE))

  expect_equal(min_stream$values, min_full$values)
  expect_equal(max_stream$values, max_full$values)
  expect_equal(range_stream$rmin$values, range_full$rmin$values)
  expect_equal(range_stream$rmax$values, range_full$rmax$values)

  # Output shape is (month, lon, lat) -- the new time-like axis first, per
  # process_data()'s aperm(x, c(num_dims, 1:(num_dims-1))) and summarise()'s
  # axes <- c(new_ax, other_axes). Location (lon=1, lat=1) is [, 1L, 1L].
  expect_true(all(is.infinite(min_stream$values[, 1L, 1L]) & min_stream$values[, 1L, 1L] > 0))
  expect_true(all(is.infinite(max_stream$values[, 1L, 1L]) & max_stream$values[, 1L, 1L] < 0))
  expect_false(any(is.infinite(min_stream$values[, -1L, ])))

  ws <- character(0L)
  withCallingHandlers(
    v$summarise("mn2", min, "month", na.rm = TRUE),
    warning = function(w) { ws <<- c(ws, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  expect_true(any(grepl("no non-missing arguments to min", ws, fixed = TRUE)))
})
