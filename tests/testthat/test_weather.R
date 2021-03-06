
# weather_raw --------------------------------------------------------------
context("weather_raw")

test_that("weather_raw (hour) downloads a data frame", {
  expect_silent(wd <- weather_raw(station_id = 51423,
                                  date = as.Date("2014-01-01"),
                                  skip = 15, interval = "hour"))
  ## Basics
  expect_is(wd, "data.frame")
  expect_length(wd, 25)
  expect_equal(nrow(wd), 744)
  expect_is(wd[, "Date/Time"], "character")
  expect_lt(length(data.frame(wd)[is.na(data.frame(wd))]),
            length(data.frame(wd)[!is.na(data.frame(wd))]))
  expect_true(stringi::stri_escape_unicode(wd[, "Data Quality"][1]) %in%
                c("\\u2021"))
})

test_that("weather_raw (day) downloads a data frame", {
  expect_silent(wd <- weather_raw(station_id = 51423,
                                  date = as.Date("2014-01-01"),
                                  skip = 25, interval = "day"))

  ## Basics
  expect_is(wd, "data.frame")
  expect_length(wd, 27)
  expect_equal(nrow(wd), 365)
  expect_is(wd[, "Date/Time"], "character")
  expect_lt(length(wd[is.na(wd)]), length(wd[!is.na(wd)]))
  expect_true(stringi::stri_escape_unicode(wd[, "Data Quality"][1]) %in%
                c("\\u2021"))
})

test_that("weather_raw (month) downloads a data frame", {
  expect_silent(wd <- weather_raw(station_id = 43823,
                                  date = as.Date("2005-01-01"),
                                  skip = 17, interval = "month"))

  ## Basics
  expect_is(wd, "data.frame")
  expect_length(wd, 25)
  expect_equal(nrow(wd), 4)
  expect_is(wd[, "Date/Time"], "character")
  expect_lt(length(data.frame(wd)[is.na(data.frame(wd))]),
            length(data.frame(wd)[!is.na(data.frame(wd))]))
})



# weather by hour ---------------------------------------------------------
context("weather by hour")

test_that("weather (hour) returns a data frame", {
  expect_silent({weather_dl(station_ids = 51423, start = "2014-01-01",
                            end = "2014-01-31")})
  expect_message({w <- weather_dl(station_ids = 51423, start = "2014-01-01",
                                  end = "2014-01-31", verbose = TRUE)})

  ## Basics
  expect_is(w, "data.frame")
  expect_length(w, 35)
  expect_equal(nrow(w), 744)
  expect_is(w$station_name, "character")
  expect_is(w$prov, "factor")
  expect_is(w$temp, "numeric")
  expect_is(w$temp_flag, "character")
  expect_is(w$date, "Date")
  expect_is(w$time, "POSIXct")
  expect_lt(length(data.frame(w)[is.na(data.frame(w))]),
            length(data.frame(w)[!is.na(data.frame(w))]))

  ## Data
  expect_equal(w$station_id[1], 51423)
  expect_equal(w$station_name[1], "KAMLOOPS A")
  expect_equal(w$prov[1], factor("BC", levels = levels(stations$prov)))
  expect_equal(w$time[1], as.POSIXct("2014-01-01 00:00:00", tz = "Etc/GMT+8"))
  expect_equal(w$qual[1], paste0("Partner data that is not subject to review ",
                                 "by the National Climate Archives"))
})

test_that("weather (hour) formats timezone display", {
  expect_silent({w <- weather_dl(station_ids = 51423, start = "2014-03-01",
                                 end = "2014-04-01",
                                 tz_disp = "America/Vancouver")})
  expect_equal(w$time[1],
               as.POSIXct("2014-03-01 00:00:00", tz = "America/Vancouver"))
  expect_equal(w$time[w$date == as.Date("2014-04-01")][1],
               as.POSIXct("2014-04-01 01:00:00", tz = "America/Vancouver"))
})

test_that("weather (hour) formats timezone to UTC with multiple zones", {
  expect_silent({w <- weather_dl(c(42203, 49909), start = "2017-09-01",
                                 end = "2017-09-30")})
  expect_equal(lubridate::tz(w$time[1]), "UTC")
  expect_equal(w$time[1], as.POSIXct("2017-09-01 08:00:00", tz = "UTC"))
  expect_equal(w$time[w$station_id == 49909][1],
               as.POSIXct("2017-09-01 06:00:00", tz = "UTC"))

  expect_silent({w <- weather_dl(c(42203), start = "2017-09-01",
                                 end = "2017-09-30")})
  expect_equal(lubridate::tz(w$time[1]), "Etc/GMT+8")

  expect_silent({w <- weather_dl(c(49909), start = "2017-09-01",
                                 end = "2017-09-30")})
  expect_equal(lubridate::tz(w$time[1]), "Etc/GMT+6")
})

