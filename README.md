# quartoDocxAddin

`quartoDocxAddin` is an RStudio addin for rendering the active Quarto
document directly to a Word (`.docx`) file in an RStudio background job. It
writes the output beside the source document without opening a browser preview
or Microsoft Word.

## Requirements

- RStudio
- Quarto
- The `quarto` and `rstudioapi` R packages

## Installation

The package is currently in development. After it is published on GitHub, it
can be installed with:

```r
install.packages("remotes")
remotes::install_github("Foluwa/quartoDocxAddin")
```

## Usage

1. Open a `.qmd` file in RStudio.
2. Select **Addins → Render Active Quarto to DOCX**.
3. Follow the render in RStudio's **Jobs** pane.
4. The generated `.docx` file will be written beside the `.qmd` file.

The addin can also be assigned a keyboard shortcut through
**Tools → Modify Keyboard Shortcuts**.

## Development

Install the local package while developing it with:

```r
remotes::install_local(".")
```

## License

MIT © 2026 Moronfoluwa Akintola
