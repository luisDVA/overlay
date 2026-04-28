#' Render a ggplot2, gt, or carbon code image to a magick image
#'
#' Converts a ggplot2 plot, gt table, or carbon.js code image to a
#' `magick-image`, ready for warping or compositing. Dispatches automatically
#' based on the class of `x`.
#'
#' @param x A ggplot2 (`"ggplot"`), gt (`"gt_tbl"`), or magick image object
#'   (from [carbon_image()]).
#' @param width Width of the output image in pixels. Default `400`.
#' @param height Height of the output image in pixels. Default `300`.
#' @param bg Background color passed to the graphics device. Use
#'   `"transparent"` (default) to keep alpha when compositing.
#'   Note: gt objects rendered via `gt::gtsave()` may not fully honor
#'   a transparent background; in that case use a dark colour such as
#'   `"#00000000"` and accept the white panel, or style the gt table
#'   background directly. For `carbon_image()` objects this argument is
#'   ignored because carbon.js controls its own background via `bg_color`.
#' @param res Resolution in DPI used when rasterizing the plot. Default `150`.
#'   Ignored for `carbon_image()` objects.
#'
#' @return A `magick-image` object.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 500, height = 350)
#'
#' # Carbon code block
#' code_img <- carbon_image('fit <- lm(mpg ~ wt, data = mtcars)\nsummary(fit)')
#' img <- render_hud(code_img, width = 600, height = 300)
#' }
#'
#' @export
render_hud <- function(x, width = 400, height = 300,
                       bg = "transparent", res = 150, ...) {
  if (inherits(x, "ggplot")) {
    render_hud_ggplot(x, width = width, height = height, bg = bg, res = res)
  } else if (inherits(x, "gt_tbl")) {
    render_hud_gt(x, width = width, height = height, bg = bg, res = res)
  } else if (inherits(x, "magick-image")) {
    # Assume a carbon image or other pre-rendered magick image
    render_hud_magick(x, width = width, height = height)
  } else {
    rlang::abort(
      paste0(
        "`x` must be a ggplot2, gt, or magick-image object, not <",
        class(x)[1], ">."
      )
    )
  }
}

# helpers

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

  # gtsave() uses a headless browser that composites a solid background into
  # the PNG, so the rendered image has no real alpha channel. Work around
  # this by injecting a chroma-key colour as the body background, rendering,
  # then erasing that colour to restore transparency.
  chroma <- "#FF00FF"
  x_chroma <- gt::opt_css(
    x,
    paste0("body, html { background: ", chroma, " !important; }")
  )

  gt::gtsave(x_chroma, filename = tmp)

  img <- magick::image_read(tmp)

  # Erase chroma-key pixels; fuzz = 5 handles anti-aliased fringe pixels
  # without biting into coloured table content
  img <- magick::image_transparent(img, chroma, fuzz = 5)

  # Resize to requested dimensions 
  magick::image_resize(img, magick::geometry_size_pixels(width, height))
}

render_hud_magick <- function(x, width, height) {
  # Resize carbon or other magick images to requested dimensions
  magick::image_resize(x, magick::geometry_size_pixels(width, height))
}
