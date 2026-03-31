#' warphud: Warp ggplot2 and gt Objects for HUD-Style Image Overlays
#'
#' @description
#' Renders ggplot2 and gt objects as images, applies optional perspective
#' warp distortions, and composites them over background images with
#' transparency — producing a heads-up display (HUD) effect.
#'
#' The main entry points are:
#' - [render_hud()]: render a ggplot2 or gt object to a `magick-image`
#' - [warp_hud()]: apply a perspective warp to a `magick-image`
#' - [composite_hud()]: overlay a `magick-image` onto a background
#' - [hud_overlay()]: convenience wrapper chaining all three steps
#'
#' @keywords internal
"_PACKAGE"
