#' Composite a HUD overlay onto a background image
#'
#' Places a `magick-image` overlay onto a background image at a specified
#' position and opacity.
#'
#' @param background A path to an image file, a URL, or a `magick-image`
#'   object to use as the background.
#' @param overlay A `magick-image` object to overlay — typically the output
#'   of [render_hud()] or [warp_hud()].
#' @param x Horizontal pixel offset of the overlay's top-left corner from
#'   the background's top-left. Default `0`.
#' @param y Vertical pixel offset of the overlay's top-left corner from
#'   the background's top-left. Default `0`.
#' @param opacity A number in `[0, 1]` controlling the overlay's
#'   transparency. `1` is fully opaque, `0` is invisible. Default `0.85`.
#' @param operator ImageMagick compositing operator. Default `"over"`.
#'   See [magick::image_composite()] for the full list of operators.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A `magick-image` of the same dimensions as `background`.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' bg  <- magick::image_read("photo.jpg")
#' p   <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 400, height = 280)
#' out <- composite_hud(bg, img, x = 50, y = 30, opacity = 0.8)
#' magick::image_browse(out)
#' }
#'
#' @export
composite_hud <- function(background, overlay,
                           x = 0, y = 0,
                           opacity = 0.85,
                           operator = "over",
                           ...) {
  if (!inherits(background, "magick-image")) {
    background <- magick::image_read(background)
  }

  overlay <- .apply_opacity(overlay, opacity)

  magick::image_composite(
    image    = background,
    composite_image = overlay,
    operator = operator,
    offset   = magick::geometry_point(x, y)
  )
}

# ── Internal helpers ──────────────────────────────────────────────────────────

# Scale the alpha channel of a magick image by a factor in [0, 1].
.apply_opacity <- function(img, opacity) {
  if (isTRUE(all.equal(opacity, 1))) return(img)

  opacity <- max(0, min(1, opacity))

  # image_fx() applies an ImageMagick expression per-channel.
  # "a * <factor>" scales the existing alpha values uniformly.
  expr <- paste0("a*", opacity)
  magick::image_fx(img, expression = expr, channel = "alpha")
}
