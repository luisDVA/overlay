# Composite an overlay onto a background image

Places a `magick-image` overlay onto a background image at a specified
position and opacity.

## Usage

``` r
composite_hud(
  background,
  overlay,
  x = 0,
  y = 0,
  opacity = 0.85,
  operator = "over",
  ...
)
```

## Arguments

- background:

  A path to an image file, a URL, or a `magick-image` object to use as
  the background.

- overlay:

  A `magick-image` object to overlay, typically the output of
  [`render_hud()`](https://luisdva.github.io/overlay/reference/render_hud.md)
  or
  [`warp_hud()`](https://luisdva.github.io/overlay/reference/warp_hud.md).

- x:

  Horizontal pixel offset of the overlay's top-left corner from the
  background's top-left. Defaults to `0`.

- y:

  Vertical pixel offset of the overlay's top-left corner from the
  background's top-left. Defaults to `0`.

- opacity:

  A number in `[0, 1]` controlling the overlay's transparency. `1` is
  fully opaque, `0` is invisible. Default is `0.85`.

- operator:

  ImageMagick compositing operator. Default `"over"`. See
  [`magick::image_composite()`](https://docs.ropensci.org/magick/reference/composite.html)
  for the full list of operators.

- ...:

  Additional arguments (currently unused, but reserved for future
  extensions).

## Value

A `magick-image` of the same dimensions as `background`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
bg  <- magick::image_read("photo.jpg")
p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
img <- render_hud(p, width = 400, height = 280)
out <- composite_hud(bg, img, x = 50, y = 30, opacity = 0.8)
magick::image_browse(out)
} # }
```
