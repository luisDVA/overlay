#' Apply a perspective warp to a magick image
#'
#' Distorts a `magick-image` using a four-point perspective transformation,
#' giving the "floating HUD panel" effect where a flat image appears to recede
#' or tilt in 3-D space.
#'
#' @param img A `magick-image` object, typically produced by [render_hud()].
#' @param corners A named list specifying how far each corner of the image
#'   should move from its natural position. Each element is a numeric vector
#'   of length 2: `c(dx, dy)`, where positive values move right/down.
#'   Names must be `"tl"` (top-left), `"tr"` (top-right), `"bl"`
#'   (bottom-left), and `"br"` (bottom-right). Any corner omitted defaults
#'   to `c(0, 0)` (no movement).
#'
#'   **Example** — tilt the panel so the left edge rises and the right
#'   edge drops:
#'   ```r
#'   corners = list(tl = c(0, -20), bl = c(0, -20),
#'                  tr = c(0,  20), br = c(0,  20))
#'   ```
#' @param keep_size If `TRUE` (default), the output image is cropped/padded
#'   back to the original pixel dimensions. If `FALSE`, ImageMagick may
#'   expand the canvas to contain the warped result.
#' @param ... Currently unused; reserved for future arguments.
#'
#' @return A warped `magick-image` with an alpha channel preserved.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' img <- render_hud(p, width = 500, height = 350)
#'
#' # Tilt the top edge backward (raise both top corners)
#' warped <- warp_hud(img, corners = list(tl = c(20, -15), tr = c(-20, -15)))
#' magick::image_browse(warped)
#' }
#'
#' @export
warp_hud <- function(img, corners = list(), keep_size = TRUE, ...) {
  info <- magick::image_info(img)
  w    <- info$width
  h    <- info$height

  resolved <- .resolve_corners(corners, w, h)

  # If any destination corner falls outside the canvas it will be hard-clipped.
  # Detect overflow on all four sides, pre-pad the canvas so every destination
  # corner lands inside the enlarged canvas, and shift src + dst together so
  # the warp geometry is preserved.  The output therefore has tighter dimensions
  # that exactly bound the warped quad rather than the original w × h.
  dst_xs     <- c(resolved$tl[1], resolved$tr[1], resolved$bl[1], resolved$br[1])
  dst_ys     <- c(resolved$tl[2], resolved$tr[2], resolved$bl[2], resolved$br[2])
  pad_left   <- max(0L, as.integer(ceiling(-min(dst_xs))))
  pad_top    <- max(0L, as.integer(ceiling(-min(dst_ys))))
  pad_right  <- max(0L, as.integer(ceiling( max(dst_xs) - w)))
  pad_bottom <- max(0L, as.integer(ceiling( max(dst_ys) - h)))

  any_pad <- pad_left > 0L || pad_top > 0L || pad_right > 0L || pad_bottom > 0L

  if (any_pad) {
    shift <- c(pad_left, pad_top)
    new_w <- w + pad_left + pad_right
    new_h <- h + pad_top  + pad_bottom
    img   <- magick::image_blank(new_w, new_h, color = "none") |>
      magick::image_composite(img, operator = "over",
                              offset = magick::geometry_point(pad_left, pad_top))
    src <- list(
      tl = c(0, 0) + shift, tr = c(w, 0) + shift,
      bl = c(0, h) + shift, br = c(w, h) + shift
    )
    dst <- lapply(resolved, `+`, shift)
  } else {
    new_w <- w
    new_h <- h
    src   <- list(tl = c(0, 0), tr = c(w, 0), bl = c(0, h), br = c(w, h))
    dst   <- resolved
  }

  # ImageMagick perspective control vector:
  # c(src_x, src_y, dst_x, dst_y) repeated for each of 4 corners
  control <- c(
    src$tl, dst$tl,
    src$tr, dst$tr,
    src$bl, dst$bl,
    src$br, dst$br
  )

  bestfit <- !keep_size

  warped <- magick::image_background(img, "none") |>
    magick::image_distort("Perspective", coordinates = control, bestfit = bestfit)

  warped <- .mask_warp_quad(warped, img, control, bestfit,
                             pad_left = pad_left, pad_top = pad_top,
                             orig_w = w, orig_h = h)

  if (keep_size) {
    warped <- magick::image_crop(warped, magick::geometry_size_pixels(new_w, new_h))
  }

  warped
}

# ── Internal helpers ──────────────────────────────────────────────────────────

# Resolve corner offsets to absolute destination coordinates.
# Natural corners: TL=(0,0), TR=(w,0), BL=(0,h), BR=(w,h)
.resolve_corners <- function(corners, w, h) {
  defaults <- list(tl = c(0, 0), tr = c(0, 0), bl = c(0, 0), br = c(0, 0))
  corners  <- utils::modifyList(defaults, corners)

  list(
    tl = c(0, 0) + corners$tl,
    tr = c(w, 0) + corners$tr,
    bl = c(0, h) + corners$bl,
    br = c(w, h) + corners$br
  )
}

# After perspective distortion, Edge virtual pixels bleed the nearest source
# edge colour into the empty regions around the warped quad.  Fix by warping
# a co-registered black-border/white-interior mask with the *same* transform:
# the extended black pixels become transparent via CopyOpacity, while the
# white interior preserves the warped content.  Using an identical distort
# call guarantees pixel-perfect alignment without any offset arithmetic.
# After perspective distortion, Edge virtual pixels bleed the nearest source
# edge colour into the empty regions around the warped quad.  Fix by warping
# a co-registered black-border/white-interior mask with the *same* transform:
# the extended black pixels become transparent via CopyOpacity, while the
# white interior preserves the warped content.  Using an identical distort
# call guarantees pixel-perfect alignment without any offset arithmetic.
#
# When the source canvas was padded (pad_left / pad_top > 0) the white
# interior must cover only the *original* content area, not the transparent
# padding rows/columns, otherwise virtual-pixel bleed from those transparent
# regions will corrupt the composite.
.mask_warp_quad <- function(warped, src_img, control, bestfit,
                             pad_left = 0L, pad_top = 0L,
                             orig_w = NULL, orig_h = NULL) {
  info <- magick::image_info(src_img)
  w <- info$width
  h <- info$height

  if (is.null(orig_w)) orig_w <- w - pad_left
  if (is.null(orig_h)) orig_h <- h - pad_top

  # White interior bounded to the original content area (1 px inset on each
  # side to guarantee a transparent border regardless of padding).
  interior <- magick::image_blank(orig_w - 2L, orig_h - 2L, color = "white")
  mask_src <- magick::image_blank(w, h, color = "none") |>
    magick::image_composite(interior, operator = "over",
                            offset = magick::geometry_point(pad_left + 1L,
                                                            pad_top  + 1L))

  mask_warped <- magick::image_distort(mask_src, "Perspective",
                                       coordinates = control,
                                       bestfit = bestfit)

  magick::image_composite(warped, mask_warped, operator = "CopyOpacity")
}
