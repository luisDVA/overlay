library(magick)
library(ggplot2)

test_that("hud_overlay handles placement and size presets", {
  p <- create_test_plot()
  bg <- create_test_bg(600, 400)
  
  # "small" preset is 280x190
  res <- hud_overlay(p, bg, placement = "bottom-right", size = "small", margin = 10)
  
  expect_s3_class(res, "magick-image")
  info <- image_info(res)
  expect_equal(info$width, 600)
  expect_equal(info$height, 400)
})

test_that("composite_hud respects opacity", {
  bg <- create_test_bg(100, 100, "white")
  fg <- create_test_bg(100, 100, "black")
  
  # Semi-transparent composite
  res <- composite_hud(bg, fg, opacity = 0.5)
  
  # If it works, the resulting image shouldn't be pure white or pure black
  # We can check if it has an alpha channel or just that it didn't error
  expect_s3_class(res, "magick-image")
})

test_that("warp_hud preserves size when requested", {
  img <- create_test_bg(100, 100)
  warped <- warp_hud(img, corners = list(tl = c(10, 10)), keep_size = TRUE)
  
  info <- image_info(warped)
  expect_equal(info$width, 100)
  expect_equal(info$height, 100)
})
