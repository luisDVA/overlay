
library(gt)
library(tibble)
library(ggplot2)
library(palmerpenguins)
library(magick)
bg <- system.file("extdata", "penguins.jpg", package = "warphud")
bg <- "penguins.jpg"
# gt
weather_tbl <- tibble(
  icon     = "snowflake",
  location = "**King George Island, Antarctica**",
  temp     = "-2 °C",
  wind     = "37 km/h",
  precip   = "10%"
) |>
  gt() |>
  fmt_icon(columns = icon, fill_color = "#5b9bd5", height = "2em") |>
  fmt_markdown(columns = location) |>
  cols_label(icon = "", location = "Location", temp = "Temperature",
             wind = "Wind", precip = "Precipitation") |>
  tab_header(title = md("**Weather**"), subtitle = "Monday, April 06, 2026") |>
  cols_align(align = "center", columns = c(icon, temp, wind, precip)) |>
  cols_align(align = "left",   columns = location) |>
  tab_style(style = cell_text(size = px(18)),
            locations = cells_body(columns = location)) |>
  opt_stylize(style = 6, color = "blue") |>
  tab_options(
    table.border.top.style    = "solid", table.border.top.width    = px(2),
    table.border.top.color    = "#2c5f8a",
    table.border.bottom.style = "solid", table.border.bottom.width = px(2),
    table.border.bottom.color = "#2c5f8a",
    table.border.left.style   = "solid", table.border.left.width   = px(2),
    table.border.left.color   = "#2c5f8a",
    table.border.right.style  = "solid", table.border.right.width  = px(2),
    table.border.right.color  = "#2c5f8a"
  )

# penguins plot 
chinstrap <- penguins |> subset(species == "Chinstrap")

penguin_plot <- ggplot(chinstrap, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point(color = "#5b9bd5", alpha = 0.7, size = 2) +
  labs(title = "Chinstrap Penguins", x = "Flipper length (mm)", y = "Body mass (g)") +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.background  = element_rect(fill = "white", color = NA)
  )
penguin_plot
# ── 3. Composite both onto penguins.jpg ──────────────────────────────────────
bg <- "penguins.jpg"

result <- weather_tbl |>
  hud_overlay(
    background = bg,
    placement  = "left",
    size       = "xxl",
    tilt = "none",
    panel = TRUE,
    opacity    = 0.85
  ) |>
  hud_overlay(
    overlay    = penguin_plot,
    background = _,          
    placement  = "right",
    size       = "xl",
    tilt="right",
    panel=TRUE,
    opacity    = 0.9
  )

result

image_browse(result)
weather_tbl |> 
  hud_overlay(
    background = bg,
    placement  = "left",
    size       = "large",
    tilt       = "right",
    opacity    = 0.92
  )

magick::image_write(result,"barb.png")



devtools::load_all("/home/luisd/Dropbox/darcyDB/pup/warphud")

result <- weather_tbl |>
  hud_overlay(
    background   = bg,
    placement    = "left",
    size         = "large",
    tilt         = "none",
    panel        = list(
      panel_color  = "#0D3B1ACC",
      border_color = "#39FF14DD",
      border_width = 28,
      padding      = 30
    ),
    opacity      = 0.85
  ) |>
  hud_overlay(
    overlay      = penguin_plot,
    background   = _,
    placement    = "right",
    size         = "large",
    tilt         = "right",
    panel        = list(
      panel_color  = "#0D3B1ACC",
      border_color = "#39FF14DD",
      border_width = 28,
      padding      = 30
    ),
    opacity      = 0.9
  )

result
