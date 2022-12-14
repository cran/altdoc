#' Preview the documentation in a webpage or in viewer
#'
#' @param path Path. Default is the package root (detected with `here::here()`).
#' @export
#'
#' @return No value returned. If RStudio is used, it shows a site preview in
#' Viewer.
#'
#' @examples
#'
#' # Preview documentation
#' preview()

preview <- function(path = ".") {

  if (rstudioapi::isAvailable()) {
    if (fs::file_exists(fs::path_abs("docs/index.html", start = path))) {
      servr::httw(fs::path_abs("docs/"))
    } else if (fs::file_exists(fs::path_abs("docs/site/index.html", start = path))) {
      # first build
      system2("cd", paste(fs::path_abs("docs", start = path), " && mkdocs build -q"))
      # stop it directly to avoid opening the browser
      servr::daemon_stop()

      # getwd has to be used outside of httw, not working otherwise
      servr::httw(
        fs::path_abs("docs/site", start = path),
        watch = fs::path_abs("docs/", start = path),
        handler = function(files) {
          system2("cd", ".. && mkdocs build -q")
        }
      )
    } else {
      cli::cli_alert_danger("{.file index.html} was not found. You can run one of {.code altdoc::use_*} functions to create it.")
    }
  } else {
    if (fs::file_exists(fs::path_abs("docs/index.html", start = path))) {
      utils::browseURL(fs::path_abs("docs/index.html", start = path))
    } else if (fs::file_exists(fs::path_abs("docs/site/index.html", start = path))) {
      utils::browseURL(fs::path_abs("docs/site/index.html", start = path))
    }
  }
}
