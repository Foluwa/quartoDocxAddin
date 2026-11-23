#' Render the active Quarto document to Word
#'
#' Saves the active `.qmd` document and starts a background RStudio job that
#' renders it to a `.docx` file beside the source document.
#'
#' @return The expected document path, invisibly.
#' @export
render_active_qmd_to_docx <- function() {
  if (!rstudioapi::isAvailable()) {
    stop("This addin must be run from RStudio.", call. = FALSE)
  }

  context <- rstudioapi::getActiveDocumentContext()
  input <- context$path

  if (!nzchar(input) || !endsWith(tolower(input), ".qmd")) {
    stop("Open and save a Quarto (.qmd) document first.", call. = FALSE)
  }

  rstudioapi::documentSave(context$id)
  output <- paste0(tools::file_path_sans_ext(input), ".docx")

  quarto::quarto_render(
    input = input,
    output_format = "docx",
    output_file = basename(output),
    as_job = TRUE
  )

  rstudioapi::showDialog(
    title = "Quarto render started",
    message = paste("Output:", output)
  )

  invisible(output)
}