test_that("weather (hour) gets all", {
  expect_silent(w <- weather_dl(station_ids = 50821,
                                start = Sys.Date() - lubridate::days(1),
                                interval = "hour", trim = FALSE))
  expect_is(w, "data.frame")
  expect_length(w, 35)
  expect_equal(nrow(w), 48)
  expect_equal(w$date[1], Sys.Date() - lubridate::days(1))
  expect_equal(w$date[nrow(w)], Sys.Date())
})

test_that("weather (hour) trims NAs", {

})

test_that("weather (hour) multiple stations", {
  expect_silent({w <- weather_dl(station_ids = c(51423, 50821),
                                 start = "2014-03-01", end = "2014-03-15")})

  expect_equal(unique(w$station_name), c("KAMLOOPS A", "BRANDON A"))
  expect_equal(nrow(w[w$station_id == 51423,]), nrow(w[w$station_id == 50821,]))
})


test_that("weather (hour) no data fails nicely", {
  expect_silent(
    expect_message(w0 <- weather_dl(1274, interval = "hour",
                                    start = "2012-11-01",
                                    end = "2012-12-01"),
                   paste0("There are no data for station 1274 for this ",
                          "interval \\(hour\\)")))
  expect_silent(
    expect_message(w1 <- weather_dl(c(1274, 1275),
                                    interval = "hour",
                                    start = "2012-11-01",
                                    end = "2012-12-01"),
                   paste0("There are no data for some stations \\(1274\\)")))

  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 35)
  expect_equal(nrow(w1), 744)

  expect_silent(
    expect_message(
      w0 <- weather_dl(1275, interval = "hour",
                       start = "2017-01-01", end = "2017-02-01"),
      paste0("There are no data for station 1275, ",
             "in this time range \\(2017-01-01 to 2017-02-01\\), ",
             "for this interval \\(hour\\)")))

  expect_silent(
    expect_message(
      w1 <- weather_dl(c(1275, 1001), interval = "hour",
                       start = "2017-01-01", end = "2017-02-01"),
      paste0("There are no data for all stations \\(1275, 1001\\), ",
             "in this time range \\(2017-01-01 to 2017-02-01\\), ",
             "for this interval \\(hour\\)")))

  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 0)
  expect_equal(nrow(w1), 0)
})

test_that("weather (hour) verbose and quiet", {
  expect_message(weather_dl(c(1275, 1001), interval = "hour",
                            start = "2017-01-01", end = "2017-02-01"))

  expect_silent(weather_dl(c(1275, 1001), interval = "hour",
                           start = "2017-01-01", end = "2017-02-01",
                           quiet = TRUE))

  expect_message(weather_dl(c(1275, 1001), interval = "hour",
                            start = "2017-01-01", end = "2017-02-01",
                            verbose = TRUE),
                 "(Getting station: 1275\\n)")
})

# weather by day ----------------------------------------------------------
context("weather by day")

test_that("weather (day) returns a data frame", {
  expect_message(expect_error({weather_dl(station_ids = 51423,
                                          start = "2014-01-01",
                                          end = "2014-03-01",
                                          interval = "day")}, NA))
  expect_message(expect_error({w <- weather_dl(station_ids = 51423,
                                               start = "2014-01-01",
                                               end = "2014-03-01",
                                               interval = "day",
                                               verbose = TRUE)}, NA))

  ## Basics
  expect_is(w, "data.frame")
  expect_length(w, 36)

  i <- lubridate::int_length(lubridate::interval(min(w$date),
                                                 max(w$date)))/60/60/24 + 1
  expect_equal(nrow(w), i)

  expect_is(w$station_name, "character")
  expect_is(w$prov, "factor")
  expect_is(w$mean_temp, "numeric")
  expect_is(w$mean_temp_flag, "character")
  expect_is(w$date, "Date")
  expect_lt(length(data.frame(w)[is.na(data.frame(w))]),
            length(data.frame(w)[!is.na(data.frame(w))]))

  ## Data
  expect_equal(w$station_id[1], 51423)
  expect_equal(w$station_name[1], "KAMLOOPS A")
  expect_equal(w$prov[1], factor("BC", levels = levels(stations$prov)))
  expect_equal(w$qual[1],
               paste0("Partner data that is not subject to review by the ",
                      "National Climate Archives"))
})

