# quartoDocxAddin implementation plan

## 1. Goal

Provide a React-like development loop for Quarto Word reports entirely inside
RStudio:

```text
Edit the active .qmd
        -> pause for one second
        -> render DOCX asynchronously
        -> refresh the RStudio Viewer preview
```

The user should not need to switch repeatedly between RStudio and Microsoft
Word. Word remains useful only for final quality assurance because a browser
preview cannot reproduce every Word-specific feature perfectly.

## 2. User experience

1. Open and save a `.qmd` file in RStudio.
2. Select **Addins -> Live Preview Quarto DOCX**.
3. The Viewer pane expands and shows the generated Word document.
4. Continue editing the same `.qmd` file.
5. With **Auto** enabled, the addin saves and rerenders after typing stops
   briefly. With **Auto** disabled, rendering occurs only when **Refresh** is
   selected.
6. The Viewer refreshes automatically while preserving its approximate scroll
   position.
7. The toolbar shows `Rendering`, the last update time, or a concise error.
8. **Fast** enables Quarto caching, **Refresh** forces a render, and **Close**
   stops the preview session.

## 3. Architecture

Keep the package deliberately small:

```text
R/render_docx.R
  render_active_qmd_to_docx()

inst/rstudio/addins.dcf
  registers the interactive addin

inst/www/
  jszip.min.js
  docx-preview.min.js

inst/licenses/
  licences for bundled browser dependencies
```

The single exported function coordinates four components:

- `rstudioapi` reads and saves the active editor document;
- `callr` runs Quarto in a separate R process;
- `shiny` maintains the Viewer session and render status;
- `bslib` provides compact Auto and Fast switches;
- `docx-preview` displays the generated DOCX as HTML in the Viewer.

No separate React application, Node build, configuration window, database, or
custom Pandoc discovery is required.

## 4. Change detection and rendering

### Editor monitoring

Poll the active RStudio document every 500 milliseconds and compare its text
with the previous value. Comparing the existing strings avoids an additional
hashing dependency.

Apply a one-second debounce. This prevents a render for every keystroke and
starts work only after the user pauses.

Observe editor changes only while **Auto** is enabled. **Refresh** remains
available in manual mode.

### Automatic saving

Save the editor immediately before each render. Quarto always receives the
latest editor contents, including changes that had not previously been saved.

The addin must never rewrite or transform the `.qmd` itself.

### Asynchronous rendering

Use `callr::r_bg()` to run `quarto::quarto_render()` in a separate process.
This keeps the Shiny preview responsive and makes the child process easy to
terminate when the preview closes.

Only one render may run at a time. If further edits occur during a render,
set a pending flag and render the latest saved version once the current render
finishes. Intermediate versions are intentionally skipped.

Render with:

- the active `.qmd` as the input;
- `docx` as the forced output format;
- the source directory as the working directory;
- the source basename with `.docx` as the output filename;
- Quarto caching when **Fast** is enabled;
- `as_job = FALSE` inside the child process, because `callr` already provides
  process isolation.

## 5. Viewer implementation

Run an interactive Shiny gadget with:

```r
shiny::runGadget(..., viewer = shiny::paneViewer("maximize"))
```

Copy each successful output to a session-specific temporary directory and
serve only that directory through a Shiny resource path. This avoids exposing
the report directory. Send a cache-busted DOCX URL to the browser.

The bundled JavaScript will:

1. fetch the generated DOCX locally;
2. pass it to `docx.renderAsync()`;
3. replace the previous preview;
4. restore the previous scroll position where practical; and
5. report browser-rendering errors back to Shiny.

The DOCX and report data remain local. Browser dependencies are bundled in the
R package, so the preview does not require a CDN or upload documents to an
external service.

## 6. Status and errors

The Viewer toolbar should display one of:

- `Waiting to render`;
- `Rendering...`;
- `Updated HH:MM:SS`;
- `Render failed: <last useful error line>`; or
- `Preview failed: <browser error>`.

Keep the last successful preview visible when a later render fails. The user
can correct the source without losing the previous output.

Closing the gadget must terminate an active child process, remove the Shiny
resource path, and delete the temporary preview directory.

## 7. Efficiency decisions

- Use one exported R function instead of a hierarchy of small wrappers.
- Poll at 500 ms and debounce at 1,000 ms to balance responsiveness and CPU
  use.
- Compare editor strings directly instead of adding `digest`.
- Skip intermediate edits while a render is already running.
- Load browser assets locally and only once per Viewer session.
- Reuse the generated report path instead of producing timestamped files.
- Avoid converting DOCX to PDF, which would require LibreOffice or Word.

The actual refresh speed is limited by the report's Quarto execution time. A
document containing expensive R code cannot update as quickly as a JavaScript
application unless its computations are cached or frozen.

## 8. Dependencies and licensing

R dependencies:

- `bslib`
- `callr`
- `htmltools`
- `quarto`
- `rstudioapi`
- `shiny`

Bundled browser dependencies:

- `docx-preview` 0.4.1, Apache-2.0
- `JSZip` 3.10.1, MIT or GPL-3.0-or-later

Keep their licence files under `inst/licenses/` and pin versions so package
behaviour is reproducible.

## 9. Testing

### Automated checks

- Run `R CMD check --no-manual` with no errors, warnings, or notes.
- Confirm the package installs and loads from a clean library.
- Check that browser assets and licence files are included in the built
  package.
- Add unit tests for input validation and output-path construction if those
  operations become separate helpers.

### Manual RStudio checks

Test the complete interaction because RStudio editor and Viewer APIs cannot be
fully exercised by ordinary unit tests:

1. Launch with a saved `.qmd` and confirm the initial preview.
2. With **Auto** enabled, edit without manually saving and confirm automatic
   refresh.
3. Disable **Auto**, edit, and confirm the preview changes only after
   **Refresh**.
4. Enable **Fast** and confirm the document renders with Quarto caching.
5. Make several rapid edits and confirm renders do not overlap.
6. Introduce an R error and confirm the previous preview remains visible.
7. Correct the error and confirm preview recovery.
8. Use a report with a Word reference document and complex flextables.
9. Press **Refresh** and **Close**, confirming that closing produces no error.
10. Confirm paths containing spaces work.
11. Test on macOS and Windows.

## 10. Known limitations

- The preview is an HTML interpretation of the generated DOCX, not Microsoft
  Word itself.
- Complex fields, tracked changes, shapes, and some pagination details may
  differ from Word.
- Automatic rerendering executes report code repeatedly; users should avoid
  irreversible side effects in executable chunks.
- Long computations delay refreshes. Quarto caching or freezing should be used
  where suitable.
- The preview follows the document that was active when the addin started.
- Final deliverables should still receive one check in Microsoft Word.

## 11. Acceptance criteria

Version 0.1 is complete when:

- the addin opens the live DOCX preview in the RStudio Viewer;
- the initial document renders automatically;
- edits trigger a debounced asynchronous rerender;
- no overlapping render processes occur;
- successful renders refresh the existing Viewer session;
- errors are visible without removing the last valid preview;
- closing the preview cleans up its process and resource path;
- the package works without internet access after installation;
- `R CMD check` reports `Status: OK`; and
- the workflow is manually verified on macOS and Windows.
