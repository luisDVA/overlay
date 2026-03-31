#' Render, warp, and composite a ggplot2 or gt object over a background image
#'
#' A convenience wrapper that chains [render_hud()], (optionally) [hud_panel()],
#' (optionally) [warp_hud()], and [composite_hud()] in a single call.
#'
#' @param overlay A ggplot2 or gt object to render and composite. Placed first
#'   so ggplot2/gt objects can be piped directly into the function.
#' @param background A path to an image file, a URL, or a `magick-image`
#'   object to use as the background.
#' @param x Horizontal pixel offset of the overlay's top-left corner.
#'   Overrides `gravity` when supplied. Default `0`.
#' @param y Vertical pixel offset of the overlay's top-left corner.
#'   Overrides `gravity` when supplied. Default `0`.
#' @param gravity Optional placement shorthand. One of `"left"`, `"right"`,
#'   `"centre"` (or `"center"`), `"top-left"`, `"top-right"`, `"top"`,
#'   `"bottom-left"`, `"bottom-right"`, `"bottom"`. Auto-computes `x` and `y`
#'   from the background dimensions and `width`/`height`. Ignored for any axis
#'   where `x` or `y` is supplied explicitly.
#' @param margin Pixel gap between the overlay and the background edge when
#'   `gravity` is used. Default `40L`.
#' @param size Optional size preset: `"small"` (280 × 190), `"medium"`
#'   (420 × 300), or `"large"` (580 × 380). Sets `width` and `height` when
#'   those arguments are not supplied explicitly. Ignored if both `width` and
#'   `height` are provided.
#' @param width Width in pixels at which to render `overlay`. Overrides
#'   `size` when supplied. Default `400` (when `size` is `NULL`).
#' @param height Height in pixels at which to render `overlay`. Overrides
#'   `size` when supplied. Default `300` (when `size` is `NULL`).
#' @param panel Controls whether a HUD panel frame is applied via [hud_panel()]
#'   after rendering. Options:
#'   - `FALSE` (default): no panel.
#'   - `TRUE`: apply a panel with default settings.
#'   - A named list of arguments forwarded to [hud_panel()] (e.g.
#'     `list(border_color = "#00FF8866", corner_radius = 18)`).
#' @param tilt Optional tilt preset. One of `"none"`, `"left"`, `"right"`,
#'   `"top"`, or `"bottom"`. `"none"` applies no warp (flat overlay). The
#'   others generate a perspective warp scaled to the overlay dimensions:
#'   `"left"` / `"right"` tilt the corresponding vertical edge away; `"top"` /
#'   `"bottom"` recede the corresponding horizontal edge. Ignored when `corners`
#'   is supplied explicitly.
#' @param corners Optional named list of corner offset vectors `c(dx, dy)`
#'   passed to [warp_hud()]. Names are `"tl"`, `"tr"`, `"bl"`, `"br"`.
#'   Overrides `tilt` when supplied. If both are `NULL` no warp is applied.
#' @param opacity Overlay transparency in `[0, 1]`. Default `0.85`.
#' @param bg Background colour for the rendered overlay. Default
#'   `"transparent"`.
#' @param res Resolution in DPI for rasterising the overlay. Default `150`.
#' @param keep_size Passed to [warp_hud()] when `corners` is not `NULL`.
#'   Default `TRUE`.
#' @param supersample Integer supersampling factor. Default `2L`. The overlay
#'   is rendered and panelled at `supersample` times the requested pixel
#'   dimensions (with proportionally scaled DPI and panel geometry), warped at
#'   that higher resolution, then downscaled with a Lanczos filter before
#'   compositing. This eliminates the horizontal scanline aliasing that
#'   ImageMagick's perspective distortion produces at steep angles. Increase to
#'   `3L` or `4L` for more aggressive anti-aliasing. Set to `1L` to disable.
#' @param operator ImageMagick compositing operator. Default `"over"`.
#' @param ... Currently unused.
#'
#' @return A `magick-image` of the same dimensions as `background`.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#'
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#'
#' out <- p |> hud_overlay(
#'   background  = "photo.jpg",
#'   x = 40, y = 60,
#'   width = 450, height = 280,
#'   panel      = list(border_color = "#39FF14"),
#'   corners    = list(tl = c(-110, 0), bl = c(-110, 0)),
#'   opacity    = 0.9
#' )
#' magick::image_browse(out)
#' }
#'
#' @export
hud_overlay <- function(overlay, background,
                         x = NULL, y = NULL,
                         gravity = NULL,
                         margin = 40L,
                         size = NULL,
                         width = NULL, height = NULL,
                         panel = FALSE,
                         tilt = NULL,
                         corners = NULL,
                         opacity = 0.85,
                         bg = "transparent",
                         res = 150,
                         keep_size = TRUE,
                         supersample = 2L,
                         operator = "over",
                         ...) {
  dims   <- .hud_size_dims(size)
  if (is.null(width))  width  <- dims[["width"]]
  if (is.null(height)) height <- dims[["height"]]

  # Resolve tilt preset to corners early so we know whether a warp will happen
  if (is.null(corners) && !is.null(tilt)) {
    corners <- .hud_tilt_corners(tilt, width, height)
  }

  # Only supersample when a warp will be applied; without distortion the
  # high-res→downscale round-trip aliases ggplot grid lines into artefacts
  ss <- if (!is.null(corners)) max(1L, as.integer(supersample)) else 1L

  if (!is.null(gravity) && (is.null(x) || is.null(y))) {
    bg_img  <- if (inherits(background, "magick-image")) background
               else magick::image_read(background)
    bg_info <- magick::image_info(bg_img)
    gpos    <- .hud_gravity_pos(gravity, width, height,
                                bg_info$width, bg_info$height,
                                as.integer(margin))
    if (is.null(x)) x <- gpos$x
    if (is.null(y)) y <- gpos$y
  }

  if (is.null(x)) x <- 0L
  if (is.null(y)) y <- 0L

  img <- render_hud(overlay,
                    width  = width  * ss,
                    height = height * ss,
                    bg     = bg,
                    res    = res    * ss)

  if (!isFALSE(panel)) {
    panel_args <- if (isTRUE(panel)) list() else panel
    if (ss > 1L) {
      panel_args$padding       <- (if (is.null(panel_args$padding))       20L else panel_args$padding)       * ss
      panel_args$corner_radius <- (if (is.null(panel_args$corner_radius)) 14L else panel_args$corner_radius) * ss
      panel_args$border_width  <- (if (is.null(panel_args$border_width))   2L else panel_args$border_width)  * ss
    }
    img <- do.call(hud_panel, c(list(img = img), panel_args))
  }

  if (!is.null(corners)) {
    scaled_corners <- if (ss > 1L) lapply(corners, `*`, ss) else corners
    img <- warp_hud(img, corners = scaled_corners, keep_size = keep_size)
  }

  if (ss > 1L) {
    wi  <- magick::image_info(img)$width
    hi  <- magick::image_info(img)$height
    img <- magick::image_resize(img,
             magick::geometry_size_pixels(wi %/% ss, hi %/% ss),
             filter = "Lanczos")
  }

  composite_hud(background, img,
                x = x, y = y,
                opacity = opacity,
                operator = operator)
}

