# Using quartoDocxAddin

## Purpose

The addin provides a live, browser-based preview of the generated Word
document inside RStudio. It avoids repeatedly opening and closing Microsoft
Word while developing a Quarto report.

The workflow is:

```text
Edit .qmd -> pause -> render DOCX -> refresh RStudio Viewer
```

## Requirements

- RStudio
- Quarto
- an active, saved `.qmd` file

The package installs its required R dependencies and bundles the JavaScript
needed to display DOCX files. Report data are not uploaded anywhere.

## Installation

From GitHub:

```r
remotes::install_github(
  "Foluwa/quartoDocxAddin",
  auth_token = NULL,
  upgrade = "never"
)
```

From a local checkout:

```r
remotes::install_local(
  "/Users/folu/Desktop/projects/quartoDocxAddin",
  upgrade = "never"
)
```

Restart RStudio after installation or updating so it reloads the Addins menu.

## Starting the preview

1. Open the relevant RStudio project.
2. Open and save the Quarto `.qmd` file.
3. Select **Addins -> Live Preview Quarto DOCX**.
4. The Viewer pane expands and starts the initial render.

The toolbar displays the current state:

- `Waiting to render`
- `Rendering...`
- `Updated HH:MM:SS`
- a render or preview error

## Editing workflow

Continue editing the same `.qmd`. The addin checks the editor twice per second.
After no further change is detected for one second, it:

1. saves the editor;
2. starts Quarto in a separate R process;
3. generates the DOCX beside the `.qmd`; and
4. refreshes the existing Viewer preview.

If another edit occurs while rendering, the current render is allowed to
finish and one new render is queued for the latest version. Intermediate
versions are skipped, preventing overlapping Quarto processes.

The Viewer remains responsive while Quarto runs. The R console is occupied by
the interactive preview session until **Close** is selected.

## Controls

- **Auto**: rerender after editor changes. Turn it off to render only when
  requested.
- **Fast**: enable Quarto caching to avoid repeating unchanged computations.
- **Refresh**: force a render without changing the source.
- **Close**: stop the preview and terminate an active render process.
- RStudio's Viewer **Zoom** control: enlarge the preview if required.

## Output and formatting

For:

```text
project/report.qmd
```

the output is:

```text
project/report.docx
```

The addin forces DOCX output but otherwise honours the Quarto configuration,
including a Word reference document:

```yaml
---
title: "Study report"
format:
  docx:
    reference-doc: darwinReportRef.docx
---
```

Formatting problems should be corrected in the `.qmd`, its R code, or the
reference document. The addin does not rewrite styles or report content.

## Rendering speed

The preview updates only after Quarto finishes. Text-only reports may update
quickly, while reports that rerun analyses can take considerably longer. Turn
on **Fast** to enable Quarto caching for the preview session.

Caching helps only when the report and its dependencies permit Quarto to reuse
unchanged work. Avoid irreversible side effects in executable chunks because
automatic previewing runs the report repeatedly.

## Preview accuracy

The Viewer shows an HTML interpretation of the actual generated DOCX. It is
useful for checking text, tables, headings, colours, images, and general page
layout without opening Word.

Microsoft Word may differ for complex pagination, fields, tracked changes,
shapes, or other Word-specific features. Open the final document in Word once
before delivery.

## Keyboard shortcut

To assign a shortcut:

1. Open **Tools -> Modify Keyboard Shortcuts** in RStudio.
2. Search for **Live Preview Quarto DOCX**.
3. Assign an unused shortcut and apply the change.

## Troubleshooting

### The addin is missing

Restart RStudio and confirm installation:

```r
packageVersion("quartoDocxAddin")
```

### The addin asks for a saved `.qmd`

Select the source editor tab, save the file, and launch the addin again.

### A render fails

The last valid preview remains visible. Read the error in the toolbar, correct
the `.qmd`, and wait for the automatic retry or select **Refresh**.

### The preview fails but the DOCX exists

The document may use a feature unsupported by the browser renderer. Open the
DOCX in Word for verification and report the preview problem with a minimal
example where possible.

### The document cannot be overwritten

Close the generated DOCX in Word or another program, then select **Refresh**.
Windows may lock an open Word file.

### GitHub installation returns HTTP 401

For this public repository, disable an invalid stored token explicitly:

```r
Sys.unsetenv(c("GITHUB_PAT", "GITHUB_TOKEN"))
remotes::install_github(
  "Foluwa/quartoDocxAddin",
  auth_token = NULL,
  upgrade = "never"
)
```
