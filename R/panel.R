#' Wrap a magick image in a dark semi-transparent panel border
#'
#' Adds a dark, rectangular background (the "panel") around a `magick-image`,
#' with an optional colored-border. The result is a larger image with
#' the original content centred on the panel, ready for [warp_hud()] or
#' [composite_hud()].
#'
#' @param img A `magick-image` object, typically from [render_hud()].
#' @param padding Number of pixels to add around all four sides of `img`
#'   before drawing the panel frame. Default `20`.
#' @param panel_color Background colour of the panel as a CSS hex string
#'   (including alpha channel). Default `"#111111CC"`.
#' @param border_color Colour of the border drawn around the panel edge.
#'   Set to `NA` (default) to omit the border.
#' @param border_width Line width of the border in pixels. Defaults to `2`.
#'
#' @return A `magick-image` with size `width + 2*padding` by
#'   `height + 2*padding` relative to the input.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 480, height = 320, bg = "transparent")
#'
#' # panel with a green border
#' panel <- hud_panel(img,
#'                    panel_color  = "#1B6B3ACC",
#'                    border_color = "#57FF8877",
#'                    border_width = 2)
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

  # flat opaque panel + content composite
  panel_rgb <- substr(panel_color, 1L, 7L)
  flat <- magick::image_blank(pw, ph, color = panel_rgb)

  flat <- magick::image_composite(
    flat, img,
    operator = "over",
    offset   = magick::geometry_point(padding, padding)
  )

  # alpha mask applied via CopyOpacity
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

  # simple stroked border
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
