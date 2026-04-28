library(magick)
library(ggplot2)

test_that("render_hud handles ggplot objects", {
  p <- create_test_plot()
  img <- render_hud(p, width = 200, height = 150)
  
  expect_s3_class(img, "magick-image")
  info <- image_info(img)
  expect_equal(info$width, 200)
  expect_equal(info$height, 150)
})

test_that("render_hud errors on invalid input", {
  expect_error(render_hud("not a plot"), "must be a ggplot2, gt, or magick-image object")
})

test_that("hud_panel adds padding", {
  p <- create_test_plot()
  img <- render_hud(p, width = 100, height = 100)
  
  paneled <- hud_panel(img, padding = 10)
  info <- image_info(paneled)
  
  # Base size 100 + 2*10 padding = 120
  expect_equal(info$width, 120)
  expect_equal(info$height, 120)
})

test_that("hud_panel with border preserves size", {
  p <- create_test_plot()
  img <- render_hud(p, width = 100, height = 100)
  
  # Border is drawn inside or exactly on the edge of the paneled image
  # total width = 100 + 2*10 padding = 120
  paneled <- hud_panel(img, padding = 10, border_color = "#FF0000", border_width = 5)
  info <- image_info(paneled)
  
  expect_equal(info$width, 120)
  expect_equal(info$height, 120)
})
