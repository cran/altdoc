.import_readme <- function(src_dir, tar_dir, tool, freeze) {

  # priorities: .qmd > .Rmd > .md
  readme_files <- list.files(src_dir, pattern = "README")

  # setup_docs() already created README.md if there is none, so if we don't find
  # any, it means the user has deleted it and we error
  if (length(readme_files) == 0) {
    cli::cli_abort("README.md is mandatory.")
  }

  # Find the preferred README extension
  readme_type <- if ("README.qmd" %in% readme_files) {
    "qmd"
  } else if ("README.Rmd" %in% readme_files) {
    "rmd"
  } else if ("README.md" %in% readme_files) {
    "md"
  } else if ("README" %in% readme_files) {
    # no extension -> md
    readme_files[readme_files == "README"] <- "README.md"
    fs::file_move(
      fs::path_join(c(src_dir, "README")),
      fs::path_join(c(src_dir, "README.md"))
    )
    "md"
  }

  if (readme_type != "qmd" && tool == "quarto_website") {
    cli::cli_abort(
      "Quarto websites require a README.qmd file in the root of the package directory.",
      call = NULL
    )
  }

  src_file <- fs::path_join(
    c(src_dir, grep(paste0("\\.", readme_type, "$"), readme_files, ignore.case = TRUE, value = TRUE))
  )

  # Skip file when frozen
  if (isTRUE(freeze)) {
    hashes <- .get_hashes(src_dir = src_dir, freeze = freeze)
    flag <- .is_frozen(
      input = basename(src_file),
      output = fs::path_join(c(src_dir, "docs", "README.md")),
      hashes = hashes
    )
    if (isTRUE(flag)) {
      cli::cli_alert("Skipped {.file {basename(src_file)}} rendering because it didn't change.")
      return(invisible())
    }
  }

  # Render README if Rmd or qmd
  # Do nothing if we only have a .md file
  switch(
    readme_type,

    # rmd -> md
    "rmd" = {
        pre <- fs::path_join(c(src_dir, "altdoc/preamble_vignettes_rmd.yml"))
        pre <- tryCatch(.readlines(pre), error = function(e) NULL)
        .qmd2md(src_file, src_dir, preamble = pre)
    },

    # qmd -> md
    "qmd" = {
        pre <- fs::path_join(c(src_dir, "altdoc/preamble_vignettes_qmd.yml"))
        pre <- tryCatch(.readlines(pre), warning = function(w) NULL, error = function(e) NULL)
        # copy to quarto file
        if (tool == "quarto_website") {
          fs::file_copy(
            src_file,
            fs::path_join(c(tar_dir, "index.qmd")),
            overwrite = TRUE
          )
        }
        # process in-place for use on Github
        # TODO: preambles inserted in the README often break Quarto websites. It's
        # not a big problem to omit the preamble, but it would be good to
        # investigate this, because I am not sure what is going on -VAB
        .qmd2md(src_file, src_dir)
        # .qmd2md(fn, src_dir, preamble = pre)
        .update_freeze(src_dir, basename(src_file), successes = 1, fails = NULL, type = "README")
        cli::cli_alert_success("{.file README} imported.")
        return(invisible())
    }
  )

  if (tool == "quarto_website") {
    tar_file <- fs::path_join(c(tar_dir, "index.md"))
  } else {
    tar_file <- fs::path_join(c(tar_dir, "README.md"))
  }

  src_file <- fs::path_join(c(src_dir, "README.md"))
  fs::file_copy(src_file, tar_file, overwrite = TRUE)
  .check_md_structure(tar_file)

  tmp <- fs::path_join(c(src_dir, "README.markdown_strict_files"))
  if (fs::dir_exists(tmp)) {
    cli::cli_alert("We recommend using a `knitr` option to set the path of your images to `man/figures/README-`. This would ensure that images are properly stored and displayed on multiple platforms like CRAN, Github, and on your `altdoc` website.")
  }
  .update_freeze(src_dir, basename(src_file), successes = 1, fails = NULL, type = "README")
  cli::cli_alert_success("{.file README} imported.")
}
