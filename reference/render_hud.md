# Render a ggplot2, gt, or carbon code image to a magick image

Converts a ggplot2 plot, gt table, or carbon.js code image to a
`magick-image`, ready for warping or compositing. Dispatches
automatically based on the class of `x`.

## Usage

``` r
render_hud(x, width = 400, height = 300, bg = "transparent", res = 150, ...)
```

## Arguments

- x:

  A ggplot2 (`"ggplot"`), gt (`"gt_tbl"`), or magick image object (from
  [`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md)).

- width:

  Width of the output image in pixels. Default `400`.

- height:

  Height of the output image in pixels. Default `300`.

- bg:

  Background color passed to the graphics device. Use `"transparent"`
  (default) to keep alpha when compositing. Note: gt objects rendered
  via [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html) may
  not fully honor a transparent background; in that case use a dark
  colour such as `"#00000000"` and accept the white panel, or style the
  gt table background directly. For
  [`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md)
  objects this argument is ignored because carbon.js controls its own
  background via `bg_color`.

- res:

  Resolution in DPI used when rasterizing the plot. Default `150`.
  Ignored for
  [`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md)
  objects.

- ...:

  Additional arguments, currently unused but reserved for future
  extensions.

## Value

A `magick-image` object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
img <- render_hud(p, width = 500, height = 350)

# Carbon code block
code_img <- carbon_image('fit <- lm(mpg ~ wt, data = mtcars)\\nsummary(fit)')
img <- render_hud(code_img, width = 600, height = 300)
} # }
```
