# Create an image of a code snippet with carbon.js via the carbonara API

Generates a styled code image using the carbonara community API
(https://github.com/petersolopov/carbonara), which provides programmatic
access to carbon.js styling without a headless browser.

## Usage

``` r
carbon_image(x, lang = "r", theme = c("dark", "light"), timeout = 60, ...)
```

## Arguments

- x:

  Character string with the code to render.

- lang:

  Programming language. Default `"r"`. See carbonara documentation for
  supported languages.

- theme:

  Overall look. `"dark"` (default, uses one-dark) or `"light"` (uses
  one-light).

- timeout:

  Request timeout in seconds. Defaults to `60`.

- ...:

  Additional carbonara API parameters. Common options include:

  - `backgroundColor`: background color (e.g., `"rgba(171,184,195,1)"`)

  - `theme`: theme name (overrides theme preset, e.g., `"monokai"`,
    `"nord"`)

  - `fontFamily`: font family (e.g., `"Hack"`, `"Fira Code"`)

  - `fontSize`: font size (e.g., `"14px"`)

  - `lineNumbers`: show line numbers (`TRUE` or `FALSE`)

  - `windowControls`: show window controls (`TRUE` or `FALSE`)

## Value

A `magick-image` object.

## Examples

``` r
if (FALSE) { # \dontrun{
# Dark theme (default)
img <- carbon_image("x <- 1:10\nplot(x)")

# Light theme
img <- carbon_image("x <- 1:10\nplot(x)", theme = "light")

# Custom theme and settings
img <- carbon_image("x <- 1:10", theme = "dark", 
                    backgroundColor = "rgba(0,0,0,1)",
                    fontSize = "16px")
} # }
```
