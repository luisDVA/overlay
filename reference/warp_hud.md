# Apply a perspective warp to a magick image

Distorts a `magick-image` using a four-point perspective transformation,
giving the "floating HUD panel" effect.

## Usage

``` r
warp_hud(img, corners = list(), keep_size = TRUE, ...)
```

## Arguments

- img:

  A `magick-image` object, typically produced by
  [`render_hud()`](https://luisdva.github.io/overlay/reference/render_hud.md).

- corners:

  A named list specifying how far each corner of the image should move
  from its natural position. Each element is a numeric vector of length
  2: `c(dx, dy)`, where positive values move right/down. Names must be
  `"tl"` (top-left), `"tr"` (top-right), `"bl"` (bottom-left), and
  `"br"` (bottom-right). Any corner omitted defaults to `c(0, 0)` (no
  movement).

  **Example**: tilt the panel so the left edge rises and the right edge
  drops:

      corners = list(tl = c(0, -20), bl = c(0, -20),
                     tr = c(0,  20), br = c(0,  20))

- keep_size:

  If `TRUE` (default), the output image is cropped/padded back to the
  original pixel dimensions. If `FALSE`, ImageMagick may expand the
  canvas to contain the warped result.

- ...:

  Currently unused.

## Value

A warped `magick-image` with an alpha channel preserved.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
img <- render_hud(p, width = 500, height = 350)

# Tilt the top edge backward (raise both top corners)
warped <- warp_hud(img, corners = list(tl = c(20, -15), tr = c(-20, -15)))
magick::image_browse(warped)
} # }
```
