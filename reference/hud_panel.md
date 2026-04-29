# Wrap a magick image in a dark semi-transparent panel border

Adds a dark, rectangular background (the "panel") around a
`magick-image`, with an optional colored-border. The result is a larger
image with the original content centred on the panel, ready for
[`warp_hud()`](https://luisdva.github.io/overlay/reference/warp_hud.md)
or
[`composite_hud()`](https://luisdva.github.io/overlay/reference/composite_hud.md).

## Usage

``` r
hud_panel(
  img,
  padding = 20,
  panel_color = "#111111CC",
  border_color = NA,
  border_width = 2,
  ...
)
```

## Arguments

- img:

  A `magick-image` object, typically from
  [`render_hud()`](https://luisdva.github.io/overlay/reference/render_hud.md).

- padding:

  Number of pixels to add around all four sides of `img` before drawing
  the panel frame. Default `20`.

- panel_color:

  Background colour of the panel as a CSS hex string (including alpha
  channel). Default `"#111111CC"`.

- border_color:

  Colour of the border drawn around the panel edge. Set to `NA`
  (default) to omit the border.

- border_width:

  Line width of the border in pixels. Defaults to `2`.

- ...:

  Additional arguments (currently unused, but reserved for future
  extensions).

## Value

A `magick-image` with size `width + 2*padding` by `height + 2*padding`
relative to the input.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
img <- render_hud(p, width = 480, height = 320, bg = "transparent")

# panel with a green border
panel <- hud_panel(img,
                   panel_color  = "#1B6B3ACC",
                   border_color = "#57FF8877",
                   border_width = 2)
} # }
```
