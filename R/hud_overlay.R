#' Render, warp, and composite a ggplot2, gt, or code snippet over a background image
#'
#' A convenience wrapper that chains [render_hud()], (optionally) [hud_panel()],
#' (optionally) [warp_hud()], and [composite_hud()] in a single call.
#'
#' @param overlay A ggplot2, gt, or an image of a code snippet to render and composite. Placed first
#'   so the ggplot2/gt/code objects can be piped directly into the function.
#' @param background A path to an image file, a URL, or a `magick-image`
#'   object to use as the background.
#' @param x Horizontal pixel offset of the overlay's top-left corner.
#'   Overrides `placement` when supplied. Default `0`.
#' @param y Vertical pixel offset of the overlay's top-left corner.
#'   Overrides `placement` when supplied. Default `0`.
#' @param placement Optional placement shorthand. One of `"left"`, `"right"`,
#'   `"centre"` (or `"center"`), `"top-left"`, `"top-right"`, `"top"`,
#'   `"bottom-left"`, `"bottom-right"`, `"bottom"`. Auto-computes `x` and `y`
#'   from the background dimensions and `width`/`height`. Ignored for any axis
#'   where `x` or `y` is supplied explicitly.
#' @param margin Pixel gap between the overlay and the background edge when
#'   `placement` is used. Default `40L`.
#' @param size Optional size preset: `"small"` (280 × 190), `"medium"`
#'   (420 × 300), `"large"` (580 × 380), `"xl"` (760 × 500), or `"xxl"`
#'   (960 × 640). Sets `width` and `height` when those arguments are not
#'   supplied explicitly. Ignored if both `width` and `height` are provided.
#' @param width Width in pixels at which to render `overlay`. Overrides
#'   `size` when supplied. Default `400` (when `size` is `NULL`).
#' @param height Height in pixels at which to render `overlay`. Overrides
#'   `size` when supplied. Default `300` (when `size` is `NULL`).
#' @param panel Controls whether a HUD panel frame is applied via [hud_panel()]
#'   after rendering. Can be either:
#'   - `FALSE` (default): no border.
#'   - `TRUE`: apply a panel with default settings.
#'   - A named list of arguments, passed to [hud_panel()] (e.g.
#'     `list(border_color = "#00FF8866")`).
#' @param tilt Optional tilt preset. One of `"none"`, `"left"`, `"right"`,
#'   `"top"`, or `"bottom"`. `"none"` applies no warp (flat overlay). Generate a perspective warp scaled to the overlay dimensions:
#'   `"left"` / `"right"` tilt the corresponding vertical edge away; `"top"` /
#'   `"bottom"` recede the corresponding horizontal edge. Ignored when `corners`
#'   is supplied.
#' @param corners Optional named list of corner offset vectors `c(dx, dy)`
#'   passed to [warp_hud()]. Names are `"tl"`, `"tr"`, `"bl"`, `"br"`.
#'   Overrides `tilt` when supplied. If both are `NULL` no warp is applied.
#' @param opacity Overlay transparency/alpha between `[0, 1]`. Default `0.85`.
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
#' @param ... Additional arguments (currently unused, but reserved for future
#'   extensions).
#'
#' @return A `magick-image` of the same dimensions as `background`.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' library(gt)
#' library(tibble)
#'
#' # Create a gt table
#' weather_tbl <- tibble(
#'   location = "King George Island, Antarctica",
#'   temp     = "-2 °C",
#'   wind     = "37 km/h"
#' ) |>
#'   gt() |>
#'   tab_header(title = "Weather Report") |>
#'   opt_stylize(style = 6, color = "blue")
#'
#' # Create a ggplot
#' p <- ggplot(penguins, aes(bill_len, bill_dep)) +
#'   geom_point(color = "#5b9bd5") +
#'   theme_minimal()
#'
#' # Composite them onto a background
#' bg <- system.file("extdata", "penguins.jpg", package = "overlay")
#'
#' out <- weather_tbl |>
#'   hud_overlay(
#'     background = bg,
#'     placement  = "top-left",
#'     size       = "medium",
#'     panel      = TRUE,
#'     opacity    = 0.85
#'   ) |>
#'   hud_overlay(
#'     overlay    = p,
#'     background = _,
#'     placement  = "bottom-right",
#'     size       = "medium",
#'     tilt       = "right",
#'     panel      = TRUE,
#'     opacity    = 0.9
#'   )
#'
#' magick::image_browse(out)
#' 
#' #' # Multiple overlays with pipe placeholder
#' code <- 'ggplot(penguins, aes(bill_len, bill_dep)) + geom_point()'
#' code_img <- carbon_image(code, lang = "r", theme = "dark")
#'
#' result <- hud_overlay(
#'   overlay = p,
#'   background = bg,
#'   placement = "left",
#'   size = "xl"
#' ) |>
#'   hud_overlay(
#'     overlay = code_img,
#'     background = _,
#'     placement = "right",
#'     size = "xl"
#'   )
#' }
#' 
#' @export
hud_overlay <- function(overlay, background,
                         x = NULL, y = NULL,
                         placement = NULL,
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

  # check for tilt preset 
  if (is.null(corners) && !is.null(tilt)) {
    corners <- .hud_tilt_corners(tilt, width, height)
  }

  # Only supersample when a warp will be applied; oterhwise the
  # high-res → downscale round-trip aliases ggplot grid lines into unwanted scanlines
  ss <- if (!is.null(corners)) max(1L, as.integer(supersample)) else 1L

  if (!is.null(placement) && (is.null(x) || is.null(y))) {
    bg_img  <- if (inherits(background, "magick-image")) background
               else magick::image_read(background)
    bg_info <- magick::image_info(bg_img)
    gpos    <- .hud_placement_pos(placement, width, height,
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
      panel_args$padding      <- (if (is.null(panel_args$padding))      20L else panel_args$padding)      * ss
      panel_args$border_width <- (if (is.null(panel_args$border_width))  2L else panel_args$border_width) * ss
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
                opacity  = opacity,
                operator = operator)
}

# helpers 

.hud_tilt_corners <- function(tilt, width, height) {
  tilt <- match.arg(tilt, c("none", "left", "right", "top", "bottom"))
  if (tilt == "none") return(NULL)

  # Vertical-axis tilts (left/right): one vertical edge moves differentially
  # in y  one corner rises and the other drops for perspective
  up   <- -round(height * 0.18)
  down <-  round(height * 0.07)

  # Horizontal-axis tilts (top/bottom): one horizontal edge converges inward
  # in x so the two corners come closer together
  # A small y nudge reinforces the depth cue
  shrink <- round(width  * 0.15)
  lift   <- -round(height * 0.06)
  drop   <-  round(height * 0.06)

  switch(tilt,
    left   = list(tl = c(0,       up),   bl = c(0,        down)),
    right  = list(tr = c(0,       up),   br = c(0,        down)),
    top    = list(tl = c( shrink, lift), tr = c(-shrink,  lift)),
    bottom = list(bl = c( shrink, drop), br = c(-shrink,  drop))
  )
}

.hud_placement_pos <- function(placement, width, height, bg_w, bg_h, margin) {
  placement <- match.arg(
    tolower(placement),
    c("left", "right", "centre", "center",
      "top-left", "top-right", "top",
      "bottom-left", "bottom-right", "bottom")
  )
  if (placement == "center") placement <- "centre" # spelling

  x <- switch(placement,
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

  y <- switch(placement,
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
    large  = list(width = 580L, height = 380L),
    xl     = list(width = 760L, height = 500L),
    xxl    = list(width = 960L, height = 640L)
  )
  if (is.null(size)) return(list(width = 400L, height = 300L))
  size <- match.arg(size, names(presets))
  presets[[size]]
}
