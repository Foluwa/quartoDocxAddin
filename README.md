# quartoDocxAddin

`quartoDocxAddin` provides a live preview of the active Quarto Word report in
RStudio's Viewer pane. After you pause editing, it saves the `.qmd`, renders a
DOCX in a separate R process, and refreshes the preview automatically.

## Installation

```r
remotes::install_github(
  "Foluwa/quartoDocxAddin",
  auth_token = NULL,
  upgrade = "never"
)
```

Restart RStudio after installation.

## Usage

1. Open and save a `.qmd` file.
2. Select **Addins -> Live Preview Quarto DOCX**.
3. Continue editing while the DOCX preview refreshes in the Viewer pane.
4. Select **Close** when finished.

The addin honours the document's DOCX options and `reference-doc`. The preview
is browser-based, so final output should still be checked once in Microsoft
Word.

## Development

```r
remotes::install_local(".", upgrade = "never")
```

## License

MIT © 2026 Moronfoluwa Akintola
