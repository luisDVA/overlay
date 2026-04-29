# Getting Started with overlay

``` r
library(overlay)
library(ggplot2)
library(gt)
library(tibble)
library(magick)
```

## Introduction

**overlay** provides tools to render ggplot2 and gt objects or code
snippets as images, apply perspective distortions, and composite them
over background images to create a “Heads-Up Display” (HUD) effect.

## Basic Workflow

The core function is
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md),
which handles rendering, optional borders, perspective warps, and
compositing in one go.

### 1. Create our overlay objects

We can use any `ggplot2` figure, `gt` table, or code snippet.

``` r
library(overlay)
library(ggplot2)
library(gt)
library(tibble)
library(magick)

# A gt table
weather_tbl <- tibble(
  icon     = "snowflake",
  location = "**King George Island, Antarctica**",
  temp     = "-2 °C",
  wind     = "37 km/h",
  precip   = "10%"
) |>
  gt() |>
  fmt_markdown(columns = location) |>
  tab_header(title = md("**Weather**"), subtitle = "Monday, April 06, 2026") |>
  opt_stylize(style = 6, color = "blue")

# A ggplot2 plot
chinstrap <- penguins |> subset(species == "Chinstrap")

penguin_plot <- ggplot(chinstrap, aes(x = flipper_len, y = body_mass)) +
  geom_point(color = "#5b9bd5", alpha = 0.7, size = 2) +
  labs(title = "Chinstrap Penguins", x = "Flipper length (mm)", y = "Body mass (g)") +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.background  = element_rect(fill = "white", color = NA)
  )
```

### 2. Composite onto a background

Use
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)
to place these objects onto a background image.

``` r
# Path to a background image
bg <- system.file("extdata", "penguins.jpg", package = "overlay")

result <- weather_tbl |>
  hud_overlay(
    background = bg,
    placement  = "left",
    size       = "large",
    panel      = TRUE,
    opacity    = 0.85
  ) |>
  hud_overlay(
    overlay    = penguin_plot,
    background = _,          
    placement  = "right",
    size       = "large",
    tilt       = "right",
    panel      = TRUE,
    opacity    = 0.9
  )

# View the result
result
```

## Code Snippets as Images

To show code as an overlay, we can create syntax-highlighted code images
using
[`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md),
which uses the [carbonara
API](https://github.com/petersolopov/carbonara) to render code with
carbon.js styling.

### Creating a code image

``` r
# Create a code snippet
code <- '
ggplot(penguins, aes(bill_len, island)) +
  geom_point(aes(color = species)) +
  theme_minimal()'

# Generate code image
code_img <- carbon_image(code, lang = "r", theme = "dark")

# Overlay on a background
bg <- system.file("extdata", "penguins.jpg", package = "overlay")

result <- hud_overlay(
  overlay    = code_img,
  background = bg,
  placement  = "center",
  size       = "xl"
)
```

### Combining plots with their code

A potential use case is showing a visualization alongside the code that
created it:

``` r
# Create a plot
p <- ggplot(chinstrap, aes(x = flipper_len, y = body_mass)) +
  geom_point(color = "#5b9bd5", alpha = 0.7, size = 2) +
  labs(title = "Chinstrap Penguins") +
  theme_minimal()

# Generate the corresponding code image
plot_code <- 'ggplot(chinstrap, aes(x = flipper_len, y = body_mass)) +
  geom_point(color = "#5b9bd5", alpha = 0.7, size = 2) +
  labs(title = "Chinstrap Penguins") +
  theme_minimal()'

code_img <- carbon_image(plot_code, lang = "r", theme = "dark")

# Combine both using the pipe placeholder
plotandcode <- hud_overlay(
  overlay    = p,
  background = bg,
  placement  = "left",
  size       = "xl",
  tilt       = "left",
  opacity    = 0.85
) |>
  hud_overlay(
    overlay    = code_img,
    background = _,          # Pipe placeholder
    placement  = "right",
    size       = "xl",
    opacity    = 1
  )
```

### Customizing code images

[`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md)
supports various customization options:

``` r
# Light theme
code_img_light <- carbon_image(
  code,
  lang = "r",
  theme = "light"
)

# Custom font and size
code_img_custom <- carbon_image(
  code,
  lang = "r",
  theme = "dark",
  fontSize = "16px",
  fontFamily = "Fira Code"
)

# Python code
python_code <- 'import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("data.csv")
df.plot(x="date", y="value")'

python_img <- carbon_image(python_code, lang = "python", theme = "dark")
```

## Advanced Customization

### The HUD Panel

[`hud_panel()`](https://luisdva.github.io/overlay/reference/hud_panel.md)
adds a dark frame with an optional border. We can pass a list of
arguments to `panel` in
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)
for further customization.

``` r
result_custom <- weather_tbl |>
  hud_overlay(
    background   = bg,
    placement    = "left",
    size         = "large",
    panel        = list(
      panel_color  = "#0D3B1ACC",
      border_color = "#39FF14DD",
      border_width = 10,
      padding      = 30
    )
  )
```

### Manual Warping

The `tilt` argument provides easy presets (`"left"`, `"right"`, `"top"`,
`"bottom"`), but we can specify `corners` manually for precise control.
Each corner is specified as a `c(dx, dy)` offset from its natural
position.

``` r
p_warped <- penguin_plot |>
  hud_overlay(
    background = bg,
    corners = list(
      tl = c(-50, -20), 
      tr = c(20, 10),
      bl = c(-30, 0),
      br = c(10, -10)
    )
  )
```

### Multiple Overlays with the Pipe

Since
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)
returns a `magick-image`, we can chain multiple calls using the base
pipe placeholder `_` (R ≥ 4.2.0):

``` r
# Multiple overlays on the same background
multi_overlay <- weather_tbl |>
  hud_overlay(
    background = bg,
    placement  = "top-left",
    size       = "medium",
    panel      = TRUE
  ) |>
  hud_overlay(
    overlay    = penguin_plot,
    background = _,
    placement  = "bottom-right",
    size       = "large",
    tilt       = "right"
  ) |>
  hud_overlay(
    overlay    = code_img,
    background = _,
    placement  = "bottom-left",
    size       = "medium"
  )
```

## Functions Summary

| Function                                                                          | Description                                                        |
|-----------------------------------------------------------------------------------|--------------------------------------------------------------------|
| [`render_hud()`](https://luisdva.github.io/overlay/reference/render_hud.md)       | Rasterizes a ggplot2, gt, or magick-image object to a magick image |
| [`carbon_image()`](https://luisdva.github.io/overlay/reference/carbon_image.md)   | Creates a syntax-highlighted code image using carbon.js            |
| [`hud_panel()`](https://luisdva.github.io/overlay/reference/hud_panel.md)         | Wraps the image in a dark frame                                    |
| [`warp_hud()`](https://luisdva.github.io/overlay/reference/warp_hud.md)           | Applies a 4-corner perspective distortion                          |
| [`composite_hud()`](https://luisdva.github.io/overlay/reference/composite_hud.md) | Composites the overlay onto a background image                     |
| [`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)     | Convenience wrapper for the full pipeline                          |
