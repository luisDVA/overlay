#' Render a ggplot2 or gt object to a magick image
#'
#' Converts a ggplot2 plot or gt table to a `magick-image`, ready for warping
#' or compositing. Dispatches automatically based on the class of `x`.
#'
#' @param x A ggplot2 (`"ggplot"`) or gt (`"gt_tbl"`) object.
#' @param width Width of the output image in pixels. Default `400`.
#' @param height Height of the output image in pixels. Default `300`.
#' @param bg Background colour passed to the graphics device. Use
#'   `"transparent"` (default) to preserve alpha when compositing.
#'   Note: gt objects rendered via `gt::gtsave()` may not fully honour
#'   a transparent background; in that case use a dark colour such as
#'   `"#00000000"` and accept the white panel, or style the gt table
#'   background directly.
#' @param res Resolution in DPI used when rasterising the plot. Default `150`.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A `magick-image` object.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 500, height = 350)
#' }
#'
#' @export
render_hud <- function(x, width = 400, height = 300,
                       bg = "transparent", res = 150, ...) {
  if (inherits(x, "ggplot")) {
    render_hud_ggplot(x, width = width, height = height, bg = bg, res = res)
  } else if (inherits(x, "gt_tbl")) {
    render_hud_gt(x, width = width, height = height, bg = bg, res = res)
  } else {
    rlang::abort(
      paste0(
        "`x` must be a ggplot2 or gt object, not <",
        class(x)[1], ">."
      )
    )
  }
}

# ── Internal helpers ──────────────────────────────────────────────────────────

render_hud_ggplot <- function(x, width, height, bg, res) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  ragg::agg_png(
    filename   = tmp,
    width      = width,
    height     = height,
    units      = "px",
    res        = res,
    background = bg
  )
  print(x)
  grDevices::dev.off()

  magick::image_read(tmp)
}

render_hud_gt <- function(x, width, height, bg, res) {
  rlang::check_installed("gt", reason = "to render gt objects")

  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  # gt::gtsave() drives a headless browser; width/height are approximate
  gt::gtsave(x, filename = tmp)

  img <- magick::image_read(tmp)

  # Resize to requested dimensions so downstream compositing is predictable
  img <- magick::image_resize(img, magick::geometry_size_pixels(width, height))

  img
}
