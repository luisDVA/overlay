#' Wrap a magick image in a dark semi-transparent HUD panel
#'
#' Adds a dark, rounded-rectangle background (the "panel") around a
#' `magick-image`, optionally with a coloured border line. The result is a
#' larger image with the original content centred on the panel, ready for
#' [warp_hud()] or [composite_hud()].
#'
#' @param img A `magick-image` object, typically from [render_hud()].
#' @param padding Number of pixels to add around all four sides of `img`
#'   before drawing the panel frame. Default `20`.
#' @param corner_radius Radius of the rounded corners in pixels. Default `14`.
#' @param panel_color Background colour of the panel as a CSS hex string
#'   (including alpha channel). Default `"#111111CC"` — near-black at ~80%
#'   opacity.
#' @param border_color Colour of the border drawn around the panel edge.
#'   Set to `NA` (default) to omit the border entirely. A hex colour with
#'   alpha works well for a glow effect, e.g. `"#00FF8866"`.
#' @param border_width Line width of the border in pixels. Ignored if
#'   `border_color` is `NA`. Default `2`.
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
#' # Wrap in a HUD panel with a subtle cyan border
#' panel <- hud_panel(img, border_color = "#00FFFF66")
#' }
#'
#' @export
hud_panel <- function(img,
                      padding       = 20,
                      corner_radius = 14,
                      panel_color   = "#111111CC",
                      border_color  = NA,
                      border_width  = 2,
                      ...) {
  info <- magick::image_info(img)
  pw   <- info$width  + 2L * as.integer(padding)
  ph   <- info$height + 2L * as.integer(padding)

  canvas <- magick::image_blank(pw, ph, color = "none")
  canvas <- magick::image_draw(canvas)
  dev_id <- grDevices::dev.cur()
  on.exit(if (dev_id %in% grDevices::dev.list()) grDevices::dev.off(dev_id),
          add = TRUE)

  pts <- .rounded_rect_pts(0, 0, pw, ph, r = corner_radius)

  # Fill
  graphics::polygon(pts[, 1], pts[, 2], col = panel_color, border = NA)

  # Optional border
  if (!is.na(border_color)) {
    graphics::polygon(pts[, 1], pts[, 2],
                      col    = NA,
                      border = border_color,
                      lwd    = border_width)
  }

  grDevices::dev.off(dev_id)

  # Composite content image centred on the panel
  magick::image_composite(
    canvas, img,
    offset = magick::geometry_point(padding, padding)
  )
}

# ── Internal helpers ──────────────────────────────────────────────────────────

# Compute vertices of a rounded rectangle as a 2-column matrix (x, y).
# Uses image coordinates: (0,0) top-left, y increases downward.
# r: corner radius in pixels. n_arc: smoothness of each arc.
.rounded_rect_pts <- function(x1, y1, x2, y2, r, n_arc = 32) {
  r   <- min(r, (x2 - x1) / 2, (y2 - y1) / 2)
  arc <- function(cx, cy, from, to) {
    a <- seq(from, to, length.out = n_arc)
    cbind(cx + r * cos(a), cy + r * sin(a))
  }
  rbind(
    arc(x1 + r, y1 + r,  pi,    3 * pi / 2),  # top-left
    arc(x2 - r, y1 + r,  3 * pi / 2, 2 * pi), # top-right
    arc(x2 - r, y2 - r,  0,     pi / 2),       # bottom-right
    arc(x1 + r, y2 - r,  pi / 2, pi)           # bottom-left
  )
}
