# Getting Started with overlay

``` r
library(overlay)
library(ggplot2)
library(gt)
library(tibble)
library(palmerpenguins)
library(magick)
```

## Introduction

**overlay** provides tools to render ggplot2 and gt objects as images,
apply perspective distortions, and composite them over background images
to create a “Heads-Up Display” (HUD) effect.

## Basic Workflow

The core function is
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md),
which handles rendering, optional panelling, warping, and compositing in
one go.

### 1. Create your overlay objects

You can use any `ggplot` or `gt` table.

``` r
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

penguin_plot <- ggplot(chinstrap, aes(x = flipper_length_mm, y = body_mass_g)) +
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

# If you don't have the file locally, you can use any image path
# bg <- "path/to/your/image.jpg"

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

## Advanced Customization

### The HUD Panel

[`hud_panel()`](https://luisdva.github.io/overlay/reference/hud_panel.md)
adds a dark frame with an optional border. You can pass a list of
arguments to `panel` in
[`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)
to customize this.

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

While `tilt` provides easy presets (`"left"`, `"right"`, `"top"`,
`"bottom"`), you can specify `corners` manually for precise control.
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

## Functions Summary

| Function                                                                          | Description                                         |
|-----------------------------------------------------------------------------------|-----------------------------------------------------|
| [`render_hud()`](https://luisdva.github.io/overlay/reference/render_hud.md)       | Rasterises a ggplot2 or gt object to a magick image |
| [`hud_panel()`](https://luisdva.github.io/overlay/reference/hud_panel.md)         | Wraps the image in a dark frame                     |
| [`warp_hud()`](https://luisdva.github.io/overlay/reference/warp_hud.md)           | Applies a 4-corner perspective distortion           |
| [`composite_hud()`](https://luisdva.github.io/overlay/reference/composite_hud.md) | Composites the overlay onto a background image      |
| [`hud_overlay()`](https://luisdva.github.io/overlay/reference/hud_overlay.md)     | Convenience wrapper for the full pipeline           |
