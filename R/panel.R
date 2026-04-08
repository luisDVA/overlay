#' Wrap a magick image in a dark semi-transparent HUD panel
#'
#' Adds a dark, rectangular background (the "panel") around a `magick-image`,
#' optionally with a coloured border line. The result is a larger image with
#' the original content centred on the panel, ready for [warp_hud()] or
#' [composite_hud()].
#'
#' @param img A `magick-image` object, typically from [render_hud()].
#' @param padding Number of pixels to add around all four sides of `img`
#'   before drawing the panel frame. Default `20`.
#' @param panel_color Background colour of the panel as a CSS hex string
#'   (including alpha channel). Default `"#111111CC"` — near-black at ~80%
#'   opacity.
#' @param border_color Colour of the border drawn around the panel edge.
#'   Set to `NA` (default) to omit the border entirely. Pass a hex colour
#'   with alpha (e.g. `"#57FF8877"`) and a large `border_width` for a glow
#'   effect.
#' @param border_width Controls the glow spread: each unit adds one concentric
#'   stroke pass, widest and most transparent outermost, thinnest and most
#'   opaque innermost. Default `2`.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A `magick-image` whose dimensions are `width + 2*padding` by
#'   `height + 2*padding` relative to the input.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 480, height = 320, bg = "transparent")
#'
#' # HUD panel with a green glow border
#' panel <- hud_panel(img,
#'                    panel_color  = "#1B6B3ACC",
#'                    border_color = "#57FF8877",
#'                    border_width = 6)
#' }
#'
#' @export
hud_panel <- function(img,
                      padding      = 20,
                      panel_color  = "#111111CC",
                      border_color = NA,
                      border_width = 2,
                      ...) {
  info <- magick::image_info(img)
  pw   <- info$width  + 2L * as.integer(padding)
  ph   <- info$height + 2L * as.integer(padding)

  # Step 1: flat opaque panel + content composite
  panel_rgb <- substr(panel_color, 1L, 7L)
  flat <- magick::image_blank(pw, ph, color = panel_rgb)

  flat <- magick::image_composite(
    flat, img,
    operator = "over",
    offset   = magick::geometry_point(padding, padding)
  )

  # Step 2: alpha mask applied in one shot via CopyOpacity
  alpha_mask <- magick::image_blank(pw, ph, color = "none")
  alpha_mask <- magick::image_draw(alpha_mask)
  dev_id_m <- grDevices::dev.cur()
  on.exit(
    if (dev_id_m %in% grDevices::dev.list()) grDevices::dev.off(dev_id_m),
    add = TRUE
  )
  graphics::rect(0, 0, pw, ph, col = panel_color, border = NA)
  grDevices::dev.off(dev_id_m)

  grey_mask <- magick::image_channel(alpha_mask, "Alpha")
  panel_img <- magick::image_composite(flat, grey_mask, operator = "CopyOpacity")

  # Step 3: glow border using ImageMagick blur for a real spread effect.
  if (is.na(border_color)) return(panel_img)

  border_rgb   <- substr(border_color, 1L, 7L)
  border_alpha <- if (nchar(border_color) == 9L)
    strtoi(substr(border_color, 8L, 9L), 16L) / 255
  else 1

  spread <- max(1L, as.integer(border_width))

  # Expand canvas by spread on every side so the blur has room to bleed outward
  # without being clipped.  We composite the panel back onto the centre of the
  # expanded result afterwards.
  expand  <- spread * 2L
  gw      <- pw + 2L * expand
  gh      <- ph + 2L * expand

  glow <- magick::image_blank(gw, gh, color = "none")
  glow <- magick::image_draw(glow)
  dev_id_g <- grDevices::dev.cur()
  on.exit(
    if (dev_id_g %in% grDevices::dev.list()) grDevices::dev.off(dev_id_g),
    add = TRUE
  )
  # Draw the rect centred on the expanded canvas
  graphics::rect(expand, expand, expand + pw, expand + ph,
                 col = NA, border = border_rgb, lwd = 1)
  grDevices::dev.off(dev_id_g)

  # Blur — now the spread has room to bleed outward
  glow <- magick::image_blur(glow, radius = spread * 2, sigma = spread)

  # Scale alpha to border_color's alpha byte
  if (!isTRUE(all.equal(border_alpha, 1))) {
    glow <- magick::image_fx(glow,
                             expression = paste0("a*", border_alpha),
                             channel    = "alpha")
  }

  # Place panel_img centred on the expanded glow canvas, then crop back
  result <- magick::image_composite(
    glow, panel_img,
    operator = "over",
    offset   = magick::geometry_point(expand, expand)
  )

  magick::image_crop(
    result,
    magick::geometry_area(gw, gh)
  )
}
#' Wrap a magick image in a dark semi-transparent HUD panel
#'
#' Adds a dark rectangular background (the "panel") around a `magick-image`,
#' optionally with a coloured border line. The result is a larger image with
#' the original content centred on the panel, ready for [warp_hud()] or
#' [composite_hud()].
#'
#' @param img A `magick-image` object, typically from [render_hud()].
#' @param padding Number of pixels to add around all four sides of `img`
#'   before drawing the panel frame. Default `20`.
#' @param panel_color Background colour of the panel as a CSS hex string
#'   (including alpha channel). Default "#111111CC" — near-black at ~80
#'   opacity.
#' @param border_color Colour of the border drawn around the panel edge.
#'   Set to `NA` (default) to omit the border entirely. The border is drawn as
#'   a single stroked rectangle; to change thickness use `border_width`.
#' @param border_width Line width of the border in pixels. Default `2`.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A `magick-image` whose dimensions are `width + 2*padding` by
#'   `height + 2*padding` relative to the input.
#'
#' @examples
#' \\dontrun{
#' library(ggplot2)
#' p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 480, height = 320, bg = "transparent")
#'
#' # HUD panel with a colored border
#' panel <- hud_panel(img,
#'                    panel_color  = "#1B6B3ACC",
#'                    border_color = "#57FF8877",
#'                    border_width = 4)
#' }
#'
#' @export
hud_panel <- function(img,
                      padding      = 20,
                      panel_color  = "#111111CC",
                      border_color = NA,
                      border_width = 2,
                      ...) {
  info <- magick::image_info(img)
  pw   <- info$width  + 2L * as.integer(padding)
  ph   <- info$height + 2L * as.integer(padding)

  # Step 1: flat opaque panel + content composite
  panel_rgb <- substr(panel_color, 1L, 7L)
  flat <- magick::image_blank(pw, ph, color = panel_rgb)

  flat <- magick::image_composite(
    flat, img,
    operator = "over",
    offset   = magick::geometry_point(padding, padding)
  )

  # Step 2: alpha mask applied in one shot via CopyOpacity
  alpha_mask <- magick::image_blank(pw, ph, color = "none")
  alpha_mask <- magick::image_draw(alpha_mask)
  dev_id_m <- grDevices::dev.cur()
  on.exit(
    if (dev_id_m %in% grDevices::dev.list()) grDevices::dev.off(dev_id_m),
    add = TRUE
  )
  graphics::rect(0, 0, pw, ph, col = panel_color, border = NA)
  grDevices::dev.off(dev_id_m)

  grey_mask <- magick::image_channel(alpha_mask, "Alpha")
  panel_img <- magick::image_composite(flat, grey_mask, operator = "CopyOpacity")

  # Step 3: draw a simple stroked border (no glow)
  if (!is.na(border_color)) {
    border_layer <- magick::image_blank(pw, ph, color = "none")
    border_layer <- magick::image_draw(border_layer)
    dev_id_b <- grDevices::dev.cur()
    on.exit(
      if (dev_id_b %in% grDevices::dev.list()) grDevices::dev.off(dev_id_b),
      add = TRUE
    )
    graphics::rect(0, 0, pw, ph,
                   col = NA,
                   border = border_color,
                   lwd = border_width)
    grDevices::dev.off(dev_id_b)

    panel_img <- magick::image_composite(panel_img, border_layer, operator = "over")
  }

  panel_img
}
