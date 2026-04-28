# Create a dummy background for tests
create_test_bg <- function(w = 500, h = 500, color = "white") {
  magick::image_blank(w, h, color = color)
}

# Create a simple ggplot for tests
create_test_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}
