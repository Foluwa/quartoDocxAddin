\name{render_active_qmd_to_docx}
\alias{render_active_qmd_to_docx}
\title{Live-preview the Active Quarto Document as DOCX}
\usage{
render_active_qmd_to_docx()
}
\value{
The generated document path, invisibly, when the preview closes.
}
\description{
Watches the active \code{.qmd}, renders it after edits pause, and displays the
generated Word document in RStudio's Viewer pane.
}
