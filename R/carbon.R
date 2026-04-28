#' Create an image of a code snippet with carbon.js via the carbonara API
#'
#' Generates a styled code image using the carbonara community API
#' (https://github.com/petersolopov/carbonara), which provides programmatic
#' access to carbon.js styling without a headless browser.
#'
#' @param x Character string with the code to render.
#' @param lang Programming language. Default `"r"`. See carbonara documentation
#'   for supported languages.
#' @param theme Overall look. `"dark"` (default, uses one-dark) or `"light"` (uses one-light).
#' @param timeout Request timeout in seconds. Defaults to `60`.
#' @param ... Additional carbonara API parameters. Common options include:
#'   - `backgroundColor`: background color (e.g., `"rgba(171,184,195,1)"`)
#'   - `theme`: theme name (overrides theme preset, e.g., `"monokai"`, `"nord"`)
#'   - `fontFamily`: font family (e.g., `"Hack"`, `"Fira Code"`)
#'   - `fontSize`: font size (e.g., `"14px"`)
#'   - `lineNumbers`: show line numbers (`TRUE` or `FALSE`)
#'   - `windowControls`: show window controls (`TRUE` or `FALSE`)
#'
#' @return A `magick-image` object.
#'
#' @examples
#' \dontrun{
#' # Dark theme (default)
#' img <- carbon_image("x <- 1:10\nplot(x)")
#' 
#' # Light theme
#' img <- carbon_image("x <- 1:10\nplot(x)", theme = "light")
#' 
#' # Custom theme and settings
#' img <- carbon_image("x <- 1:10", theme = "dark", 
#'                     backgroundColor = "rgba(0,0,0,1)",
#'                     fontSize = "16px")
#' }
#'
#' @export
carbon_image <- function(x, lang = "r", theme = c("dark", "light"), 
                        timeout = 60, ...) {
  
  rlang::check_installed("httr", reason = "making API requests to carbonara")
  
  theme <- match.arg(theme)
  
  # Collapse if needed
  if (length(x) > 1L) {
    x <- paste(x, collapse = "\n")
  }
  
  # Build JSON body for carbonara API with custom settings
  if (theme == "dark") {
    body <- list(
      code = x,
      language = lang,
      backgroundColor = "rgba(0,0,0,0)",
      theme = "one-dark",
      windowTheme = "bw",
      width = 680,
      dropShadow = FALSE,
      dropShadowOffsetY = "20px",
      dropShadowBlurRadius = "68px",
      windowControls = TRUE,
      widthAdjustment = TRUE,
      paddingVertical = "0px",
      paddingHorizontal = "0px",
      lineNumbers = FALSE,
      firstLineNumber = 1,
      fontFamily = "Source Code Pro",
      fontSize = "14px",
      lineHeight = "133%",
      squaredImage = FALSE,
      exportSize = "2x",
      watermark = FALSE
    )
  } else {
    body <- list(
      code = x,
      language = lang,
      backgroundColor = "rgba(189,16,224,1)",
      theme = "one-light",
      windowTheme = "bw",
      width = 680,
      dropShadow = FALSE,
      dropShadowOffsetY = "20px",
      dropShadowBlurRadius = "68px",
      windowControls = TRUE,
      widthAdjustment = TRUE,
      paddingVertical = "0px",
      paddingHorizontal = "0px",
      lineNumbers = FALSE,
      firstLineNumber = 1,
      fontFamily = "Hack",
      fontSize = "14px",
      lineHeight = "133%",
      squaredImage = FALSE,
      exportSize = "2x",
      watermark = FALSE
    )
  }
  
  # Merge with user parameters
  dots <- list(...)
  if (length(dots) > 0L) {
    body <- utils::modifyList(body, dots)
  }
  
  # Try multiple endpoints with retry logic
  endpoints <- c(
    "https://carbonara-42.herokuapp.com/api/cook",
    "https://carbonara.solopov.dev/api/cook"
  )
  
  response <- NULL
  last_error <- NULL
  
  for (endpoint in endpoints) {
    tryCatch({
      response <- httr::POST(
        endpoint,
        body = body,
        encode = "json",
        httr::timeout(timeout)
      )
      
      # If successful
      if (!httr::http_error(response)) {
        break
      }
      
      last_error <- sprintf(
        "Endpoint %s returned status %d",
        endpoint,
        httr::status_code(response)
      )
      response <- NULL
      
    }, error = function(e) {
      last_error <<- sprintf(
        "Endpoint %s failed: %s",
        endpoint,
        conditionMessage(e)
      )
      response <<- NULL
    })
  }
  
  # if all endpoints failed
  if (is.null(response)) {
    rlang::abort(
      sprintf(
        "All carbonara API endpoints failed. Last error: %s",
        last_error
      )
    )
  }
  
  # Get the image content
  img_data <- httr::content(response, as = "raw")
  
  # Write to temp file and read with magick
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(img_data, tmp)
  
  # Return as-is 
  magick::image_read(tmp)
}