test_that("weather (day) gets all", {
  expect_silent(weather_dl(station_ids = 54398, interval = "day", trim = FALSE))
  expect_message(expect_error({w <- weather_dl(station_ids = 54398,
                                               interval = "day",
                                               trim = FALSE,
                                               verbose = TRUE)}, NA))

  expect_is(w, "data.frame")
  expect_length(w, 36)
  expect_gte(nrow(w), 20)
  expect_equal(min(w$date), as.Date("2016-01-01"))
  expect_equal(max(w$date), Sys.Date())

  expect_silent(w <- weather_dl(station_ids = 54398, start = "2017-01-01",
                                interval = "day", trim = FALSE))
  expect_equal(min(w$date), as.Date("2017-01-01"))
  expect_equal(max(w$date), Sys.Date())

  expect_silent(w <- weather_dl(station_ids = 54398, end = "2016-04-01",
                                interval = "day", trim = FALSE))
  expect_equal(min(w$date), as.Date("2016-01-01"))
  expect_equal(max(w$date), as.Date("2016-04-01"))

})


test_that("weather (day) trims NAs", {
  expect_silent(w1 <- weather_dl(station_ids = 54398, interval = "day",
                                 trim = FALSE))
  expect_silent(w2 <- weather_dl(station_ids = 54398, interval = "day",
                                 trim = TRUE))

  expect_gte(nrow(w1), nrow(w2))
  expect_gte(length(data.frame(w1)[is.na(data.frame(w1))]),
             length(data.frame(w2)[is.na(data.frame(w2))]))
})

test_that("weather (day) mutliple stations", {
  expect_error(w <- weather_dl(station_ids = c(54398, 51423),
                               start = "2016-03-01", end = "2016-04-01",
                               interval = "day"), NA)

  expect_equal(unique(w$station_name), c("MUSKOKA SNOW", "KAMLOOPS A"))
  expect_equal(nrow(w[w$station_id == 54398,]),
               nrow(w[w$station_id == 51423,]))
})

test_that("weather (day) no data fails nicely", {
  expect_silent(
    expect_message(w0 <- weather_dl(station_ids = 42013,
                                    interval = "day",
                                    start = "2017-01-01",
                                    end = "2017-02-01"),
                   paste0("There are no data for station 42013 for ",
                          "this interval \\(day\\)")))
  expect_silent(
    expect_message(w1 <- weather_dl(station_ids = c(42013, 51423),
                                    interval = "day",
                                    start = "2017-01-01",
                                    end = "2017-02-01"),
                   paste0("There are no data for some stations \\(42013\\), ",
                          "in this time range \\(")))

  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 36)
  expect_equal(nrow(w1), 32)

  expect_silent(
    expect_message(w0 <- weather_dl(1274, interval = "day",
                                    start = "2017-01-01",
                                    end = "2017-03-01"),
                   paste0("There are no data for station 1274, in ",
                          "this time range \\(2017-01-01 to 2017-03-01\\).")))
  expect_silent(
    expect_message(w1 <- weather_dl(c(1274, 1275), interval = "day",
                                    start = "2017-01-01",
                                    end = "2017-03-01"),
                   paste0("There are no data for all stations ",
                          "\\(1274, 1275\\), in this time range ",
                          "\\(2017-01-01 to 2017-03-01\\)")))

  ## Basics
  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 0)
  expect_equal(nrow(w1), 0)
})

test_that("weather (day) verbose and quiet", {
  expect_message(weather_dl(c(42013, 51423), interval = "day",
                            start = "2017-01-01", end = "2017-02-01"))

  expect_silent(weather_dl(c(42013, 51423), interval = "day",
                           start = "2017-01-01", end = "2017-02-01",
                           quiet = TRUE))

  expect_message(weather_dl(c(42013, 51423), interval = "day",
                            start = "2017-01-01", end = "2017-02-01",
                            verbose = TRUE),
                 "(Getting station: 42013\\n)")
})

# weather by month --------------------------------------------------------
context("weather by month")

test_that("weather (month) returns a data frame", {
  expect_silent(w <- weather_dl(station_ids = 5401, start = "2014-01-01",
                                end = "2014-05-01", interval = "month"))

  ## Basics
  expect_is(w, "data.frame")
  expect_length(w, 34)
  expect_equal(nrow(w), 5)
  expect_is(w$station_name, "character")
  expect_is(w$prov, "factor")
  expect_is(w$mean_temp, "numeric")
  expect_is(w$mean_temp_flag, "character")
  expect_is(w$date, "Date")
  expect_lt(length(data.frame(w)[is.na(data.frame(w))]),
            length(data.frame(w)[!is.na(data.frame(w))]))

  ## Data
  expect_equal(w$station_id[1], 5401)
  expect_equal(w$station_name[1], "MAGOG")
  expect_equal(w$climate_id[1], "7024440")
  expect_equal(w$WMO_id[1], "")
  expect_equal(w$TC_id[1], "")
  expect_equal(w$prov[1], factor("QC", levels = levels(stations$prov)))

})

