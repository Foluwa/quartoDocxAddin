#' Live-preview the active Quarto document as DOCX
#'
#' Watches the active `.qmd`, renders it after edits pause, and displays the
#' generated Word document in RStudio's Viewer pane.
#'
#' @return The generated document path, invisibly, when the preview closes.
#' @export
render_active_qmd_to_docx <- function() {
  if (!rstudioapi::isAvailable()) {
    stop("Run this addin from RStudio.", call. = FALSE)
  }

  context <- rstudioapi::getActiveDocumentContext()
  path <- context$path
  if (!nzchar(path) || !endsWith(tolower(path), ".qmd")) {
    stop("Open and save a Quarto (.qmd) document first.", call. = FALSE)
  }

  output <- paste0(tools::file_path_sans_ext(path), ".docx")
  prefix <- paste0("docx-", gsub("[^a-zA-Z0-9]", "", tempfile()))
  preview_dir <- tempfile("docx-preview-")
  dir.create(preview_dir)
  preview <- file.path(preview_dir, basename(output))
  shiny::addResourcePath(prefix, preview_dir)

  dependency <- htmltools::htmlDependency(
    "docx-preview", "0.4.1",
    src = c(file = system.file("www", package = "quartoDocxAddin")),
    script = c("jszip.min.js", "docx-preview.min.js")
  )

  ui <- htmltools::attachDependencies(
    shiny::fluidPage(
      shiny::tags$head(
        shiny::tags$style(htmltools::HTML(
          "body{margin:0;background:#ddd;font-family:system-ui}#bar{position:sticky;top:0;z-index:2;display:flex;align-items:center;gap:10px;padding:8px 12px;background:#fff;border-bottom:1px solid #bbb}#bar .form-group{margin:0}#status{color:#555}#preview{height:calc(100vh - 52px);overflow:auto;padding:18px}.docx-wrapper{margin:auto}"
        )),
        shiny::tags$script(htmltools::HTML(
          "Shiny.addCustomMessageHandler('show-docx',async u=>{const x=document.getElementById('preview'),y=x.scrollTop;try{const r=await fetch(u,{cache:'no-store'});if(!r.ok)throw Error(r.statusText);x.innerHTML='';await docx.renderAsync(await r.blob(),x,null,{breakPages:true});x.scrollTop=y}catch(e){Shiny.setInputValue('preview_error',e.message,{priority:'event'})}});"
        ))
      ),
      shiny::div(
        id = "bar",
        shiny::actionButton("refresh", "Refresh"),
        shiny::actionButton("done", "Close"),
        bslib::input_switch("auto", "Auto", value = TRUE),
        bslib::input_switch("fast", "Fast", value = FALSE),
        shiny::span(shiny::textOutput("status", inline = TRUE), id = "status")
      ),
      shiny::div(id = "preview")
    ),
    dependency
  )

  server <- function(input, output_ui, session) {
    state <- shiny::reactiveValues(process = NULL, pending = FALSE,
                                   status = "Waiting to render")
    changed <- shiny::reactiveVal(0L)
    last_text <- paste(context$contents, collapse = "\n")

    output_ui$status <- shiny::renderText(state$status)

    start_render <- function() {
      if (!is.null(state$process)) {
        state$pending <- TRUE
        return()
      }
      rstudioapi::documentSave(context$id)
      state$status <- "Rendering..."
      state$process <- callr::r_bg(
        function(input, file, cache) {
          args <- list(input = input, output_format = "docx",
                       output_file = file, quiet = TRUE, as_job = FALSE)
          if (cache) args$cache <- TRUE
          do.call(quarto::quarto_render, args)
        },
        list(path, basename(output), isTRUE(input$fast)),
        wd = dirname(path), stdout = "|", stderr = "|"
      )
    }

    timer <- shiny::reactiveTimer(500, session)
    shiny::observe({
      timer()
      current <- rstudioapi::getActiveDocumentContext()
      if (identical(current$id, context$id)) {
        text <- paste(current$contents, collapse = "\n")
        if (!identical(text, last_text)) {
          last_text <<- text
          changed(changed() + 1L)
        }
      }
    })

    edits <- shiny::debounce(shiny::reactive(changed()), 1000)
    shiny::observeEvent(edits(), {
      if (isTRUE(input$auto)) start_render()
    }, ignoreInit = TRUE)
    shiny::observeEvent(input$refresh, start_render())
    shiny::observeEvent(input$auto, {
      if (isTRUE(input$auto)) start_render()
    }, ignoreInit = TRUE)
    shiny::observeEvent(input$fast, {
      if (isTRUE(input$auto)) start_render()
    }, ignoreInit = TRUE)
    session$onFlushed(function() {
      shiny::isolate(start_render())
    }, once = TRUE)

    shiny::observe({
      shiny::invalidateLater(250, session)
      process <- state$process
      if (is.null(process) || process$is_alive()) return()

      ok <- identical(process$get_exit_status(), 0L) && file.exists(output)
      if (ok) {
        file.copy(output, preview, overwrite = TRUE)
        state$status <- paste("Updated", format(Sys.time(), "%H:%M:%S"))
        url <- sprintf("/%s/%s?v=%s", prefix,
                       utils::URLencode(basename(output), reserved = TRUE),
                       as.numeric(Sys.time()))
        session$sendCustomMessage("show-docx", url)
      } else {
        log <- trimws(paste(process$read_all_output(),
                            process$read_all_error()))
        state$status <- paste(
          "Render failed:", utils::tail(strsplit(log, "\n")[[1]], 1)
        )
      }

      state$process <- NULL
      if (state$pending) {
        state$pending <- FALSE
        start_render()
      }
    })

    shiny::observeEvent(input$preview_error, {
      state$status <- paste("Preview failed:", input$preview_error)
    })
    shiny::observeEvent(input$done, shiny::stopApp())
    session$onSessionEnded(function() {
      process <- shiny::isolate(state$process)
      if (!is.null(process) && process$is_alive()) process$kill()
      shiny::removeResourcePath(prefix)
      unlink(preview_dir, recursive = TRUE)
    })
  }

  shiny::runGadget(ui, server, viewer = shiny::paneViewer("maximize"))
  invisible(output)
}
