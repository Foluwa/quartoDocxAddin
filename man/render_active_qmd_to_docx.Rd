\name{render_active_qmd_to_docx}
\alias{render_active_qmd_to_docx}
\title{Render the Active Quarto Document to Word}
\usage{
render_active_qmd_to_docx()
}
\value{
The expected document path, invisibly.
}
\description{
Saves the active \code{.qmd} document and starts a background RStudio job that
renders it to a \code{.docx} file beside the source document.
}