test_that("weather (month) trims NAs", {

})

test_that("weather (month) no data fails nicely", {
  expect_silent(
    expect_message(w0 <- weather_dl(station_ids = 51423,
                                    interval = "month",
                                    start = "2012-01-01",
                                    end = "2012-02-01"),
                   paste0("There are no data for station 51423 for this ",
                          "interval \\(month\\)")))
  expect_silent(
    expect_message(w1 <- weather_dl(station_ids = c(51423, 1275),
                                    interval = "month",
                                    start = "2012-01-01",
                                    end = "2012-02-01"),
                   paste0("There are no data for some stations \\(51423\\), ",
                          "in this time range \\(2012-01-01 to 2012-02-01\\), ",
                          "for this interval \\(month\\)")))
  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 34)
  expect_equal(nrow(w1), 2)

  expect_silent(
    expect_message(w0 <- weather_dl(1274, interval = "month",
                                    start = "2017-01-01",
                                    end = "2017-02-01"),
                   paste0("There are no data for station 1274, in ",
                          "this time range \\(2017-01-01 to 2017-02-01\\).")))
  expect_silent(
    expect_message(w1 <- weather_dl(c(1274, 1275), interval = "month",
                                    start = "2017-01-01",
                                    end = "2017-02-01"),
                   paste0("There are no data for all stations ",
                          "\\(1274, 1275\\), in this time range ",
                          "\\(2017-01-01 to 2017-02-01\\)")))

  expect_is(w0, "data.frame")
  expect_length(w0, 0)
  expect_equal(nrow(w0), 0)
  expect_is(w1, "data.frame")
  expect_length(w1, 0)
  expect_equal(nrow(w1), 0)
})

test_that("weather (month) multiple stations", {
  expect_silent(w <- weather_dl(station_ids = c(5401, 5940),
                                start = "2014-01-01",
                                end = "2014-05-01",
                                interval = "month"))

  expect_equal(unique(w$station_name), c("MAGOG", "ST PRIME"))
  expect_equal(nrow(w[w$station_id == 5401,]), nrow(w[w$station_id == 5940,]))
})

test_that("weather (month) multiple stations (one NA)", {
  expect_message(expect_error(w <- weather_dl(station_ids = c(5401, 51423),
                                              start = "2014-01-01",
                                              end = "2014-05-01",
                                              interval = "month"), NA))
  expect_equal(unique(w$station_name), c("MAGOG"))
})

test_that("weather (month) verbose and quiet", {
  expect_message(weather_dl(c(51423, 1275), interval = "month",
                            start = "2017-01-01", end = "2017-02-01"))

  expect_silent(weather_dl(c(51423, 1275), interval = "month",
                           start = "2017-01-01", end = "2017-02-01",
                           quiet = TRUE))

  expect_message(weather_dl(c(51423, 1275), interval = "month",
                            start = "2017-01-01", end = "2017-02-01",
                            verbose = TRUE),
                 "(Getting station: 51423\\n)")
})


# list_cols ---------------------------------------------------------------

context("Generating list_col")

test_that("list_col=TRUE and interval=hour groups on the right level", {
  expect_equal(ncol(weather_dl(station_ids = c(27226), start = "2015-01-01",
                               end = "2015-01-15", interval = "hour") %>%
                      tidyr::nest(-dplyr::one_of(p_names), -date)),
               ncol(weather_dl(station_ids = c(27226), start = "2015-01-01",
                               end = "2015-01-15", interval = "hour",
                               list_col=TRUE)) )
})

test_that("list_col=TRUE and interval=day groups on the right level", {
  expect_equal(ncol(weather_dl(station_ids = c(27119), start = "2015-01-01",
                               end = "2015-01-15", interval = "day") %>%
                      tidyr::nest(-dplyr::one_of(p_names), -month)),
               ncol(weather_dl(station_ids = c(27119),
                               start = "2015-01-01",
                               end = "2015-01-15",
                               interval = "day",
                               list_col=TRUE))
  )
})

test_that("list_col=TRUE and interval=month groups on the right level", {
  expect_equal(ncol(weather_dl(station_ids = c(5217), start = "2015-01-01",
                               end = "2015-01-15", interval = "month") %>%
                      tidyr::nest(-dplyr::one_of(p_names), -year)),
               ncol(weather_dl(station_ids = c(5217), start = "2015-01-01",
                               end = "2015-01-15", interval = "month",
                               list_col=TRUE))
  )
})