# ── Internal helpers ──────────────────────────────────────────────────────────

.hud_tilt_corners <- function(tilt, width, height) {
  tilt <- match.arg(tilt, c("none", "left", "right", "top", "bottom"))
  if (tilt == "none") return(NULL)
  up   <- -round(height * 0.18)   # leading edge rises
  down <-  round(height * 0.07)   # trailing edge drops
  switch(tilt,
    left   = list(tl = c(0, up),   bl = c(0, down)),
    right  = list(tr = c(0, up),   br = c(0, down)),
    top    = list(tl = c(0, up),   tr = c(0, up)),
    bottom = list(bl = c(0, down), br = c(0, down))
  )
}

.hud_gravity_pos <- function(gravity, width, height, bg_w, bg_h, margin) {
  gravity <- match.arg(
    tolower(gravity),
    c("left", "right", "centre", "center",
      "top-left", "top-right", "top",
      "bottom-left", "bottom-right", "bottom")
  )
  if (gravity == "center") gravity <- "centre"

  x <- switch(gravity,
    "left"         = margin,
    "right"        = bg_w - width - margin,
    "centre"       = as.integer((bg_w - width) / 2L),
    "top-left"     = margin,
    "top-right"    = bg_w - width - margin,
    "top"          = as.integer((bg_w - width) / 2L),
    "bottom-left"  = margin,
    "bottom-right" = bg_w - width - margin,
    "bottom"       = as.integer((bg_w - width) / 2L)
  )

  y <- switch(gravity,
    "left"         = as.integer((bg_h - height) / 2L),
    "right"        = as.integer((bg_h - height) / 2L),
    "centre"       = as.integer((bg_h - height) / 2L),
    "top-left"     = margin,
    "top-right"    = margin,
    "top"          = margin,
    "bottom-left"  = bg_h - height - margin,
    "bottom-right" = bg_h - height - margin,
    "bottom"       = bg_h - height - margin
  )

  list(x = as.integer(x), y = as.integer(y))
}

.hud_size_dims <- function(size) {
  presets <- list(
    small  = list(width = 280L, height = 190L),
    medium = list(width = 420L, height = 300L),
    large  = list(width = 580L, height = 380L)
  )
  if (is.null(size)) return(list(width = 400L, height = 300L))
  size <- match.arg(size, names(presets))
  presets[[size]]
}
